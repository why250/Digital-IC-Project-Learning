# Virtuoso AMS：官方教程入口与入门实验路线

日期：2026-10-04。适合已有Spectre与模拟电路经验、正在补齐RTL的工程师。本文整理官方资料与建议实验。用户随后授权解压并尝试官方PLL例，已确认原理图可读，AMS启动失败在网表阶段，见 [实际运行记录](12_ams_tutorial_run.md)。主线仍从单系统时钟SPI开始，AMS独立开展。

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

## 当前服务器具备什么

只读检查找到：

- Virtuoso：`/opt/eda/cadence/IC251/tools/dfII/bin/virtuoso`。
- Spectre：`/opt/eda/cadence/SPECTRE251/bin/spectre`。
- IC251中AMS集成脚本、上述文档与示例包。

当前SSH PATH及进一步检查的Cadence安装树未找到xrun/irun，IC/Spectre下未找到所需connect库。可能是未安装、另有目录或环境未配置，不能排除其他位置。Virtuoso框架许可已在独立批处理签出，AMS/Xcelium许可未验证。runams实际失败在缺connectLib的网表阶段，不能确认联合仿真可运行。

后续实际运行需定位兼容Xcelium、确认所需AMS/数字/模拟许可并跑最小例子；不必为阅读教程先修改全局PATH。已有GUI/服务保持独立，实验使用自己的工作目录与结果目录。

## 六个建议实验

六步已扩展为 [AM01–AM06完整课程](../ams/00_course.md)，包含逐课操作、计算题、故障实验、参考答案、结课接口和个人记录，预算64–96小时。下表保留概览；尚无自建模型、Virtuoso库、testbench或脚本。先完成基础01–06的寄存器/FSM，再做AM01–AM03；AM04–AM06按对应ADC/校准/滤波基础推进。

| 顺序 | 实验 | 学会什么 | 验收产物 |
|---|---|---|---|
| AM01 | RTL计数器＋理想DAC＋RC，绑定config并运行短tran | 混合层次、选视图、netlist/compile/elaborate/run | 同时看到码值、DAC输出和RC电压 |
| AM02 | logic→RC电压→logic回读，修改供电/阈值/负载 | L2E/E2L、阈值、rout、tr/tf和初始状态 | 理论RC与跨阈时刻一致，桥位置正确 |
| AM03 | 改码后等待settling再测量 | code-load、量化、采样窗口/早采样 | 正确等待与提前采样的误差对照 |
| AM04 | SAR控制＋DAC模型＋比较器模型，逐步换晶体管视图 | conversion、比较器延迟、有效窗口 | 逐次trial/decision/结果与独立参考一致 |
| AM05 | trim FSM＋可观测plant＋ADC/比较器＋ready | 前台测量、噪声、timeout、取消恢复 | 正常收敛及非单调/饱和/未ready失败 |
| AM06 | CT ΔΣ模型＋后级滤波，或四路DAC门控重构 | 混合码流、多速率、时序/数值/模拟谱 | 独立码流台账、频谱口径及模型边界 |

先将模拟部分用RC/Verilog-A建成小例子，数字部分用已有验证的RTL。通过后只替换一个关键模块为晶体管/提取视图，并比较替换前后响应。每次替换重新确认模型接口、电压、负载与延迟，不一次把完整ADC所有模块变成晶体管级长FFT仿真。

## AM01的具体操作框架

1. 在独立Virtuoso库建top testbench，放入数字计数器symbol、理想DAC行为模型、R/C、供电和时钟。数字计数器先用clk/reset独立验证；不修改SPI第一课。
2. 建config，选择AMS模板，检查每个实例绑定：数字用RTL文本视图，DAC用所选行为视图，RC用schematic。view名字取决于导入方式；显式确认绑定，不只依赖switch view list默认顺序。
3. 从该config进入ADE，选择AMS相关仿真流程。当前官方FAQ给出的Explorer设置是Simulation → Netlist and Run Options → AMS Unified netlister with xrun；其他版本以本机帮助为准。
4. 检查logic/electrical端口discipline与边界。如果DAC行为模块显式接受数字bus并输出electrical，码值转换由它定义；若用electrical bit输入的Verilog-A DAC，则每bit需要适当logic→electrical转换。两种接口不要重复转换或混淆。
5. 设置供电、connect rule/IE的电平、tr/tf、rout与E2L阈值/初始规则。数字码不是“12根电压线直接相加”；DAC编码、FS、共模与输出阻抗由DAC模型明确表达。
6. 做短transient并保存数字码、DAC电压、RC节点、clk/reset。逐级检查netlist、编译、展开与仿真日志，以及实际插入的IE；只有波形输出不证明绑定正确。
7. 再改变RC、门限与等待时间，重跑并核对解析值；先建立一个受控错误反例，再扩展到长流/FFT。

供电电平、阈值和时间精度是模型参数，必须和接口统一。检查上电初态、X/Z的桥行为、迟滞及阈值附近噪声。理想E2L只体现所定义的判决，不证明真实比较器亚稳态/恢复时间；需要电路或显式非理想模型。

## 用一个RC算例判断仿真是否合理

理想0→1V阶跃驱动R=10kΩ、C=10pF，时间常数τ=100ns，Vc(t)=1−exp(−t/τ)。到0.5V为τln2≈69.315ns，到1%终值误差为τln100≈460.517ns；可把提前采样与充分等待对照。

此公式假定源阻抗为零、边沿理想、无额外负载。若L2E有rout=1kΩ，则理想阶跃下τ=(R+rout)C=110ns；有限tr/tf还需卷积或对应瞬态分析。模型桥的阻抗与slew会改变电路响应，不能把它们当绘图设置。

减小最大模拟步长/收紧容差检查结果收敛，并确认数字timeunit/timeprecision足以区分计划事件。模拟maxstep与数字precision解决不同问题。EOC与clk相邻时需明确结果保持/握手，不能靠事件调度先后完成CDC证明。

## 怎样接回当前课程

上电/settling与trim对应 [25–44](00_course.md)，SAR对应 [AD课程](../adc_digital/00_course.md)，CT ΔΣ滤波对应 [DF课程](../delta_sigma_filter/00_course.md)，交织DAC重构对应 [TD课程](../dac_digital/00_course.md)。AMS是这些项目的混合电路验证方法，可逐步增加，现有纯RTL/整数回归继续负责数值与协议检查。

首次资料整理没有运行设计；后续授权实验已展开官方例并批量读取OA、尝试runams，未进入联合仿真，见运行记录。没有修改已有GUI、许可证或全局环境。后续登记绑定、连接规则、模型范围、退出码/实际结果；模拟/工艺/物理签核仍使用各自证据。
