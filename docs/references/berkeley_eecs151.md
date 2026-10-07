# Berkeley EECS151/251A

资源 ID：`B151-F26`。课程：Introduction to Digital Design and Integrated Circuits。版本：Fall 2026；2026-10-07 核对公开站。完整关系见 [中心 Mapping](course_mapping.md#5-课程-mapping)。

## 官方入口与选择性阅读

[学校课程说明](https://www2.eecs.berkeley.edu/Courses/EECS151/) 与 [当前公开站 / lecture 日历](https://eecs151.org/) 是入口。用户原先提供的 inst 域入口本次未能读取，部分历史学期跳登录；当前站的后半学期日历仍有空项，不预填未来 lecture。

| 当前项目问题 | 推荐入口 | 回到自己的工程 |
|---|---|---|
| 如何把顺序程序理解为寄存器更新？ | 当前日历 L4 HDL、L5 Behavioral SV、L6 Sequential SV & Verification | K02，01–05：画 Q→逻辑→D，解释非阻塞赋值与 enable |
| FSM 怎样表达接受/拒绝/完成？ | L7 Testbenches/FSM | K03/K05，01–06：按 SPI 的契约画状态与八个采样事件 |
| 流水化为什么改变协议？ | L10 Pipelining | K06/K14，33–36/AD15：跟踪 valid/id/version 和 latency |
| 怎样从 RTL 走向工具证据？ | [ASIC Lab 2](https://eecs151.org/asic/lab2/overview/) | K05/K06：读 RTL/门级仿真、综合、功耗报告方法 |
| 怎样实现并检查一块版图？ | [ASIC Lab 3](https://eecs151.org/asic/lab3/overview/) | K07/K09/K10：floorplan/place/CTS/route 与宏集成 |
| 如何检查测试本身是否有效？ | [ASIC Lab 4](https://eecs151.org/asic/lab4/overview/)；L12 Formal | K05：覆盖、约束、性质、反例与形式假设 |

Lecture 编号绑定 F26，换学期时核对标题后再用。Labs 是借用方法的参考，不宣称公开课以 SPI/ADC 为实验对象。

原课内已经给出逐课阅读处方；下面保留可直接定位的官方小节，避免只到 Lab 首页：

| 官方小节（F26 站，2026-10-07 核对） | 原课内接入示例 |
|---|---|
| [Lab 1 SystemVerilog Primer](https://eecs151.org/asic/lab1/docs/pg4-verilog/)：Sequential Logic / Non-Blocking Assignments | [03：旧 Q 与新 D](../course/01_sync_spi.md#03-参考与实验) |
| [Lab 2 Testbenches](https://eecs151.org/asic/lab2/docs/pg3-testbenches/) | [06：独立 SPI slave 与错误注入](../course/01_sync_spi.md#06-参考与实验) |
| [Lab 2 Synthesis](https://eecs151.org/asic/lab2/docs/pg6-synthesis-intro/) | [08：Genus 网表解释](../course/02_synth_sta.md#08-参考与实验)、[AD15：定点校正路径](../adc_digital/04_calibration.md#ad15-参考与实验) |
| [Lab 3 FSM Style Guide](https://eecs151.org/asic/lab3/docs/fsm-style-guide/) | [26：模拟 ready 与等待边界](../mixed_signal/01_power_reset.md#26-参考与实验) |
| [Lab 3 Place and Route](https://eecs151.org/asic/lab3/docs/pg3-place-and-route/)、[Clock Tree Synthesis](https://eecs151.org/asic/lab3/docs/pg4-clock-tree-synthesis/) | [19：物理输入清单](../course/05_physical.md#19-参考与实验)、[20：skew 与 setup/hold](../course/05_physical.md#20-参考与实验) |
| [FPGA Lab 4 Ready-Valid Interfaces](https://eecs151.org/fpga/lab4/docs/pg3-readyvalid/)、[FIFO](https://eecs151.org/fpga/lab4/docs/pg5-fifo/) | [17：同步 FIFO](../course/04_integration.md#17-参考与实验)、[AD08：容量与流控](../adc_digital/02_timing_data.md#ad08-参考与实验)；不替代异步 CDC 证据 |

## 为什么值得学

它把 RTL 语义、验证与 ASIC 实现连接起来，适合补上模拟工程师熟悉晶体管和时序，却尚未形成数字工具证据链的部分。读课时始终追问：哪一段 RTL 是触发器、组合门、时钟负载或物理连线？

## 推荐 Lab 路径与本项目实验

- Lab 2 → `EXP-SPI-BASE`：先解释已有 SPI 独立 TB 与 Genus 网表；门级仿真仍待执行。
- [Lab 4 coverage](https://eecs151.org/asic/lab4/docs/pg1-coverage/) → `EXP-VERIFY-CONTRACT`：建立 busy-start/reset/done 场景计数与缺口表。
- [Lab 4 UVM](https://eecs151.org/asic/lab4/docs/pg2-uvm/)：先理解 stimulus/driver/monitor/scoreboard 分工，当前不强制迁移整个 TB 到 UVM。
- [Lab 4 formal](https://eecs151.org/asic/lab4/docs/pg3-formal/) → 小性质任务：区分 assert/assume/cover，检查 reset、可达性和 vacuity。
- [Lab 3 SRAM/hard macros](https://eecs151.org/asic/lab3/docs/pg4-sram-and-hard-macros/) → `EXP-SRAM-BUFFER`：定义端口/读延迟/同址行为，再考虑宏。
- [Lab 4 signoff](https://eecs151.org/asic/lab4/docs/pg4-signoff/) → `EXP-ASIC-IMPLEMENT`：区分实现工具的 DRC 与独立 signoff 检查；该页讨论 LVS 不等于已在本项目运行 LVS。

课内 VCS/Verdi、Hammer、Jasper、Pegasus、Skywater 环境均未在本项目验证。当前 SPI 使用已有 runner/Genus；正式 P&R 需先核对物理库和技术文件。原实验机器/PDK 配置不直接照搬。

## 学习进度、问题与取舍

目前完成的是资料核对与映射，尚未登记本人阅读或新实验通过。实际过程写 [学习日志](../learning_log/README.md)，验收回 [01–24 workbook](../course/08_workbook.md) 或 [25–48 workbook](../mixed_signal/09_workbook.md)。工程基线见 [progress](../progress.md)。

建议带着问题读：done 的 SVA 观察的是哪个采样时刻？为什么 100% 代码覆盖仍可能漏 busy-start？SRAM 读延迟改变后，ADC 样本标签需要怎么延迟？

目前不投入完整 FPGA 学期作业、CPU 大项目或全套 UVM 搬迁。CDC 专项、数模 settling/校准、ΔΣ 与 AMS 仍回本项目；不能用这里的基础顺序逻辑代替 CDC 物理证据。
