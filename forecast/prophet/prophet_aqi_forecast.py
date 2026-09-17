#!/usr/bin/env python3

import os
import warnings
from datetime import datetime
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd
from prophet import Prophet


BASE_DIR = os.environ.get("WEATHER_EXTENSION_DIR", str(Path(__file__).resolve().parent))
INPUT_FILE = os.path.join(BASE_DIR, "data", "aqi_monthly_2020_2025.tsv")
RESULT_DIR = os.path.join(BASE_DIR, "result")
PLOT_DIR = os.path.join(BASE_DIR, "plots")
TSV_FILE = os.path.join(RESULT_DIR, "aqi_prophet_forecast.tsv")
CSV_FILE = os.path.join(RESULT_DIR, "aqi_prophet_forecast.csv")


def safe_filename(value):
    return "".join("_" if ch in '/\\:*?"<>|' else ch for ch in str(value))


def main():
    os.makedirs(RESULT_DIR, exist_ok=True)
    os.makedirs(PLOT_DIR, exist_ok=True)

    columns = ["city_name", "month_start", "avg_aqi", "observation_count"]
    data = pd.read_csv(
        INPUT_FILE,
        sep="\t",
        header=None,
        names=columns,
        encoding="utf-8",
    )
    data["month_start"] = pd.to_datetime(data["month_start"], errors="raise")
    data["avg_aqi"] = pd.to_numeric(data["avg_aqi"], errors="raise")
    data = data.dropna(subset=["city_name", "month_start", "avg_aqi"])

    train_start_limit = pd.Timestamp("2020-01-01")
    train_end_limit = pd.Timestamp("2025-12-01")
    future_dates = pd.date_range(
        start="2026-01-01",
        end="2026-12-01",
        freq="MS",
    )
    expected_months = pd.date_range(
        start=train_start_limit,
        end=train_end_limit,
        freq="MS",
    )
    generated_at = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    all_forecasts = []
    summaries = []

    for city in sorted(data["city_name"].unique()):
        city_data = data[data["city_name"] == city].copy()
        train = city_data[
            (city_data["month_start"] >= train_start_limit)
            & (city_data["month_start"] <= train_end_limit)
        ].sort_values("month_start")

        actual_months = pd.DatetimeIndex(train["month_start"].unique()).sort_values()
        missing_months = expected_months.difference(actual_months)
        if len(train) < 24:
            warnings.warn(
                f"{city}: only {len(train)} training months; fewer than 24 months",
                RuntimeWarning,
            )
        if len(missing_months) > 0:
            warnings.warn(
                f"{city}: missing months: {','.join(x.strftime('%Y-%m') for x in missing_months)}",
                RuntimeWarning,
            )

        model = Prophet(
            yearly_seasonality=True,
            weekly_seasonality=False,
            daily_seasonality=False,
            interval_width=0.95,
        )
        model.fit(train[["month_start", "avg_aqi"]].rename(columns={"month_start": "ds", "avg_aqi": "y"}))

        future_df = pd.DataFrame({"ds": future_dates})
        forecast = model.predict(future_df)
        future_forecast = forecast[["ds", "yhat", "yhat_lower", "yhat_upper"]].copy()
        negative_count = int((future_forecast["yhat"] < 0).sum())
        if negative_count:
            print(f"WARNING {city}: {negative_count} negative raw Prophet forecast values; preserved")

        future_forecast["city_name"] = city
        future_forecast["forecast_month"] = future_forecast["ds"].dt.strftime("%Y-%m-%d")
        future_forecast["forecast_aqi"] = future_forecast["yhat"]
        future_forecast["forecast_lower"] = future_forecast["yhat_lower"]
        future_forecast["forecast_upper"] = future_forecast["yhat_upper"]
        future_forecast["train_start"] = train["month_start"].min().strftime("%Y-%m-%d")
        future_forecast["train_end"] = train["month_start"].max().strftime("%Y-%m-%d")
        future_forecast["model_name"] = "Prophet"
        future_forecast["generated_at"] = generated_at
        all_forecasts.append(
            future_forecast[
                [
                    "city_name",
                    "forecast_month",
                    "forecast_aqi",
                    "forecast_lower",
                    "forecast_upper",
                    "train_start",
                    "train_end",
                    "model_name",
                    "generated_at",
                ]
            ]
        )

        min_row = future_forecast.loc[future_forecast["forecast_aqi"].idxmin()]
        max_row = future_forecast.loc[future_forecast["forecast_aqi"].idxmax()]
        summaries.append(
            {
                "city_name": city,
                "training_months": len(train),
                "train_start": train["month_start"].min().strftime("%Y-%m-%d"),
                "train_end": train["month_start"].max().strftime("%Y-%m-%d"),
                "forecast_records": len(future_forecast),
                "min_forecast_month": min_row["forecast_month"],
                "min_forecast_aqi": float(min_row["forecast_aqi"]),
                "max_forecast_month": max_row["forecast_month"],
                "max_forecast_aqi": float(max_row["forecast_aqi"]),
                "avg_forecast_aqi": float(future_forecast["forecast_aqi"].mean()),
                "missing_months": ",".join(x.strftime("%Y-%m") for x in missing_months) or "none",
            }
        )

        plot_file = os.path.join(PLOT_DIR, f"{safe_filename(city)}_forecast.png")
        fig = model.plot(forecast)
        fig.set_size_inches(12, 6)
        fig.tight_layout()
        fig.savefig(plot_file, dpi=150)
        plt.close(fig)

        components_file = os.path.join(PLOT_DIR, f"{safe_filename(city)}_components.png")
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            component_fig = model.plot_components(forecast)
        component_fig.set_size_inches(12, 8)
        component_fig.tight_layout()
        component_fig.savefig(components_file, dpi=150)
        plt.close(component_fig)

    result = pd.concat(all_forecasts, ignore_index=True)
    result["forecast_aqi"] = result["forecast_aqi"].round(4)
    result["forecast_lower"] = result["forecast_lower"].round(4)
    result["forecast_upper"] = result["forecast_upper"].round(4)
    result.to_csv(TSV_FILE, sep="\t", index=False, header=False, encoding="utf-8")
    result.to_csv(CSV_FILE, index=False, encoding="utf-8-sig")

    print("Prophet forecast summary")
    for summary in summaries:
        print(
            f"{summary['city_name']}\ttraining_months={summary['training_months']}\t"
            f"train={summary['train_start']}..{summary['train_end']}\t"
            f"forecast_records={summary['forecast_records']}\t"
            f"min={summary['min_forecast_month']}({summary['min_forecast_aqi']:.4f})\t"
            f"max={summary['max_forecast_month']}({summary['max_forecast_aqi']:.4f})\t"
            f"avg={summary['avg_forecast_aqi']:.4f}\t"
            f"missing_months={summary['missing_months']}"
        )
    print(f"forecast_rows={len(result)}")
    print(f"tsv={TSV_FILE}")
    print(f"csv={CSV_FILE}")


if __name__ == "__main__":
    main()
