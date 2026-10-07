# 公开资料与项目知识节点映射

状态：**已接入课程导航，持续维护**。版本：v1.0，2026-10-07。来源页见 [参考体系](README.md)，实际学习过程见 [Learning Log](../learning_log/README.md)。

本页是关系中心：以 K01–K19 连接现有课程、公开资料和自己的实验，保留 94 个课号与数模混合主线。建议实验均不是新运行结果；已有工具证据引用 [progress](../progress.md)，不重新登记 PASS。个人验收仍由原 workbook 维护。

## 1. 设计结论

保留现有六个方向，以稳定的知识节点连接课程、外部资料、自己的实验和学习记录。公开课、教材、YouTube 系列都是资源类型，不各自建立一套学习树。

```text
当前项目提出的问题
  → 知识节点 Kxx
  → 本项目课号 / 讲义
  → 一个首选外部 Lecture / Lab / Reading
  → 自己的预测、实验与 artefact
  → 证据、解释与未解决问题
  → 原课程验收 / 最终项目能力
```

节点索引解决“这个知识在哪里、资料该挂到哪里”；[roadmap](../roadmap.md) 决定个人学习顺序。节点不另设课时、完成打卡或必须逐项读完的课程顺序。

优先建立映射并补证据链。SDC、setup/hold、CDC、CTS、功耗、DFT 已有程度不同的覆盖，不再按公开课标题重复编写讲义。数模接口、校准、ΔΣ 抽取、TI-ADC/DAC 和 AMS 继续由本项目主导。

## 2. 审计基线与现有体系

审计对象是当前本地工作区，不是只看 Git 已提交版本。origin 为 `why250/Digital-IC-Project-Learning`，当前提交为 `4d42414`；开始时已有文档整理、部署脚本和网站的未提交工作，全部保留。未查询远端服务器，也未重跑 EDA。

已完整阅读 README、roadmap、progress，以及以下六目录的 64 份 Markdown（含总纲、全部讲义、答案、项目规格、workbook 和工具参考）。另读 AGENTS.md、running、文档检查器、网站说明与内容索引，并检查 lessons 源码目录和综合入口。仓库内只发现根 AGENTS.md，未发现项目内 SKILL.md 或额外嵌套 AGENTS.md。

| 方向 | 课程范围 | 现有组织与能力 | 实现 / 证据状态 |
|---|---|---|---|
| [数字基础](../course/00_course.md) | 01–24 | SPI→RTL→验证→综合/STA→CDC/配置→集成→物理基础→配置项目 | SPI Master 有 RTL/TB/SDC 和既有 sim/synth 证据；微实验、Slave/配置项目待实现 |
| [数模混合控制](../mixed_signal/00_course.md) | 25–48 | 上电/故障、采样/settling、定点、trim、模型/性质、低功耗/DFT | 讲义与测量/trim 契约齐全，完整控制项目待实现 |
| [ΔΣ 后级](../delta_sigma_filter/00_course.md) | DF01–DF08 | PSD→FIR→alias→CIC→多级/多相→预算→定点→RTL | 解析算例已核对；正式系数、模型和 RTL 待实现 |
| [ADC 内部数字](../adc_digital/00_course.md) | AD01–AD20 | SAR/编码/DEM、标签/重排/CDC、交织失配、估计/校正、版本和回归 | 数值模型、七个 RTL top、独立回归、连续流与教学 setup 已有证据 |
| [TI-DAC 前端](../dac_digital/00_course.md) | TD01–TD12 | 重构/插值/DDS、预加载/交付、失配/校正、DEM、三层验证 | 讲义与架构契约齐全；模型/系数/RTL 待实现 |
| [Virtuoso AMS](../ams/00_course.md) | AM01–AM06 | 绑定→接口桥→settling→SAR→trim→CT ΔΣ 或 DAC 联验 | 自建实验待实现；官方 PLL 尝试缺 connectLib，未进入仿真 |

合计 **94 个课程节点**，不是 94 份独立讲义；多课共用一个阶段文件。各方向已复用 CDC、定点、频谱与配置版本知识。个人 workbook 仍待填写，已有工具 PASS 不代表个人验收通过。

工程基线有独立 stimulus/reference、边界/故障用例、完成标记、退出码、映射与 timing intent 检查、scp/SHA-256 收集。SPI 全 256 TX、非回环 RX、busy-start、reset、done 和分频 1/3/25 的契约继续适用。

## 3. 知识节点：新增资源的稳定挂载点

K 编号不含课程名、学校名或学期；名称调整不改 ID，废弃节点保留迁移说明。一个课号可以连接多个节点，一个外部资源也可以服务多个项目。先用 Markdown 表维护，稳定后再考虑机器可读索引。

