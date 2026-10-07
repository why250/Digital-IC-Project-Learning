# 验证记录

日期：2026-10-02。服务器：IC_Server（xunipc）。
本地：D:/Users/Administrator/Documents/GitHub/Digital-IC-Project-Learning。
服务器：/home/userone/AAAIC/test_tb/digital_ic_learning。

## 已完成

- 创建独立学习目录和本地 Git 仓库。
- 中文学习路线、SPI 第一课、RTL、自检查 testbench、SDC 和 Genus Tcl。
- 普通 scp 部署，每个文件进行 SHA-256 校验，未发现包装或内容损坏。
- 从公开 EPEL 下载 Icarus 12.0 RPM，校验 RPM 内容摘要，解包至项目 .tools/iverilog。
  没有系统安装，也没有修改全局 PATH；RPM 签名验证不在本次记录范围内。
- 使用真实 Icarus 仿真，使用真实 Genus 25.10-p002_1 综合，Genus_Synthesis 许可证正常签出。
- 仿真/综合产物收集到本地 results，19 个下载文件均通过 SHA-256 校验。
  results 和 .tools 被 Git 忽略；许可文件、教学库正文和 foundry PDK 没有复制进项目。

## RTL 仿真

| HALF_PERIOD_CYCLES | 对应逻辑 SCLK 频率 | 完整交易 | 结果 |
|---|---:|---:|---|
| 1 | 25 MHz | 258 | PASS |
| 3 | 8.333… MHz | 258 | PASS |
| 25 | 1 MHz | 258 | PASS |

合计 774 笔完整交易；每个参数另有一笔复位中止交易。
每组覆盖 A5/3C 首笔交易、所有 256 个发送值、独立接收、
忙时 start 丢弃、输入在锁存后改变、复位中止及复位后恢复。
协议监视器检查 8 次采样、8 次下降沿、半周期、CS setup/hold 和单周期 done。
最后版本编译日志为空，没有残留时间单位警告。

首笔默认参数交易：
- MOSI 采样：10100101 = A5。
- MISO 采样：00111100 = 3C。
- CS 有效时间：8.5 μs。
- 文件：../lessons/01_spi_master/results/sim/div25/spi_first_frame.svg。
- 原始 VCD：../lessons/01_spi_master/results/sim/div25/spi_master.vcd。

## Genus 综合

- 工具：25.10-p002_1；默认参数 HALF_PERIOD_CYCLES=25。
- 库：服务器 Genus 自带 tutorial.lib，typical_case，5 V，25°C。
- 37 个 fflopd、56 个 inv1、171 个 nand2、13 个 nor2，共 277 个单元。
- 单元面积：440.500（教学库面积单位；不是实际工艺面积结论）。
- 最大延迟报告最差 setup slack：14239 ps = 14.239 ns。
- 最差报告路径：miso → rx_data_reg[0]/D，采用教学 SDC 的 5 ns 输入预算。
- 映射前和映射后的 timing intent 检查均为 Total: 0。
- 映射后 check_design：没有 unresolved、empty、undriven、multidriven 或 unloaded 逻辑。
- 网表实例仅包含上面四种教学库单元，无 latch 或残余通用逻辑实例。
- 报告列出 277 个 logical-only 实例：本次没有读取 LEF，这是逻辑综合阶段的预期状态。

工具给出教学库缺少部分阈值/库级属性的消息，
以及默认参数 elaboration 和综合流程选项的提示；没有阻止综合。
不把教学库消息描述成工艺库验证通过。

## 尚未完成的阶段

未做门级仿真、形式等价、布局布线、提取寄生、多角 setup/hold、
功耗活动分析或真实 SPI 器件接口签核。
当前 SDC 的外部 SPI 时序是教学预算；约束检查为零不代表外部协议已签核。

应用项目侧栏尚未注册。当前可调用工具没有创建项目入口，
computer-use 的 guidance.md 明确禁止自动控制 ChatGPT 桌面界面。
源码和服务器项目已经完整建立；可手动添加此本地目录为独立项目并设为主目录。
官方项目说明：https://learn.chatgpt.com/docs/projects#use-local-projects-for-folders-and-codebases

