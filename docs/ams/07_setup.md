# AMS 环境、Virtuoso 操作与分阶段排错

本页为六课共用操作指南。课程各课说明具体电路与参数；这里解决如何确认工具流程真的运行到目标阶段。[总纲](00_course.md) · [记录](10_workbook.md)。

## 当前真实状态与开课条件

服务器已确认 Virtuoso IC25.1-64b.38、Spectre25.1.0.054、DDI25.10-p002_1。官方 AMSDInADE 已独立解压，PLL top/config 可读；首次runams退出255，在缺connectLib的网表阶段失败，未进入AMS仿真。

当前SSH PATH及已检查Cadence目录未找到xrun/irun/数字引擎，IC/Spectre树未找到所需连接库，不排除其他安装位置。AMS/Xcelium许可未验证。详见 [实际尝试](../mixed_signal/12_ams_tutorial_run.md) 与 [工具栈](../mixed_signal/13_tool_stack.md)，不重复解压或启动旧任务。

实际运行新实验之前需要：兼容的Xcelium/AMS安装及连接库，IC/Spectre配套组合，所需授权许可，个人工作目录中的最小例子通过。Xcelium25.03维护版只是候选，精确ISR/OS支持以官方矩阵及安装内 `spectre_compatible_version.xml` 核对，不能直接写“25.03一定兼容”。本课不自动安装软件、不改全局PATH。

暂未具备工具时：完成解析题、接口表、独立RTL/数值参考和testbench设计；把真实联合仿真项留待运行。纯Spectre＋Verilog-A可跑模拟模型，但不替代RTL数字事件引擎；wreal/RNM也不自动解节点阻抗与KCL/KVL。

## 个人目录与数据边界

远程项目为 `/home/userone/AAAIC/test_tb/digital_ic_learning`。后续实现建议自有源码放 `lessons/ams/`（当前尚未创建），个人OA库放项目 `.tools/ams_course/<run_id>/`，仿真/波形/报告放 `results/ams_course/<run_id>/`。专有PDK、官方教程和连接库仍引用已授权安装位置，不能复制入Git。

独立批处理与个人ADE状态不修改其他GUI会话或共享服务。脚本只给子进程配置必要工具路径，不更改全局环境。远程传输使用普通scp，并在两端比较SHA-256；若文本异常先检查哈希、编码和行尾，不能直接使用另一个转码方式掩盖损坏。

## Virtuoso 共用操作顺序

1. **建立模型与symbol。** 将RTL导入合适文本视图，模拟行为选择Verilog-A或Verilog-AMS并区分端口域；导入菜单/视图名取决于版本。保证symbol与源码的端口名、方向、总线位序一致。
2. **建立top schematic。** 放数字模块、模拟对象、驱动、供电和地，指定元件参数/初态，标记每个测量节点。使用PDK时加入对应model section，不混用不相关工艺模型。
3. **建立config。** 用AMS相关模板/设置逐实例指定视图，填写counter/FSM、DAC、cmp、RC和适配器绑定表。确认stop/switch view list与实例覆盖规则没有隐藏地选中另一个视图。
4. **从config打开ADE。** 当前IC25.1 FAQ在Explorer给出的设置为 `Simulation → Netlist and Run Options → AMS Unified netlister with xrun`；其他版本按本机帮助确认。检查实际top和保存状态属于个人试验台。
5. **定义边界。** 对IE/connect rule显式检查VDD/VSS、阈值、rout、tr/tf、初始化及X/Z。选择自写桥时确认没有重复自动插桥。总线混合DAC的逻辑输入与electrical-bit DAC的接口要分别处理。
6. **配置短tran和保存。** 记录stop time、模拟容差/maxstep、数字timeunit/timeprecision、initial condition及保存信号；先跑几个受控事件，再做长码流。数字边界可先用1ns/1ps的精度计划，非整数时钟周期需记录实际量化误差；它不是模拟求解精度。
7. **逐阶段检查。** 检查netlist、compile、elaborate、simulate的退出/完成情况，确认实际参数/绑定/插桥；再读波形与独立检查结果。
8. **导出和存档。** 数字按sample_event/id导出，模拟测量用实际节点和时间；保存工具版本、模型版本、随机种子、绑定表和误差阈值。导出的报告/波形仍在忽略目录。

不要照抄旧教程中OSS/irun状态到新流程。已有PLL示例保存的旧连接规则为 `ConnRules_18V_full_fast`，不能因此把本课1 V/2 V接口也设为1.8 V；应重新建立适配状态。

## 两种时间机制如何一起检查

数字寄存器在clk事件后按NBA等调度更新；模拟电压按方程连续演化。mixed模型更新目标会触发新的模拟响应，crossing再产生离散事件。把LOAD、模拟跳变、sample、valid、消费边沿分别保存；同一时刻竞争要用保持窗口/明确相位消除，不能通过“这次仿真先执行谁”证明硬件正确。

一阶RC理想基准从maxstep≤τ/20开始只是初始选择。AM02阈值误差要求通常需要更细步长/事件定位；有2 ns边沿或1 ns缺口时需按最短特征进一步限制并复核。只保存稀疏点可能丢掉波形，即使求解器内部已解析事件，因此保存/导出网格也要记录。

收敛操作：固定电路与刺激→减半maxstep→收紧reltol及相关电压/电流绝对容差→加密导出/测量网格，比较关键电压/时间/谱线。数字precision另做测试；容差变化导致结果变化大时优先找事件、初态、模型不连续和测量插值。

## 按失败阶段排错

| 阶段/现象 | 优先检查 | 可以证明什么 |
|---|---|---|
| OA/config读不开 | library路径、view、端口/总线 | OA可读只证明设计数据库可读 |
| 网表报connectLib缺失 | 安装/引用路径、连接规则、旧状态 | 尚未进入编译/仿真 |
| 编译/展开失败 | HDL语法、discipline、缺模块、参数 | 无运行结果；不可解读“模拟精度” |
| 许可/进程启动失败 | 对应产品与子进程环境 | Virtuoso框架许可不证明AMS许可 |
| 模拟初始解/收敛失败 | 浮空节点、理想源冲突、初态/模型连续性 | 先修模型，不直接降级为RNM掩盖阻抗问题 |
| 电压合理但码错误 | 位序、量程、signed、阈值、采样时刻 | 定位模型/数字契约 |
| 结果随步长变化 | crossing、最短脉冲、保存网格、FFT重采样 | 尚未完成数值收敛 |
| 仿真退出正常但检查失败 | 独立oracle、身份/时序/性能 | 工具完成不等于实验通过 |

后续脚本必须同时检查进程退出码、各阶段完成、检查器完成和PASS/FAIL。建议自建课程检查器使用 `AMxx_CHECKS_COMPLETE`＋明确用例统计；这是待实现要求，当前没有这些运行标记。失败保留原始日志和第一个错误，不只保留最后一行退出码。

学习结果分类为“解析完成／数字验证／AMS行为验证／电路替换验证”。每类写实际证据；课程设计完成与实验掌握分别登记。
