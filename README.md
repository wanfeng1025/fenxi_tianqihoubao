# 历史天气与 AQI 数据采集分析项目

一个面向课程实验和作品集展示的端到端数据工程项目：从历史天气/AQI 网页采集开始，经 MySQL 落库、DataX 导入 HDFS/Hive，完成十项 Hive 指标分析，再回流 MySQL 并使用 ECharts 展示。

## 项目快照

- 城市：南京、合肥、杭州、亳州、淮南、铜陵
- 数据快照：2026-09-15 核验
- `history_weather`：14,622 行；`history_aqi`：14,544 行
- 十张指标结果表：34、72、6、36、18、6、6、6、72、432 行，合计 688 行
- 训练边界：2020—2025；2026 年未完成全年数据，不用于完整年度比较

## 目录

```text
src/                         多线程采集与 MySQL 幂等写入
sql/mysql/                   MySQL 建库建表和指标表
sql/hive/                   Hive 建库建表与十项分析 SQL
datax/mysql_to_hdfs/        MySQL -> HDFS/Hive
datax/hdfs_to_mysql/        Hive -> MySQL
forecast/prophet/            月度 AQI Prophet 预测
visualization/html/          ECharts 交互式首页和十个页面
visualization/json/          十项图表数据
visualization/images/        十张 500 DPI PNG
docs/metrics/               十项指标说明
data_evidence/              可公开复核的摘要证据
```

## 快速开始

1. 安装 Python 依赖：`python -m pip install -r requirements.txt`。
2. 复制 `.env.example` 为本地 `.env`，填写自己的 MySQL 连接信息；不要把 `.env` 提交到 Git。
3. 执行 `sql/mysql/init_weather_db.sql` 建立原始表，运行 `python src/main.py --small-test` 做小规模验证，再按需运行完整采集。
4. 在 Hadoop/Hive 主机上先执行 `sql/hive/init_hive_aqi.sql` 和 `sql/hive/init_hive_weather.sql`，再执行 `datax/mysql_to_hdfs/` 中的作业。DataX JSON 中的 `YOUR_*` 占位符必须替换为本机环境值。
5. 按顺序运行 `sql/hive/analytics/` 下的指标脚本；Prophet 脚本使用 `forecast/prophet/data/aqi_monthly_2020_2025.tsv` 作为月度训练输入。
6. 浏览器打开 `visualization/html/index.html` 查看十项图表。

## 口径和复现说明

雨天定义为白天或夜间天气状况包含“雨”；连续优空气定义为 AQI <= 50；Prophet 使用 yearly seasonality，关闭 weekly/daily seasonality，预测区间为 95%。ECharts 页面和 PNG 使用本次实验已核验的结果快照，不代表重新采集后的永久值。

## 安全边界

本仓库不包含原始报告 PDF/DOCX、数据库 dump、运行日志、个人截图、内网地址或真实密码。详细审计见 [PROJECT_AUDIT.md](PROJECT_AUDIT.md) 和 [SECURITY_AUDIT.md](SECURITY_AUDIT.md)。
