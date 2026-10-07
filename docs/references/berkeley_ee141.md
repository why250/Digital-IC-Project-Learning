# Berkeley EE141 / Rabaey Digital Integrated Circuits

资源 ID：`RABAEY-DIC2`。2026-10-07 核对的是 **Digital Integrated Circuits 第 2 版教材配套站**，并未核实某一学期完整 EE141。作为 transistor-level 数字 IC 补充，关系见 [中心 Mapping](course_mapping.md#5-课程-mapping)。

## 官方入口与推荐章节

[教材配套站](https://icbook.eecs.berkeley.edu/) 与 [章节 slides 索引](https://icbook.eecs.berkeley.edu/resources/powerpoint-slides)。站点明确限制 slides 电子再发布；本仓库只保留链接和自己的分析，不存 PDF/PPT 或转写课件。

| 阅读章节 | 本项目的问题 | 原创分析产物 |
|---|---|---|
| Ch4 wires、Ch9 interconnect | 为什么 RTL 不变，布线后路径延迟仍会变化？ | K01/K10，19–21：cell/net delay 与负载拆分表 |
| Ch5 CMOS inverter、Ch6 combinational | slew/load/PVT 如何影响门延迟？ | K01/K06，07–08：连接 Liberty 查表与驱动级联 |
| Ch7 sequential、Ch10 timing | setup/hold、clock skew 与 clock load 如何进入窗口？ | K02/K07，09–10/20：时钟与数据到达图 |
| Ch11 arithmetic | 算术结构怎样影响关键路径与切换？ | K06/K14，33–36/AD15：位宽、树结构与流水对照 |
| Ch12 memory | SRAM 为何需要不同于寄存器阵列的接口与视图？ | K09，17/DF08：读延迟、宏边界与端口表 |

## 为什么值得学、怎么练

模拟/RF 背景可直接用负载、RC、驱动、噪声和 PVT 直觉解释数字报告。首先阅读 Ch5/7/10，遇到长线或算术路径再读相应章节；不需要从头重新学习全部 MOS 基础。

练习以本项目 [第一份综合报告](../02_read_first_reports.md) 与 [物理课程](../course/05_physical.md) 为对象：选择一条路径，将 cell/net delay、slew/load 与 setup/hold 假设分开；没有真实数据时只做给定参数计算，不编造网表或物理报告。功耗练习要注明活动定义、电压、时钟和遗漏的内部/漏电分量。

## 学习进度与边界

目前仅核对资源。个人理解写 [日志](../learning_log/README.md)，课程验收仍回原 workbook。建议问题：加大驱动为何增加前一级负载？缩小时钟周期为何通常不能修 hold？门控时钟的毛刺为何是电路问题？

本页不承担 RTL/验证主线，不以教材示例替代实际 Liberty、工艺规则或模拟噪声证据。不复制书中图、习题答案或整套讲义。
