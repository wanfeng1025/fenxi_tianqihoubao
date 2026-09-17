# 发布前项目审计

## 审计结论

本发布版来自本地历史天气与 AQI 项目目录，保留真实的 Python 采集器、Hive SQL、MySQL DDL、DataX 作业、Prophet 预测脚本、ECharts 页面和 500 DPI PNG。原始项目目录不是 Git 仓库，因此本地没有可供复核的历史提交；远程仓库审计显示 `main` 只有初始 README。

## 纳入内容

- `src/`：六城市多线程采集和 MySQL 幂等写入。
- `sql/`：MySQL/Hive 初始化、十项指标 SQL 和验证脚本。
- `datax/`：MySQL→HDFS/Hive、Hive→MySQL 作业，已将环境参数脱敏。
- `forecast/prophet/`：2020—2025 月度训练和 2026 月度预测。
- `visualization/`：交互式 ECharts、十份指标 JSON、十张 500 DPI PNG。
- `docs/`、`data_evidence/`、`examples/`：指标说明、摘要证据和最小样例。

## 排除内容

原始报告 PDF/DOCX、个人截图、运行日志、原始数据库导出、虚拟机临时文件、内部报告构建脚本、实验报告生成 skill、缓存和任何含本机路径/凭据的文件均未纳入。

## 数据口径

项目快照包含六个城市；完整年度训练和年度比较以 2020—2025 为边界，2026 仅作为不完整年度预测/观察。十张指标表总计 688 行。