## 下一课入口

先读 01_spi_master.md，完成最后的六个问题。
先解释波形，再阅读 RTL，然后看综合网表和报告。
学习进度达到这里再进入 SPI Slave + 配置寄存器及 CDC。

## 2026-10-03 初始化复核

- 本地项目结构完整；复核前 Git 工作区干净，已有初始化提交 `012b155`。
- SSH 密钥连接 IC_Server 成功，远端项目目录存在；Genus、Innovus 和项目内 Icarus 可执行文件均可访问。
- 19 个 Git 跟踪文件与远端对应文件的 SHA-256 全部一致。
- 19 个已收集仿真/综合产物与远端 SHA-256 全部一致。
- 复核 10 月 2 日已有结果：分频 1、3、25 均为 PASS，每组 258 笔完整交易；Genus 日志含 `SPI_SYNTHESIS_COMPLETE` 和 `Normal exit.`。
- 映射前后 timing intent 均为 0；映射网表再次核对为 37 个 fflopd、56 个 inv1、171 个 nand2、13 个 nor2，共 277 个单元，无其他单元实例。
- 本次复用已验证产物，没有重新安装工具或重跑仿真/综合，没有修改 RTL、testbench 或 SDC。波形、报告和工具继续留在 Git 忽略目录。

项目已具备第 01 课学习条件。入口为 `docs/01_spi_master.md`，随后阅读 `docs/02_read_first_reports.md`。
以上仍是教学库下的 RTL 仿真和逻辑综合结果，未完成布局布线、多角时序或真实器件接口签核。

## 2026-10-03 课程编写

- 新增 `docs/course/` 的 24 节中文课程、六阶段讲义、完整参考答案、实验记录模板与结课项目规格；README 和 roadmap 已接入课程入口。
- 面向模拟 IC 背景，从寄存器/门/负载/PVT 建立同步 RTL 直觉，再学习独立验证、综合/STA、Slave/CDC、原子配置、集成与物理实现。
- 结课设计选择明确输入窗口的 50 MHz clk 过采样 SPI Slave，提供 24 位帧、地址表、pending 快照、安全应用、错误与复位契约；这是待实现课程设计，不是已验证的新模块。
- 学习状态模板保持未填写，不把既有工具 PASS 当成学习者已掌握。物理实现的数据依赖和未执行边界单独列出。
- 本次仅修改课程文档，没有改 RTL、testbench、SDC 或运行脚本，也没有重跑仿真/综合；真实工具结果仍以先前记录为准。
- 文档结构检查：9 个课程文件 UTF-8 解码正常，讲义与答案均连续覆盖 01–24，39 个本地 Markdown 链接可解析；`git diff --check` 通过。

## 2026-10-03 数模混合控制方向课程设计

- 用户明确选择数模混合控制方向，形成 48 节完整课程：保留 01–24 基础，新增 `docs/mixed_signal/` 的 25–48 专项讲义、答案、实验记录和结课规格。
- 专项覆盖数模接口、上电/故障管理、ADC/DAC 时序、定点/平均、校准 FSM、行为模型与故障验证、低功耗、电源域、DFT 和交付评审。
- 结课项目是 SPI 配置、模拟启动/采样管理与 8 位 trim 前台校准，明确最小等待/ready/超时、样本 id/version、有限搜索、取消恢复和数字测量误差判据。
- README 和 roadmap 已将本方向设为主线；建议基础与专项合计 180–260 小时，个人学习状态仍未填写。
- 本次仅设计课程和教学项目契约，未新增或修改 RTL、testbench、SDC、运行脚本；没有重跑仿真/综合，也没有执行 AMS、形式、UPF、DFT 或物理实验。
- 文档检查：基础与专项共 19 个课程文件 UTF-8 正常，讲义/答案各连续覆盖 01–48，63 个本地 Markdown 链接可解析，`git diff --check` 通过。新增单调性前提与端点检查的证据边界。

## 2026-10-03 CT ΔΣ 后级数字滤波课程

