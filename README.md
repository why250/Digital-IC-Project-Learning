# 数字 IC 与数模混合设计学习

面向熟练模拟 IC 工程师，从寄存器、门、时序窗口、负载与 PVT 理解 RTL。结合已有 CT ΔΣ 环路滤波器经验，逐步完成控制、校准和数据处理模块。

[在线学习网站](https://why250-digital-ic-classroom.pages.dev/)：课程阅读与搜索、个人进度/笔记和 SPI 时序演示。网页直接使用本仓库讲义；本地开发与发布见 [网站说明](web/README.md)。

## 从这里开始

1. 看 [个人学习路线](docs/roadmap.md)，确定当前阶段和前置知识。
2. 做 [第 01 课内的基础练习](docs/course/01_sync_spi.md#第-01-课内的基础入门顺序)，再手画 A5/3C 的 SPI 波形。
3. 把预测和解释写入 [基础学习记录](docs/course/08_workbook.md)，通过阶段验收后继续。

需要运行工具时，先读 [当前进度与证据](docs/progress.md)，再按 [运行指南](docs/running.md) 操作。

## 课程入口

| 材料 | 范围 | 用途 |
|---|---|---|
| [数字基础](docs/course/00_course.md) | 01–24 | 同步 RTL、SPI、综合/STA、CDC、配置与实现基础 |
| [数模混合控制](docs/mixed_signal/00_course.md) | 25–48；总纲含 01–48 阶段索引 | 上电、采样、定点、测量/trim 与交付 |
| [ΔΣ 后级数字滤波](docs/delta_sigma_filter/00_course.md) | DF01–DF08 | 优先深入的方向：频谱、CIC/FIR、抽取与定点 |
| [ADC 内部数字模块](docs/adc_digital/00_course.md) | AD01–AD20 | SAR、编码、DEM、TI 样本对齐与校准 |
| [时间交织 DAC](docs/dac_digital/00_course.md) | TD01–TD12 | 重构、插值、码交付与失配校正 |
| [Virtuoso AMS](docs/ams/00_course.md) | AM01–AM06 | RTL 与连续时间电路的联合验证 |

各总纲链接到讲义、项目规格、参考答案和学习记录。选课顺序与整体时间预算见个人路线；工具完成和个人掌握分别记录。

## 公开资料与项目映射

本项目按自己的项目路线推进，参考 Berkeley EECS151、Cornell ECE5745、MIT 6.004 等公开资料。按知识节点选择阅读，再回到 RTL、验证与数模实验。

→ [公开资料与本项目课程映射](docs/references/course_mapping.md)

## 工程入口与目录

- [SPI 接口与电路参考](docs/01_spi_master.md)、[第一份综合报告解读](docs/02_read_first_reports.md)、[SPI RTL](lessons/01_spi_master/rtl/spi_master.sv)。
- [ADC 源码目录](lessons/adc_digital/README.md)、[AD01–AD20 可运行实验](docs/adc_digital/09_labs.md)。
- `docs/`：课程和工程参考；`docs/history/`：按日期保留的历史记录。
- `lessons/`：已实现的模型、RTL、testbench、约束和独立运行脚本。
- `tools/`：部署、结果收集、波形转换与文档检查。
- `results/`、`.tools/`：生成产物与项目内工具，Git 忽略。

## 文档维护

README 只做入口；roadmap 维护个人顺序与前置；各 `00_course.md` 维护专题目录；项目规格维护接口契约；running 维护运行命令；progress 维护当前证据摘要，详细历史留在 history。公开资料挂已有知识节点，learning_log 记录实际理解变化，原 workbook 保持个人验收归属。新增专题接入入口和路线，复用公共知识时引用原讲义。

整理文档后运行 `python tools/check_docs.py` 与 `git diff --check`。修改设计后按运行指南执行相应回归。Genus 教学库用于逻辑教学，既有 RTL 仿真和综合结果不代表真实模拟性能或流片签核。
