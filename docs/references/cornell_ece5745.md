# Cornell ECE5745

资源 ID：`C5745-S23`。课程：Complex Digital ASIC Design。公开课程页为 Spring 2023；2026-10-07 核对。中心关系见 [Mapping](course_mapping.md#5-课程-mapping)。

## 官方资料与版本

[课程入口](https://www.csl.cornell.edu/courses/ece5745/)、[schedule](https://www.csl.cornell.edu/courses/ece5745/schedule.html)、[handouts](https://www.csl.cornell.edu/courses/ece5745/handouts.html)。T01 HDL、T05 automated methods、T08 testing/verification、T12 synthesis、T13 physical automation 是 handout 主题，不能直接当作已核对的 lecture 编号。

| 阅读材料 | 主要问题 | 本项目连接 |
|---|---|---|
| [S01 front-end](https://cornell-ece5745.github.io/ece5745-S01-front-end/) | RTL、单元视图和前端流程如何分工？ | K05/K06，07–08/41–44；该页日期 2023-01-27 |
| [Tutorial 4 ASIC tools](https://cornell-ece5745.github.io/ece5745-tut4-asic-tools/) | 如何读综合/实现报告并做评估？ | K06/K07/K10，07–10/19–22/48 |
| [S02 back-end](https://cornell-ece5745.github.io/ece5745-S02-back-end/) | 网表、布局、时钟、布线、延迟与能量如何连接？ | K07/K10/K11；该页日期 2022-02-04，虽由 2023 课程引用仍保留自身版本 |
| [S05 SRAM](https://cornell-ece5745.github.io/ece5745-S05-srams/) | memory 能否综合为宏，接口和视图需什么？ | K09，17/DF08/AD08 的后续存储练习 |

## 为什么值得学

本项目已有综合、SDC 和物理流程讲义，最需要补的是“有 baseline、替代方案、受控评估”的 ASIC 方法。负 slack 和功耗不是孤立数字：要回到数据路径、扇出、负载、布局和活动解释。

## 推荐项目方法

在 handouts 入口选择 Lab 1 的流水整数乘法器方法，服务 `EXP-FIXED-PPA`。基线用已有 [adc_fixed_correct](../../lessons/adc_digital/rtl/adc_fixed_correct.sv)，另建实验副本比较流水或资源复用。先冻结数值/吞吐契约，预测 latency、FF/门数和关键路径，再做整数 oracle 回归、综合与报告对照。

采用三个里程碑：baseline 与测试策略 → alternative design → 同条件 evaluation。报告至少列库/角/约束、吞吐与延迟、面积单位、最差路径和活动来源。不能把不同库或不同频率下的结果当作架构收益。

`EXP-ASIC-IMPLEMENT` 参考 S02/Tutorial 4，将自己的小控制模块走到 P&R；当前仍需完整 LEF/技术文件、提取数据和分析工具。SRAM 先做 [接口契约练习](../practice/memory.md)。课内 DC/VCS 与教学 NanGate/FreePDK 环境不直接替换本项目的 Genus/Innovus，也不代表流片 PDK。

## 学习进度与问题

目前是资源核对，不代表本人完成 Cornell lab；记录在 [learning_log](../learning_log/README.md)，工程执行状态仍在 [progress](../progress.md)。

建议回答：流水是否真的增加可接受样本速率？共享乘法器是否仍赶得上 sample deadline？为什么布线后 net delay 可能比逻辑重构更重要？报告的 power 是何种活动与电压条件？

完整排序/CPU 加速器、处理器软件栈和学校基础设施暂不加入。可读报告方法，但不把公开课程的教学 DRC 或功耗数字作为自己的签核证据。