- 根据已有 CT ΔΣ ADC 环路滤波器经验，新增独立 `docs/delta_sigma_filter/` 专题：DF01–DF08 讲义、总纲、项目规格、答案和实验/实际参数表，共12份文档；接入README、roadmap和数模混合主线，保留原48节编号。
- 教学案例明确为6.144MHz输入、20kHz带宽、48ksample/s输出，抽取128、OSR153.6；实际调制器参数未提供，不承诺真实ADC性能。
- 候选CIC3/16→HB/2→HB/2→补偿FIR/2，起始31/47/161 taps、位宽与指标均须后续设计验证；明确PSD单位、各级alias、phase、modulo、定点和startup契约。
- 数学核对：CIC冲激相位输出136/120、阶跃816/3536/4096；20kHz下垂−0.1159235dB；候选整链长度12238、算法延迟995.849609375μs；这些不是已实现滤波器的实测结果。
- 专题RTL另用49.152MHz单core时钟，第一课SPI保持50MHz。指出48k×24bit=1.152Mbit/s，1MHz SPI不承担连续结果流。
- 本次仅设计课程与契约，未生成系数、调制器实现或新RTL，未改第一课RTL/testbench/SDC/运行脚本，未重跑仿真/综合。
- 文档检查：12份专题文件UTF-8正常，DF01–DF08讲义/答案连续覆盖，原01–48主线保留；101个本地Markdown链接可解析，`git diff --check`通过。数学核对独立使用boxcar卷积和显式公式；明确FIR饱和标签按卷积历史传播。

## 2026-10-04 ADC 内部数字模块课程

- 新增独立 `docs/adc_digital/` 九份文档：AD01–AD20讲义、总纲、四通道TI项目、答案与实验记录，接入README/roadmap/控制和滤波专题；原01–48和DF01–DF08保留。
- 面向模拟IC背景，覆盖SAR控制、Flash编码、Pipeline冗余、ΔΣ DEM、多相采样、标签重排/CDC、交织失配、前后台校准、定点、版本与实现证据；建议80–120小时。
- 四通道教学例总4Msample/s、12bit、100MHz core；转换延迟有界，80周期重排，系数按帧原子应用并随样本保留；真实多相时钟/skew/jitter/负载/PVT需电路和物理证据。
- 首版结课目标为重排与offset/gain校正，timing/bandwidth和未知输入后台估计先做模型并说明适用条件；SPI承载配置/快照，不能输出72Mbit/s持续结果。
- 本次仅新增/编辑课程文档；未实现新模型/RTL，未改SPI RTL/testbench/SDC/运行脚本，未重跑仿真/综合或物理实验。学习状态均待填写，不借既有SPI PASS。
- 文档检查：九份AD文件齐全，AD01–AD20讲义/答案连续覆盖，原01–48和DF01–DF08讲义/答案保留；46份Markdown文件UTF-8/空白检查通过，128个本地链接可解析，`git diff --check`通过。
- 算例核对：SAR结果677、DWA八元件各用三次、返回顺序0/2/1/3/4/6/5/7、offset DFT与20bit累加范围一致；gain/skew/jitter分别−46.0206dBc/−70.0570dBc/64.0364dB，校正整数1506。这些是解析数值核对，非ADC实测或RTL结果。

## 2026-10-04 ADC 模型与 RTL 实验实现