| 节点 ID | 核心问题 / 能力 | 本项目归属 |
|---|---|---|
| K01 | 数字抽象与 CMOS：逻辑电平、门、延迟、负载/PVT 如何连接？ | 01 内基础练习、07、19–22 |
| K02 | 同步 RTL：Q→组合逻辑→D、NBA、位宽、使能与复位 | 01–05；全部 RTL 项目复用 |
| K03 | FSM 与接口契约：何时接受、拒绝、完成、取消？ | 01–06、23–24、25–32、39–40、AD02 |
| K04 | 事务、寄存器、原子配置与流控 | 13–18、23–24、AD17、TD05–07/10 |
| K05 | 验证：独立参考、lint、性质、SVA、随机、覆盖率与形式 | 06、15、24、41–44、AD18–19、TD12 |
| K06 | 综合与架构优化：映射、位宽、逻辑重构、流水/资源复用 | 07–08、48、DF08、AD15/19、TD12 |
| K07 | 时序与约束：setup/hold、接口预算、uncertainty、例外、MMMC | 09–10、20–21、48、AD19 |
| K08 | CDC 与跨域复位：电平、事件、mailbox、Gray、epoch | 11–15、AD08、TD07、真实转换器接口 |
| K09 | 存储：FIFO、RAM 语义、SRAM 宏、模型/时序/物理视图 | 17、DF08 历史缓冲、AD08；SRAM 部分待补 |
| K10 | 物理实现与验证：floorplan→placement→CTS→routing→提取→DRC/LVS | 19–21、48；后两项待补教学步骤 |
| K11 | 功耗与电源意图：活动、ICG、唤醒、隔离/保持/电平转换 | 22、31、45–46、AD20 |
| K12 | DFT/测试模式：scan、ATPG 与模拟控制输出的拥有权 | 47、48、后续 BIST |
| K13 | 数模控制窗口：MIN/ready/MAX、settling、quiet、故障/恢复 | 25–32、AM03/05 |
| K14 | 定点与 DSP 数据通路：编码、位宽、RNE、饱和、流水标签 | 33–36、DF07–08、AD15、TD10 |
| K15 | 校准与可辨识性：激励、估计、搜索、收敛、误差/漂移 | 37–40、AD09–16、TD08–10、AM05 |
| K16 | 多速率与转换器频谱：PSD、alias/image、CIC/FIR、抽取/插值 | DF01–DF08、TD01–04；AD 复用 PSD |
| K17 | ADC/DAC 架构中的数字控制、编码与 DEM | AD01–05、TD11、AM04 |
| K18 | 交织时基与样本身份：lane、tag、重排、预加载、skew/jitter | AD06–12/17–20、TD05–09 |
| K19 | AMS：视图绑定、logic/electrical、求解、采样与逐块替换 | AM01–AM06 |

加入新资料时先回答：它解决哪个节点的问题？补的是概念还是工具实践？已有首选是否足够？能带回哪个本项目实验？没有具体用途时先不纳入，不为链接另建节点。新节点只在现有能力集合无法表达新工程问题时增加。

## 4. 外部资料核对与各自定位

核对日期：2026-10-07。以下只保存入口、主题及适用理由，不镜像课件、答案、教材或学校工具配置。推荐主题属于选择性阅读，不表示学过或实验通过。

