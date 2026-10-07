# Stanford EE271：Introduction to VLSI Systems

资源 ID：`S271-PUBLIC`。2026-10-07 核对 [官方公开页](https://web.stanford.edu/class/ee271/)，页面未标学期。详细 syllabus 链接到 Canvas；具体 lecture/lab 本次未核对，不分配虚构编号。关系见 [中心 Mapping](course_mapping.md#5-课程-mapping)。

## 适合补充什么

公开主题包括 transistor/gates、delay/power/logical effort、HDL/synthesis、DFT，以及 dynamic/static/formal verification。作为第二视角，按当前问题选择：

| 节点与本项目 | 推荐问题 | 应带回的产物 |
|---|---|---|
| K01/K06，07–08/19–22 | 驱动、逻辑努力与真实负载怎样解释路径？ | 自己的门/线延迟分析 |
| K05，41–44 | 仿真、静态检查与形式方法分别回答什么？ | 性质/覆盖/假设分工表 |
| K12，47–48 | scan capture/shift 如何影响模拟控制输出？ | normal/calibration/test 的时钟与拥有权表 |

## 推荐实践与访问边界

目前没有可确认的独立公开 lab 清单，先用上述主题查漏，实验回本项目 [验证补充](../practice/verification.md) 和 [物理/DFT 补充](../practice/physical.md)。如果以后取得官方公开 lecture，记录版本和具体来源后挂回节点；不为获取 Canvas 内容复制登录资料。

DFT 暂以模式与输出安全分析起步，scan insertion/ATPG 要等匹配库、工具、故障模型和测试约束。课程有 DFT 主题不代表本项目已有工具流程。

## 学习进度、问题与取舍

来源已核对，个人学习未登记；写入 [学习日志](../learning_log/README.md)，47–48 验收回 [控制 workbook](../mixed_signal/09_workbook.md)。

带着“scan_shift 时谁控制 trim 码？”和“test clock override 会不会破坏 quiet 窗口？”阅读。没有具体知识缺口时，优先使用已经选定的 Berkeley/Cornell 资料，不追加一套 Stanford 必修路线。