- 用户明确要求将逐课实现设为goal；新增独立 `lessons/adc_digital/`，七个RTL top、五个testbench、标准库数值/整数/接口/码流参考、独立models/sim/stream/synth脚本及SHA-256结果收集工具。
- AD01–AD20的运行入口和模型/RTL/物理证据分层见 `docs/adc_digital/09_labs.md`。模型包括SAR/Flash/Pipeline/DWA、TI offset/gain/skew/jitter/RC、DC/正弦估计、有限带宽导数校正和条件化后台均值跟踪；真实时钟trim/通用后台RTL/SPI桥不在首版范围。
- 服务器Python3.9.23无需第三方包，复用项目Icarus和Genus独立batch；第一课SPI RTL/testbench/SDC/脚本未改，未重复其仿真或综合。
- 模型脚本exit0、`ADC_MODEL_VERIFICATION_COMPLETE`；受控dither8192份/点/lane做前台估计，随机jitter Monte Carlo与小扰动预算比较，秩不足和lane相关包络反例被识别。
- RTL回归exit0、`ADC_SIMULATION_COMPLETE`：SAR全部1024码/超时/忙启动/reset/单周期done；Flash全部65536二值输入；Pipeline100份对齐/错标签/非法trit；DWA q=0…8/非法q/指针保留；异步FIFO10ns/14ns满空/越界/环绕/协调复位；定点14103份全raw范围/随机signed系数/负数tie/RNE/saturation/flush。
- TI独立台账最终18场景通过，normal/random各513份输出，包含三lane同时返回、缺失/迟到/重复/错lane/tag/epoch、请求/返回/释放/校正四阶段复位及旧epoch、sink违约、id/version guard，整组系数原子切换及冻结统计验证。故障进入sticky HALT并拒绝同拍commit。
- 连续流exit0、`ADC_STREAM_VERIFICATION_COMPLETE`：采集65540份，丢弃四份旧版本后65536份连续id/epoch/version/逐样本整数值全部一致。N65536/bin6001、4MHz、1000LSB模型下，SFDR从36.478dB到98.060dB，RTL校正后SNDR67.791dB；仅是受控offset/gain合成失配结果，非真实ADC性能。
- 最终七top教学库映射/setup通过：SAR581cells/6885ps、Flash241/5653ps、Pipeline1327/6429ps、DWA162/7464ps、定点3691/2474ps、FIFO1162/8106ps、TI后端18625/2317ps。七top映射前后timing intent均0，mapped netlist实例来自实际教学库，无未映射procedural逻辑/未知单元/latch，check_design无unresolved/empty/undriven/multidriven。命令exit0、Genus完成标记/Normal exit及`ADC_SYNTHESIS_VERIFIED_OUTPUTS tops=7 mode=existing-reports`全部确认。
- Genus当前report_timing不支持early/hold，本流程报告setup；未执行hold/CTS/寄生/多角/功耗/形式/门级或物理签核。FIFO CDC例外有教学条件，Gray bus物理skew/max delay与MTBF未验证。库有xor2等单元，checker根据实际tutorial.lib建立完整单元清单，并拒绝未知单元/procedural逻辑/latch。
- 首轮TI batch逻辑映射耗时过长，检查结构后主动终止自己的独立进程（不记PASS），将每slot写回固定到所属lane、局部时间差缩为8bit，全局tick/完整tag保持；缩位依赖80周期slot寿命/故障截止。修改后RTL整套回归再次exit0，继续重跑连续流与TI综合。未动GUI/共享服务。
- 优化后连续流再次exit0、SFDR/SNDR不变，TI后端新batch正常退出且setup通过；其余六top源设计未改，复核已有报告而非重复综合。检查器保存单元分布、setup、报告SHA-256和未执行hold信息到每top的`verification.json`。
- 已回收155份模型/trace/报告/网表/码流/VCD到本地Git忽略的results，逐文件普通scp与SHA-256全部一致，收集脚本exit0、`ADC_RESULTS_COLLECTED_HASH_VERIFIED files=155`。
- 最终文档检查48份Markdown/141个本地链接，UTF-8与空白检查通过，`git diff --check`通过；83份源文件已普通scp同步且逐文件SHA-256核验。当前教学目标已实现，个人掌握与真实ADC/物理签核仍独立记录。

## 2026-10-04 个人学习路线整理

- 根据用户确认的模拟 IC 背景、CT ΔΣ 环路经验和数模混合发展目标，更新 roadmap 为个人路线：公共数字基础、配置/CDC、测量/校准控制，再优先深入 ΔΣ 抽取滤波，扩展 TI-ADC 校准；现有课程编号和总纲保留。
- 在第 01 课内部补充数字表示、组合逻辑、寄存器、非阻塞赋值、计数器、移位、FSM、验证、完整 SPI 和综合/STA 的十步入口。20–30 小时为基础课程内的初始练习预算，不额外累加。
- README 接入个人路线；基础微实验目前是任务清单，未新增可运行 RTL。现有工具 PASS 与个人掌握程度仍分开记录，ΔΣ 抽取链仍待实现。
- 本次仅整理课程文档，未修改 RTL/testbench/SDC/脚本，未重跑仿真或综合。
- 四份改动文档严格 UTF-8 解码正常，41 个本地文件链接存在，`git diff --check` 通过；本次更新保存在本地项目。