| 资源 ID / 版本 | 官方入口及已核对的细分入口 | 推荐用途与取舍 |
|---|---|---|
| B151-F26：Berkeley EECS 151/251A，Fall 2026 | [学校课程说明](https://www2.eecs.berkeley.edu/Courses/EECS151/)、[当前公开站](https://eecs151.org/)、[ASIC Lab 2](https://eecs151.org/asic/lab2/overview/)、[Lab 3](https://eecs151.org/asic/lab3/overview/)、[Lab 4](https://eecs151.org/asic/lab4/overview/) | RTL/验证首选；Lecture 4–7 对应 HDL/顺序逻辑/TB/FSM，10 对应流水，12 对应 formal。Lab 2 综合/门级，Lab 3 P&R/SRAM/CTS，Lab 4 coverage/UVM/SVA/formal/物理检查。使用方法，自己的案例仍是 SPI/转换器 |
| C5745-S23：Cornell ECE 5745，Spring 2023；handout 各有版本 | [课程](https://www.csl.cornell.edu/courses/ece5745/)、[schedule](https://www.csl.cornell.edu/courses/ece5745/schedule.html)、[handouts](https://www.csl.cornell.edu/courses/ece5745/handouts.html)、[S01 front-end](https://cornell-ece5745.github.io/ece5745-S01-front-end/)、[S02 back-end](https://cornell-ece5745.github.io/ece5745-S02-back-end/)、[Tutorial 4](https://cornell-ece5745.github.io/ece5745-tut4-asic-tools/)、[S05 SRAM](https://cornell-ece5745.github.io/ece5745-S05-srams/) | ASIC 方法首选；T01 HDL、T05 方法、T08 testing、T12 synthesis、T13 physical automation 为 handout 主题。学习 RTL→网表→P&R→延迟/能量评估，以及 baseline/alternative/evaluation 项目里程碑。Lab 1 流水整数乘法器可启发定点通路优化；排序/CPU 集成为选读 |
| M6004-S17：MIT 6.004，OCW Spring 2017 | [OCW](https://ocw.mit.edu/courses/6-004-computation-structures-spring-2017/)、[课程伴随站](https://computationstructures.org/)、[notes](https://computationstructures.org/notes/index.html)、[labs](https://computationstructures.org/exercises/index.html) | 数字抽象首选：单元 2–6（抽象/CMOS/组合/顺序/FSM）、7–8（性能/取舍）、15（流水）选择阅读。结合自己的寄存器/计数器实验；Beta CPU、ISA、编译/虚拟内存不设必修 |
| RABAEY-DIC2：Berkeley EE141 / Rabaey 补充资源 | [Digital Integrated Circuits 第 2 版配套站](https://icbook.eecs.berkeley.edu/)、[章节索引](https://icbook.eecs.berkeley.edu/resources/powerpoint-slides) | 本次核实的是教材配套站，不冒充已核实某学期 EE141。优先 Ch4/5/6/7/9/10（线/反相器/门/顺序/互连/时序），Ch11 算术、Ch12 存储按需。连接 slew/load/PVT 与单元抽象；不重学全部器件基础 |
| S271-PUBLIC：Stanford EE271，公开页未标学期 | [课程公开页](https://web.stanford.edu/class/ee271/) | 公开主题包括 delay/logical effort、HDL/synthesis、DFT、dynamic/static/formal verification。作第二参考；详细 syllabus 位于 Canvas，具体 Lecture/Lab 暂标“未核对”，不虚构编号 |
| M6375-F19：MIT 6.375，Fall 2019 | [课程](https://csg.csail.mit.edu/6.375/6_375_2019_www/index.html)、[schedule](https://csg.csail.mit.edu/6.375/6_375_2019_www/schedule.html)、[handouts](https://csg.csail.mit.edu/6.375/6_375_2019_www/handouts.html) | 高级模块化、流水和设计空间探索的可选参考。BSV/Bluespec 与当前 SV 工具链不同；不引入第二 RTL 语言或完整 CPU/cache 项目 |

版本注意：B151 当前学期日历后半仍有空项，不根据未来课号填主题；旧 Berkeley 指定域/部分学期入口本次无法访问或跳登录。当前可读 lab 文本也不代表校内账户、仓库、PDK 和许可证可用。Cornell S02 页面日期为 2022-02-04，不能把被 2023 课程引用等同于文档更新于 2023。

EE141 配套 slides 页明确限制电子再发布；这里只链接并写自己的理解。课程实验适配 Genus/Innovus 与项目内已有工具，不照搬 Cornell 的 DC/VCS 路径，也不复制 Berkeley Hammer 学校环境。Cornell 教学 NanGate/FreePDK 与本项目 tutorial.lib 都不代表流片 PDK。

## 5. 课程 Mapping

关系标记：**P = Primary Reference**，本节点当前首选；**S = Secondary Reference**，用于第二视角；**O = Optional**，按工程需求选读；**Own = 本项目主导内容**，六门课只补公共方法。

P/S/O 是对具体节点的关系，不是课程总排名。可用“外部资源对应的方法”支持自己的案例，不把公开课没有的 SPI、ADC 校准或 AMS 内容归给它。

| 本项目阶段 / 讲义入口 | 节点 | 首选 P / Own | 第二参考 S / 可选 O | 回到自己的项目后留下什么 |
|---|---|---|---|---|
| [01 内基础练习](../course/01_sync_spi.md) | K01–02 | P：M6004 单元 2–5 | S：B151 L4–6；O：DIC2 Ch5–7 | enable/同步复位寄存器图、双寄存器更新预测；微实验待实现 |
| [01–06 SPI/RTL/TB](../course/01_sync_spi.md) | K02–03/05 | P：B151 L4–7、Lab 2 TB/RTL 方法 | S：M6004 单元 5–6 | A5/3C 台账、独立 stimulus、故障检测；复用 SPI 已有基线 |
| [07–08 单元/综合](../course/02_synth_sta.md) | K01/06 | P：B151 Lab 2；C5745 S01 的单元视图方法 | S：C5745 T12；O：DIC2 Ch6/11 | 39→37 存储位解释、mapped netlist 与后续 PPA 对照 |
| [09–10 STA/SDC](../course/02_synth_sta.md) | K07 | P：本项目接口预算＋C5745 Tutorial 4 中时序方法 | S：DIC2 Ch10；B151 实现报告；供应商命令文档按实际版本 | setup/hold 手算、约束来源表；补真实 min/hold 与场景证据 |
| [11–15 Slave/CDC/配置](../course/03_slave_cdc.md) | K03–04/08 | Own：SPI 停钟、mailbox、safe_update 与 epoch | S：B151 相关顺序/接口方法；专门 CDC 资料待核对 | 窄脉冲漏采反例、握手保持/复位矩阵；2FF 不能凭 RTL 仿真证明 MTBF |
| [16–18 集成/FIFO/APB](../course/04_integration.md) | K04/09 | P：B151 FPGA Lab 4 的 ready-valid/FIFO 方法 | S：C5745 模块接口；O：APB 官方规范另核对 | 接受/拒绝表、FIFO oracle、W1C 并发；APB 继续选修 |
| [19–21 floorplan/CTS/routing](../course/05_physical.md) | K07/10 | P：C5745 S02；B151 Lab 3 | S：DIC2 Ch4/9/10 | 物理输入审查；数据具备后保存分阶段 setup/hold、寄生和拥塞摘要 |
| [22 功耗/耦合](../course/05_physical.md) | K01/11 | P：DIC2 相关 CMOS/时钟章节；C5745 S02 能量方法 | S：B151 Lab 2 的 power-report 阅读 | idle/transfer/update 活动场景、活动标注率与功耗假设 |
| [23–24 配置项目](../course/06_capstone.md) | K03–08 | Own：配置控制器；P 方法：C5745 项目里程碑 | S：B151 模块验证流程 | 接口/独立 TB/约束/评审证据包；不改第一课 Master |
| [25–28 上电/故障](../mixed_signal/01_power_reset.md) | K03/08/13 | Own：数模接口与 MIN/ready/MAX | S：B151 FSM/验证方法 | 延迟/抖动/掉线/截止并发预测与恢复证据 |
| [29–32 采样/settling/吞吐](../mixed_signal/02_sampling.md) | K04/08/13/18 | Own：模拟窗口、测量身份和 quiet | S：B151 接口/FIFO 方法 | code_applied→settled→sample→response 台账，版本与丢弃计数 |
| [33–36 定点/平均/IIR](../mixed_signal/03_fixed_point.md) | K06/14 | Own：数值契约；P 方法：C5745 Lab 1 乘法器 | S：DIC2 Ch11；O：M6375 流水方法 | 精确整数 oracle、负 tie/饱和、吞吐/延迟/PPA 取舍 |
| [37–40 搜索/校准](../mixed_signal/04_calibration.md) | K03/13/15 | Own：可达/单调前提、确认与取消恢复 | S：公开课 FSM/验证方法 | 搜索轨迹、噪声/前提失效、trial/committed 分离 |
| [41–44 性质/模型/覆盖](../mixed_signal/05_verification.md) | K05 | P：B151 Lab 4；Own：模拟模型假设 | S：C5745 T08；O：S271 公开验证主题 | 从已有不变量升级到 monitor/SVA、覆盖闭环和可重放 seed |
| [45–46 活动/多电源](../mixed_signal/06_implementation.md) | K11 | Own：唤醒/模拟安全与 power intent | S：DIC2；B151/C5745 功耗方法 | 活动/电源状态表；UPF/ICG 实验按库与工具条件推进 |
| [47–48 DFT/交付](../mixed_signal/06_implementation.md) | K06–07/10–12 | Own：模拟输出的测试模式拥有权；P 方法：C5745 实现评估 | O：S271 DFT，DIC2 时钟/时序 | 模式表与交付矩阵；scan/ATPG、多角及物理检查分别留证 |
| [DF01–DF06](../delta_sigma_filter/00_course.md) | K16 | Own：PSD/alias/CIC/多级滤波 | O：未来 DSP 课程挂 K16，六门数字课不充当滤波理论首选 | PSD 校验、47k→1k 反例、系数与 alias/延迟预算 |
| [DF07–DF08](../delta_sigma_filter/07_fixed_point.md) | K02/06–09/14/16 | Own：bit-accurate/valid/相位；P 方法：B151/C5745 | O：M6375 调度/流水 | 四层模型、MAC deadline、标签/暖机与综合路径 |
| [AD01–AD05](../adc_digital/01_architectures.md) | K03/17 | Own：SAR/Flash/Pipeline/DEM | S：B151 FSM/组合/流水；DIC2 算术 | 复用 SAR/encoder/align/DWA 已有 RTL，增加自己的解释 |
| [AD06–AD08](../adc_digital/02_timing_data.md) | K08–09/18 | Own：采样身份/重排/复位 | S：B151 接口/FIFO；专门 CDC 资料待核对 | 独立台账、异步 FIFO 回归；补 Gray 物理约束证据 |
| [AD09–AD16](../adc_digital/03_interleaving.md) | K14–16/18 | Own：失配谱、可辨识性、前台估计/校正 | O：DIC2 算术、M6375 数据通路 | 单误差预测、估计残差、固定点 oracle；后台算法保持有条件扩展 |
| [AD17–AD20](../adc_digital/05_integration.md) | K04–08/11/18 | Own：原子系数与连续流；P 方法：B151/C5745 | S：B151 Lab 4 coverage/formal | 在途版本、计数守恒、连续流 FFT 与逐样本证据复用 |
| [TD01–TD04](../dac_digital/01_reconstruction.md) | K14/16 | Own：重构核/插值/DDS | O：未来 DSP 资料；DIC2 算术 | 直接/多相对照、码谱与模拟镜像分别解释 |
| [TD05–TD12](../dac_digital/00_course.md) | K04–09/14–18 | Own：预加载、门控、欠载、核失配 | S：B151 接口/验证；C5745 实现方法 | id/load/on/off 台账、整数 oracle、连续时间重构三层证据 |
| [AM01–AM06](../ams/00_course.md) | K13/15–19 | Own：Cadence AMS 与模拟模型/电路替换 | S：供应商版本对应资料；六门数字课只补 RTL/验证 | binding/桥/settling/事务/求解收敛；联验未运行继续明确标记 |

公共内容“一个概念解释、多处应用”：CDC 先回 11–15，定点回 33–35，PSD 回 DF01。专题只补自己的接口与非理想因素。FPGA ready-valid/FIFO 可阅读，但 FPGA BRAM、时钟资源与 ASIC SRAM/标准单元差异需明确。

## 6. 对比后的真实缺口与已有覆盖

下表是 **2026-10-07 接入前的审计基线**，区分内容缺口、深度缺口、实验/工具证据缺口。本次新增补充的状态见表后，不把“已有阅读/练习说明”写成“已有工具证据”。公开课并不包办工业签核；MMMC、CDC 物理约束、scan/ATPG 等不因出现在需求清单就自动归属 B151/C5745。

| 项目 | 当前审计结果 / 依据 | 差距与推荐动作 | 优先级 |
|---|---|---|---|
| lint | 未发现 lint 专节、规则集或 runner；已有编译/Genus 结构检查 | 内容＋工具缺口。补位宽/符号、未完整赋值、死代码等诊断与 waiver 依据，挂 K05；外部 lint 资料待核对，不冒称两门课已覆盖 | 近期 |
| constrained-random | 42–44 已有固定 seed、随机/边界方法；ADC 有随机向量 | 已覆盖思路；缺系统化 SV constraints/sequence/coverage closure。B151 Lab 4 方法→自己的 SPI/FIFO，完整 UVM 选做 | 近期 |
| assertions / SVA | 41 已有安全/活性不变量和程序 monitor；仅提到完整 SVA 支持限制 | 深度/实现缺口。补采样语义、$past/复位例外、assert/assume/cover、vacuity；先保留可运行 monitor，再加支持工具的 SVA | 近期 |
| formal / LEC | 文档提到二者、工具栈有候选；无 harness/proof/等价运行 | 实验缺口。B151 formal 可教性质证明；先 FIFO/控制器小性质，注明 assumptions、证明范围、反例、undetermined；LEC 单列后续任务 | 后续 |
| 功能/代码/断言覆盖 | 44 已区分功能/代码覆盖；已有显式事件矩阵 | 深度/工具缺口。补覆盖目标、缺口分析、无法到达与 waiver；B151 Lab 4 可作首选 | 近期 |
| synthesis optimization | 07–08 解释未使用存储位/常量/映射；DF08、AD15/19、48 涉及流水/复用 | 已覆盖，缺受控 baseline/alternative PPA 对比。用一个定点乘加通路，不再写泛泛“综合是什么” | 后续 |
| SDC / STA / setup / hold / uncertainty | 09–10 有公式、max/min、接口/例外；真实 scripts 有教学约束 | 不是缺课。缺已验证 hold 和更完整时钟/例外审计；ADC 现有流程明确 setup-only，不伪造 hold 通过 | 近期补设计；运行按条件 |
| MMMC | 19 输入表提到 MMMC，48 要求多角/模式；没有具体场景矩阵/Tcl | 深度＋实验缺口。先写 functional/test、min/max、库/RC/clock/exception 场景表，再核对实际工具 | 后续 |
| floorplan / placement / CTS / routing / post-layout STA | 19–21 已有步骤、公式、skew、RC/修复、propagated clock | 理论已覆盖，缺配套数据和实跑。对应 C5745 S02 / B151 Lab 3，建独立物理实验，不能拿 tutorial.lib 拼出物理 PASS | 数据就绪后 |
| power analysis | 22/45/AD20 有 αCV²f、代表活动及模拟耦合 | 已有理论，缺活动注入、标注率、模型/场景与工具报告。先 idle/transfer/update 三场景 | 数据/工具就绪后 |
| DFT / scan | 47 有 scan/ATPG、测试时钟及模拟安全拥有权 | 不是完全缺失；缺故障模型深度、插链、shift/capture 和覆盖报告。S271 主题作选读，细化资料另核对 | 后续选修 |
| memories / SRAM | 17/AD08 有 FIFO，DF08 有历史存储；未发现 SRAM 专门课程/宏视图实验 | 明显内容缺口。补 RAM read-during-write、同步读延迟、宏模型/Liberty/LEF 与 FIFO 寄存器实现差异；B151 Lab 3、C5745 S05 | 后续，贴合滤波/样本缓冲 |
| physical verification / IO | 只有工具栈提及 DRC/LVS/PDK；未见专门教学和具体实验 | 明显内容缺口。补 P&R DRV、DRC、LVS、黑盒/waiver、IO/供电边界；B151 Lab 4 signoff 作阅读首选，实际检查用已有授权流程 | 理论后续；运行按数据 |
| 工业 CDC / MTBF / Gray bus 约束 | 11–15 和 AD08 已详述协议/亚稳态/恢复，progress 明确物理项未验证 | 保留已有课程，补结构分析、同步器解析时间、bus skew/max delay 的实际审查；需要专门 CDC 一手资料 | 后续，接口出现时 |

相较两门公开课最明显的差异是：**验证由“检查通过”到“覆盖闭环/性质证明”仍欠方法和工具实践；存储宏、物理验证/IO 的系统教学较薄；ASIC 从逻辑综合到真实物理评估尚未跑通。** 后者主要是数据与环境条件，不能全算课程内容遗漏。

本次已补教学入口，工具与实跑缺口继续保留：

| 节点 | 本次补充 | 当前层次 / 下一步 |
|---|---|---|
| K05 | [lint/SVA/随机/覆盖/小形式任务](../practice/verification.md)，含已核对 Verilator 官方资料 | 有练习设计与 SVA 教学片段；lint/断言编译/覆盖/formal 待执行 |
| K06/K07 | [受控 PPA、min/hold 与 MMMC](../practice/timing_and_ppa.md) | 有比较契约、手算与场景设计；无新增 hold/多角结果 |
| K09 | [RAM/SRAM](../practice/memory.md) | 有同步读/碰撞/初始化契约与宏视图清单；模型/宏集成待实现 |
| K10/K12 | [物理检查/IO/DFT](../practice/physical.md) | 有 DRC/LVS/blackbox/waiver/故障模型与模式分析；P&R/物理检查/ATPG 未运行 |

## 7. 保留 / 修改 / 新增 / 暂不加入

| 分类 | 建议 | 理由 |
|---|---|---|
| 保留 | 01–48、DF/AD/TD/AM 编号，六方向结构与 SPI 第一课契约 | 现有顺序、接口和交叉引用已经完整，不重新编号 |
| 保留 | 讲义/答案/workbook/项目规格、progress/history/running 的职责 | 已区分个人掌握、工具证据、运行操作，避免三份进度表 |
| 保留 | ΔΣ 优先、控制项目主导、TI/DEM/AMS 的数模特色 | CPU/FPGA 课程只供方法，不改变最终方向 |
| 修改 | roadmap 增加按问题查 K 节点的阅读方式；README 增一个简洁入口 | 让外部资料进入现有路线，导航不变成收藏夹 |
| 修改 | 06/41–44 的验证与 19–22/48 的实现，在后续小 diff 中补缺口 | 每次针对一个节点和实验，不重写全部讲义 |
| 新增 | 中心 mapping、六个资源页、轻量 learning_log | 索引、来源和学习过程分工明确 |
| 新增 | lint、SVA/coverage、SRAM、physical verification 的项目化补充 | 针对已确认缺口，独立知识补充页先按需建，不预建大目录 |
| 暂不加入 | 全套 CPU/RISC-V/cache、完整 FPGA 学期作业、BSV 工具链 | 当前目标是 Mixed-Signal / Digitally Assisted Analog |
| 暂不加入 | 强制 UVM、全面后台校准、完整工业签核、自动抓取全部 slides/video | 按需求增加工具深度；不制造高维护成本或超出证据的结果 |
| 暂不加入 | 为每个公开课建课号树、空 lecture 日志、第二套完成状态 | 新资料只挂知识节点；实际学过一次再建日志 |

## 8. 推荐目录与信息归属

以下入口已经建立，学习日志的年份/实例目录只在实际学习时创建：

```text
docs/
├── roadmap.md                    # 个人顺序/前置/项目门槛
├── course/ mixed_signal/ ...      # 六套原课程保留
├── references/
│   ├── course_mapping.md          # K 节点 + 课程/资源/实验关系，中心索引
│   ├── README.md                  # 资源使用原则、版本/状态说明
│   ├── berkeley_eecs151.md
│   ├── cornell_ece5745.md
│   ├── mit_6004.md
│   ├── berkeley_ee141.md
│   ├── stanford_ee271.md
│   └── mit_6375.md
├── practice/                     # 按工程问题补强，不增加课号
│   ├── verification.md           # K05
│   ├── timing_and_ppa.md         # K06/K07
│   ├── memory.md                 # K09
│   └── physical.md               # K10/K12
└── learning_log/
    ├── README.md                  # 按节点索引实际日志，链接原 workbook
    ├── _template.md
    └── 2026/
        └── 2026-10-xx_K02_spi-registers.md  # 未来记录命名示例，不预建
```

本轮不新增 lessons 实现目录；后续实验按项目契约另建，源/TB/约束/脚本可入 Git，波形/报告/工具/PDK 继续留 results/.tools。教材和视频将来可以共用资源页字段，不要求目录永远只含大学公开课。

六个资源页只维护：资源 ID、名称/机构/作者、学期/版本、官方/具体入口、主题、推荐顺序、为什么值得学、对应 K 节点、相关实验、前置/工具依赖、访问状态和核对日期。其“学习进度”只链接日志和原 workbook，不手填第二份完成率。

Mapping 是关系唯一维护位置：资源页可链接中心表并说明课程特有取舍，不再复制整张映射。每课先选一个 P，出现理解差异再读 S；O 不占必修预算。允许一个节点的不同子问题分别指定 P，如单元视图与综合流程。

已有网站 [内容索引](../../web/src/lib/catalog.ts) 递归读取 `docs/**/*.md`，通用阅读路由能展示新增参考文档；不用新建第七课程或改变 94 个 lesson ID。本地已验证入口、搜索和新增页面的桌面/手机阅读；多列表格保留可读列宽并局部横向滚动。网站笔记目前只覆盖 lesson ID、存在浏览器 localStorage；不会自动生成 Git learning_log，导出内容也需本人审核后整理。

参考页与补充已在 docs 扫描范围内，下次网站构建会读到它们。本站不新增课程分类或个人进度字段；本轮只做本地验证，不部署网站。

## 9. Learning Log：记录理解变化，不抄课程

复用各 workbook 已有的预测/命令/退出码/证据字段，新增来源和节点关联。workbook 保持课号验收权威；learning_log 保存一次实际学习过程；progress 维护工程执行状态；history 保留历史。学习日志关联多个课号时只写一次正文。

```markdown
# 日期 + Kxx + 本次工程问题

- 状态：计划 / 已阅读 / 已实验 / 已解释（由本人填写）
- Source：资源 ID、学期/版本、Lecture/Lab/章节标题、原链接
- Connection：K 节点、课号、当前项目/实验 ID

## Prediction
运行前写出波形/数值/单元/时序变化及其适用假设。

## Experiment
独立参考、刺激/错误注入、代码版本、未提交差异、工具版本、参数/seed、命令。

## Evidence
退出码、完成标记、用例/覆盖统计；产物路径与 SHA-256；失败及恢复。
注明解析/数值模型/RTL/综合/物理/AMS 哪一层。

## Conclusion
预测与观察哪里不同？这段 RTL 对应什么电路？
能证明什么，尚需什么模拟/工艺/接口证据？

## Questions / Next Step
尚未解决的问题，以及下一项可验证的小动作。
```

未运行时 Evidence 写“未运行”，不得填预期数字当实测。不提前生成 lec01…lecN 空日志，也不代替本人填写 What I Learned。没有完整工具环境时，可留下手算或分析产物，但不升级为已执行的综合/AMS/物理验收。

状态分列，不合并成一个完成勾：`resource_checked`（来源可读/未核对/登录）、`learning`（本人状态）、`experiment`（计划/已实现/未运行/失败/通过＋验证层次）。本次没有代填个人完成状态；实际条目使用 [日志模板](../learning_log/_template.md)。

## 10. 公开资料→自己实验→最终能力

实验 ID 独立于外部课程，换资料不会改变实验身份。以下是候选绑定，路径为现有源码的才视为实现；其余是设计任务。

| 实验 ID / 节点 | 外部触发 | 自己的实验与预测 | artefact / 能力 | 状态 |
|---|---|---|---|---|
| EXP-SPI-BASE / K02–03/05–07 | M6004 顺序；B151 TB/综合 | 预测 A5/3C 与寄存器更新；解释映射位数和 setup | [SPI RTL/TB/SDC](../../lessons/01_spi_master/rtl/spi_master.sv)、已有波形/网表/报告位置及自己的解释 | 实现/既有证据；个人验收待填 |
| EXP-RTL-LINT / K02/05 | [Verilator 官方 lint 资料与练习](../practice/verification.md) | 在独立副本注入 signed/width/latch 问题，预测诊断与硬件影响 | lint 规则/diagnostic/waiver、修复前后对照 | 计划，不动基线；安装版本待核对 |
| EXP-VERIFY-CONTRACT / K05 | B151 Lab 4 | 为 SPI busy/done 或 FIFO 守恒补 monitor/SVA、约束随机与覆盖；注入能违反性质的错误 | 源/seed/反例/覆盖闭环；具备工具时再记录 proof | 计划 |
| EXP-CDC-PULSE / K08 | 专门 CDC 资料待核对，复用 11–15 | 10ns 脉冲在 20ns 目的时钟下扫相位；比较直接、2FF、toggle/握手 | 漏事件与正确传输台账；解释协议边界 | 计划；不以仿真观察亚稳态概率 |
| EXP-FIXED-PPA / K06/14 | C5745 Lab 1 的流水/评估方法 | 复用 [adc_fixed_correct](../../lessons/adc_digital/rtl/adc_fixed_correct.sv)，预测流水/资源复用改变延迟与面积 | bit-accurate 回归、latency/throughput、映射/路径对照 | 基线已有；比较实验待做 |
| EXP-SDC-HOLD / K07 | C5745 工具方法＋实际供应商文档 | 固定接口预算，分别改变 min/max/uncertainty；先手算再审查 | constraint/scenario 表、合法工具的 setup/hold 报告 | 计划；既有 max 报告不作 min 结果 |
| EXP-SRAM-BUFFER / K09 | B151 Lab 3；C5745 S05 | 比较寄存器 FIFO 与同步 RAM/宏；预测读延迟/同址读写/端口冲突 | RAM 契约、模型/RTL 对照、库视图清单 | 计划 |
| EXP-ASIC-IMPLEMENT / K07/10–11 | C5745 S02；B151 Lab 3/4 | 选一个小控制模块，数据核对后走 synth→floorplan→place→CTS→route→提取/STA；独立 DRC/LVS | 阶段报告、活动/功耗、物理检查摘要；完整条件清单 | 配套数据/工具待核对 |
| EXP-DF-CHAIN / K14/16 | 本项目 DF 主导，数字课补调度/实现 | float→量化系数→整数→RTL；预测 CIC wrap、alias、相位与 MAC deadline | 系数 manifest、逐样本与频谱证据、综合解释 | 计划；已有算例不是完整实现 |
| EXP-TI-CAL / K15/18 | 本项目 AD 主导 | 复用标签/重排/offset-gain；新资料只补所遇方法问题 | [AD 实验索引](../adc_digital/09_labs.md)的连续流/数值/版本证据 | 已有教学模型/RTL/setup，真实时钟另验 |
| EXP-AM-SETTLE / K13/19 | 本项目 AM＋Cadence 版本对应文档 | 预测 RC/量化、sample 与 response；逐块替换视图 | binding 表、混合波形、求解收敛与测量台账 | 计划；AMS 环境尚未跑通 |

实际 run_id、源 hash、库/场景、完成标记和产物 hash 留在日志/manifest；中心 mapping 只维护关系与当前能力层次。报告正文、波形和专有数据不提交 Git。

## 11. 落地状态与后续维护

2026-10-07 经用户确认后接入第一批：README/roadmap 的短入口、六个版本化资源页、按节点记录的日志说明与模板，以及 AGENTS 的维护规则。K05、K06/K07、K09、K10/K12 已增加项目化补充，并从原讲义反向连接。保留所有课程编号与已有未提交工作，不更改 RTL/TB/模型/SDC/runner。

每次补强仍按单节点、小实验推进：先 K02/SPI 的个人预测与解释；需要工具深度时做 K05 的 lint/故障检测，再做 K06/07 的架构/min/hold 比较。SRAM 与物理实验先按清单审查数据，齐备后实现。DF/AD/TD/AM 继续由自己的契约主导。

新增资源的维护动作：核对官方具体入口与版本 → 判断已有节点是否能表达问题 → 选择 P/S/O 或保持 Own → 绑定一个已有/计划实验 → 实际学习时建立日志 → 回原 workbook 验收。无工程用途的链接暂不纳入；新资源不带来新课程树。

文档改动运行 `python tools/check_docs.py` 与 `git diff --check`。网站自动读取 docs，本地验证构建与站内链接/锚点；发布是另一个动作。本次真实检查记录见 [progress](../progress.md)，不在 mapping 复制测试统计或实验完成率。

维持以下不变量：94 个课号有映射；首选资源有来源/版本与取舍；内容、实现、工程证据和个人掌握分别登记；六条数模方向不被公开课取代；新教材或视频优先挂已有节点。
