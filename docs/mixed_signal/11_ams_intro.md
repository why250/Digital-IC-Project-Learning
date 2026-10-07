# Virtuoso AMS：工具关系与官方资料入口

资料核对日期：2026-10-04。本页保留工具分工与服务器官方资料位置。逐课实验统一见 [AM01–AM06 课程](../ams/00_course.md)，操作与开课条件见 [环境指南](../ams/07_setup.md)，当前工具状态见 [进度摘要](../progress.md)。

## 工具之间的关系

Virtuoso负责原理图/设计视图，Hierarchy Editor的config负责实例绑定，ADE负责仿真设置与结果。Spectre AMS Designer联合数字事件引擎与模拟求解器：数字RTL由Xcelium引擎处理，模拟电路/Verilog-A由Spectre系列求解器处理，跨域信号经interface elements/connect modules交换。具体支持、兼容版本与许可证依安装而定。

```mermaid
flowchart LR
    A[Virtuoso 原理图与 config 绑定] --> B[ADE AMS / AMS UNL]
    B --> C[Xcelium 数字事件引擎]
    B --> D[Spectre 模拟求解器]
    C <--> E[接口元件 L2E / E2L]
    E <--> D
```

现代流程常用xrun编译、展开和运行；较老教程可能出现Incisive、irun、ncvlog/ncelab/ncsim或OSSN流程。优先按安装版本的AMS UNL说明，不直接复制旧命令或全局初始化设置。runams是Virtuoso/UNL相关批处理入口，不能凭它存在就确认数字引擎与许可证可用。

| 仿真方式 | 适合问题 | 模型边界 |
|---|---|---|
| Spectre＋晶体管/Verilog-A | 模拟电路、连续时间行为模型 | 不能仅靠Spectre替代完整RTL事件仿真 |
| Icarus/Xcelium纯数字 | FSM、协议、定点、行为参考 | 普通逻辑/real参考不解连续电路 |
| Spectre AMS Designer | RTL＋模拟电路/Verilog-A，电压/逻辑边界 | 成本取决于模拟规模与事件活动 |
| RNM/DMS：wreal或SV实数网络 | 高速系统回归与校准行为 | 不是自动建立KCL/KVL/阻抗的SPICE仿真 |

Verilog-A偏重模拟行为；Verilog-AMS可描述模拟/数字混合行为与connectmodule。wreal与SV实数网络的解析/连接能力依具体引擎，不能把普通real变量当作有电气负载的线网。

## 已找到的官方资料

服务器IC_Server上的IC251安装包含下列文件，可在服务器阅读，不复制官方文档或教程库正文进Git。

| 文档 | 用途 | 服务器相对位置（根为 `/opt/eda/cadence/IC251/`） |
|---|---|---|
| Welcome to AMS in ADE | 认识ADE/AMS、netlist/run、connect rules | `doc/WelcometoAMSinADE/Welcome.html` |
| AMS Designer in ADE Explorer FAQ | config、AMS UNL、xrun和常见设置 | `doc/AMSinADEFAQ/chap1.html` |
| Spectre AMS Designer and Xcelium Simulator Mixed-Signal User Guide | 引擎、模拟控制、IE/多电源/运行/调试 | `doc/ams_dms_simug/ams_dms_simug.pdf` |
| Cadence Verilog-AMS Language Reference | discipline、cross、transition、连接模块 | `doc/verilogamsref/verilogamsref.pdf` |
| AMS ADE教程包 | 用于独立工作目录的示例 | `tools.lnx86/dfII/samples/tutorials/AMS/AMSDInADE.tar.gz` |
| AVUM workshop资料 | Virtuoso AMS流程学习资料 | `tools.lnx86/dfII/samples/tutorials/AMS/AVUM_workshop.pdf` |
| runams教程包 | 批处理流程参考 | `tools.lnx86/dfII/samples/tutorials/AMS/runams.tar.gz` |

Welcome/FAQ当前标题版本为IC25.1（2025年6月），混合仿真用户指南为23.09（2023年9月），以各文档自身版本为准。AMSDInADE包已在独立目录解压，2394文件校验；PLL示例尚未运行到仿真。workshop未逐页核对，其中旧菜单/命令需要按当前流程适配。

可在Virtuoso的Help/文档检索中搜索这些英文标题；Cadence支持门户通常需要账户。不同版本的文档界面入口可能不同，找到标题比照搬旧菜单截图更可靠。

## 下一步入口

- [AM01：计数器→DAC→RC](../ams/01_am01_binding.md)：电路、解析预测和具体实验步骤。
- [AM02：接口桥](../ams/02_am02_interfaces.md)：电压、阈值、rout、X/Z 与负载。
- [共用环境与排错](../ams/07_setup.md)：config/ADE 操作、分阶段日志与数值收敛。
- [官方 PLL 尝试记录](12_ams_tutorial_run.md)：已执行步骤、失败阶段与诊断位置。
- [工具栈评估](13_tool_stack.md)：实际版本与兼容性核对依据。

原六步建议已展开为 AM01–AM06，实验参数、操作和验收以各课讲义及共用项目契约为准。