## 2026-10-04 时间交织 DAC 课程与项目建议

- 新增独立 `docs/dac_digital/` 八份文档、TD01–TD12讲义/练习/答案/记录/结课规格，接入README、roadmap与控制总纲，保留原01–48、DF和AD编号。
- 教学选择四lane门控脉冲求和，总4M、lane1M、12bit、100MHz core，提前100ns加载；单lane为1/4占空RZ、总理想ZOH。持续保持求和、并行接口、DEM与真实交织分别说明。
- 首版规划四样本帧输入、整数offset/gain校正、原子版本、预加载/gate与欠载HALT；插值/DDS/DEM/CDC逐级扩展。timing/width/settling需独立连续时间核，数字码FFT不代替模拟谱。
- 新增数模混合项目建议：优先测量/trim和CT ΔΣ抽取，再交织ADC/DAC，PLL启动/粗调、数字辅助LDO、BIST/集成按前置条件展开；后四类尚无完整专门实现。
- 本轮仅编写本地课程文档，未新增DAC模型/系数/RTL/运行脚本、未部署、未重跑SPI/ADC仿真综合。个人状态仍待学习，未宣称DAC工具或性能PASS。
- 文档核对55份Markdown/179个本地文件链接，严格UTF-8、空白与`git diff --check`通过，TD01–TD12讲义/答案连续齐全。独立算术核对ZOH下垂−0.008931659/−0.912097584dB、四相DC增益、DDS频率步长、RNE校正94码、相干频率与load/on台账；这些是解析检查，不是新DAC模型或RTL测试结果。

## 2026-10-04 Virtuoso AMS 文档与环境只读核对

- 根据用户关于Virtuoso/AMS教程的问题，新增中文官方资料入口与六步实验建议，接入README和控制总纲。检查Welcome/FAQ（IC25.1）与混合仿真指南（23.09）的HTML，确认AMS UNL/config、xrun数字事件引擎与Spectre模拟求解器关系。
- 服务器可定位Virtuoso/Spectre可执行文件和IC251官方文档；AMS教程目录含AMSDInADE/runams等归档与AVUM_workshop.pdf。只读查看两归档清单，未展开、复制或执行官方例子，官方文档/库正文不入Git。
- 当前SSH PATH未找到xrun/irun，已检查Cadence安装根最大五层也未找到xrun；不排除其他安装位置/环境。未检查AMS许可证或签出许可，未宣称联合仿真可运行。
- 新讲义包含logic/electrical接口桥、RC/settling、视图逐步替换、SAR/trim/转换器集成路线与可验证边界。AM01–AM06是待实现任务，无新OA库、模型、RTL或脚本。
- 本轮未启动/修改GUI或共享服务，未改全局PATH、许可证、第一课或ADC/DAC设计，未运行AMS或重复已有仿真综合。
- 四份改动文档严格UTF-8/空白检查及51个本地链接通过，`git diff --check`通过；RC解析算例τ=100ns、t50=69.314718ns、1%settling=460.517019ns，加入1kΩ源阻抗后τ=110ns。仅为算术核对，无AMS运行结果。

## 2026-10-04 AMSDInADE 解压与实际批量启动

- 用户授权解压运行；将官方AMSDInADE.tar.gz放在独立`.tools/ams_tutorials/amsd_in_ade_20261004_he_3kf81/`下解压，验证2394普通文件、1294目录，无软/硬链接；拒绝越界/特殊成员，逐文件SHA-256与归档一致。
- 保留source快照并建work副本。教程带GPDK090模型/OA库，均留服务器Git忽略目录，未复制库/模型正文到源码。运行后再次校验2394源文件未变。
- 确认testbench为amsPLL/PLL_160MHZ_sim/config、ams_state1，保存tran2u、fREF25M。旧状态为OSS-based/irun、ConnRules_18V_full_fast、模型$TestDir路径。
- 独立virtuoso -nograph只读打开顶层schematic，exit0、AMS_TESTBENCH_INSPECTION_COMPLETE，读到22个实例；教学GPDK加载成功，Framework License(111)签出成功，不等于AMS/Xcelium许可。
- 实际runams -nocdsinit -netlist all -simulate batch退出255，日志AMS-1172缺connectLib，随后strcat nil和生成网表失败。未进入编译/展开/仿真，未产生波形，诊断AMS_NOT_RUN。runams自动删除work中两个旧状态选项，source不变。
- SSH PATH及Cadence安装树未发现xrun/irun/xmsim/ncsim，IC/Spectre下未找到connect库，AMSHOME未设置；不排除其他安装位置。需要兼容数字引擎/连接库、进程局部TestDir和旧状态迁移后继续，未擅改全局PATH或安装工具。
- 普通scp回收10份日志/诊断/哈希清单到本地results/ams_tutorial，逐文件SHA-256通过，AMS_TUTORIAL_ARTIFACTS_COLLECTED_HASH_VERIFIED files=10。未执行归档clean_up、未动既有GUI/服务；两次自身batch均已退出，SPI/ADC/DAC设计未改或重跑。
- 新增中文解压/启动记录并更新AMS入口，真实失败与原理图可读性分别记录，不登记AMS PASS。
- 四份改动文档严格UTF-8/空白及39个本地链接检查通过，`git diff --check`通过；再次确认本次runams进程已退出、日志记录独立slave session关闭。

## 2026-10-04 IC25.1工具栈评估

- 只读核对virtuoso -W为IC25.1-64b.38、spectre -W为25.1.0.054，DDI README为25.10-p002_1并明确Genus/Innovus/Joules三个产品；JSTUDIO是Joules Studio，不是JasperGold。
- Innovus内qrc/quantus可执行入口存在，ExtCce/extQrcx组件为24.10-s201；DDI README声明配套Virtuoso/Tempus/Voltus25.1、Quantus24.1.0-s201。组件存在不登记提取或功耗流程PASS。
- calibre -version确认2025.2_38.18；服务器RHEL9.7/x86_64。ADS2025/2026/2027仅确认目录，未逐一验证版本/许可。当前PATH未找到Xcelium/SimVision/Tempus/Voltus/JasperGold/Conformal/Modus，不排除其他位置。
- 新增工具栈与候选版本建议，保留现有基线，Xcelium25.03维护版作为优先评估候选；精确ISR及IC/Spectre/RHEL组合兼容仍待官方矩阵，不宣称认证或最新版本。AMS文档明确按Xcelium spectre_compatible_version.xml核对，当前缺该安装。
- 使用Browser技能尝试公开资料核对，未取得完整兼容矩阵；以实际版本和本机DDI/AMS文档为证据。未读取许可正文、安装/升级软件、改变全局环境或重跑设计。

## 2026-10-04 AM01–AM06完整学习课程

- 按用户的六步实验建议新增独立docs/ams课程：总纲、六课讲义、设置/排错、共用模型/项目契约、参考答案和个人记录，共11份。每课包含前置、解析预测、操作步骤、正常/故障实验及验收；AM06分CT ΔΣ与交织DAC支线，建议先选CT ΔΣ。
- 预算64–96小时；保留SPI第一课及已有所有课程编号。明确DAC分母/编码、floor与RNE、采样和应答时间、桥rout/阈值/X策略、旧结果隔离、SAR既有valid优先与trim超时优先的差别。
- 接入README、控制总纲、AMS简介和学习路线。课程设计已完成，自建模型源码/OA/testbench/回归及真实AMS验证尚待逐课实现；已知官方PLL仍停在缺connectLib的网表阶段，不登记PASS或个人掌握。
- 未安装工具、创建OA库、启动远程仿真或改共享环境；未修改/重跑已有SPI/ADC RTL。所有PDK/教程/许可/报告/波形继续留在Git外。
- 本轮16份文档严格UTF-8、空白及135个本地链接/课程锚点检查通过，六课讲义/答案/记录连续齐全，git diff --check通过。独立算术核对RC、39/55拍等待、floor码、SAR十次trial、RNE平均及trim可接受码100…106、相关频率和FFT基频；这是文档/解析验证，不是AMS运行结果。
