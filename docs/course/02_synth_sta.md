# 阶段二：综合与时序（07–10）

前提：通过阶段一。工程参考：[实际报告解读](../02_read_first_reports.md)、[SDC](../../lessons/01_spi_master/constraints/spi_master.sdc)、[Genus Tcl](../../lessons/01_spi_master/synth/run_genus.tcl)。本阶段从功能正确走向“在指定模型和边界条件下，电路是否能按时工作”。

## 07：Liberty 如何连接电路与数字工具

### 目标和讲解

SPICE 模型描述器件；标准单元 Liberty 描述已经设计好的门和触发器的逻辑、面积、时序弧与其他特性。工具用这些抽象选择实现和计算路径，而不是每次综合都跑晶体管级仿真。

| 模型信息 | 电路含义 | 工具用途 |
|---|---|---|
| function | 输入输出逻辑关系 | 映射与逻辑判断 |
| combinational timing arc | 输入变化到输出变化的延迟 | 传播 arrival time |
| clock-to-Q arc | 时钟边沿到 Q 响应 | 数据发射时刻 |
| setup/hold constraint | D 相对 CK 的稳定窗口 | 捕获合法性 |
| input capacitance | 输入引脚负载 | 前级门延迟 |
| output transition | 输出斜率 | 下一级时序查表 |
| operating condition | 电压、温度、工艺模型 | 对应分析角 |
| internal/leakage power | 单元内部与静态功耗模型 | 功耗估算 |

同一个 NAND2 的延迟不是常数，通常依赖输入 slew、输出负载、输入相关时序弧和上升/下降方向。互连 RC 会进一步改变延迟与波形。不同 PVT 库用于不同条件；不能把“慢角/快角”简单固定成任意温度组合，温度反转等效应需看具体库。

驱动更大的单元常可减小本级输出延迟，但增加前级负载、面积和动态功耗，未必改善整条路径。多级缓冲器和逻辑重构也可能更合适。

### 07 参考与实验

- **选读与定位**：K01/K06 · P 首选：[Cornell ECE5745 S01：ASIC Flow Front-End](https://cornell-ece5745.github.io/ece5745-S01-front-end/)。来源/边界：[C5745-S23 / S01-2023](../references/cornell_ece5745.md)。
- **带着问题读**：只读 Standard-Cell Libraries / 逻辑、时序和物理视图；同一个 NAND 为什么需要多种视图？
- **回到本课做**：EXP-SPI-BASE：对自己的 tutorial.lib 只记录单位/角/弧与负载解释，不复制库；连接本课 MOS/Liberty/LEF 区别。
- **留下证据**：单元视图用途表和 slew/load/PVT 假设卡。将预测、实际观察和结论写入 [本方向学习表](08_workbook.md)；公开资料引起的理解变化用 [学习日志模板](../learning_log/_template.md) 记录。

### 练习与验收

解释“输出负载增加 → 延迟与 slew 变化 → 下一级延迟也变化”的链条。到服务器只读查阅教学库的单位和角定义，记录属性名称与数值，不复制库正文到 Git。验收要求说明 MOS 模型、Liberty、LEF 三者不能互相替代。

## 08：从 RTL 到映射网表

### 目标和讲解

`read_hdl` 读取描述；`elaborate` 展开参数、连接和层次；综合把行为变成逻辑网络；映射将网络实现为库单元；优化在约束下调整结构。

当前 RTL 声明存储位：8+8+8+5+3+2+5=39。网表有 37 个触发器，因为 tx_shift[7] 的保存值从未参与后续输出，rx_shift[7] 的保存值也从未被读取。首个 MOSI 来自 tx_data[7]，最终接收结果由旧 rx_shift[6:0] 和当前 miso 形成。

这是可观察行为优化：不是“综合漏了两位”，也不是“RTL 声明多少变量就一定需要多少硬件”。状态编码、常量传播、未使用逻辑和公共逻辑都会改变实际数量。

现有映射结果：37 fflopd、56 inv1、171 nand2、13 nor2，共 277 单元。MUX 和加法比较逻辑可以分解为基础门，因此没有名为 MUX 的单元不代表没有选择功能。教学库面积 440.500 只用于比较当前模型内的实现。

### 08 参考与实验

- **选读与定位**：K06 · P 首选：[EECS151 ASIC Lab 2：Synthesis](https://eecs151.org/asic/lab2/docs/pg6-synthesis-intro/)。来源/边界：[B151-F26](../references/berkeley_eecs151.md)。
- **带着问题读**：只读 RTL→technology mapping 和报告用途；脚本依赖保持本项目 Genus 环境。
- **回到本课做**：EXP-SPI-BASE：追踪 div_count 的 Q→逻辑→D，解释 39 个声明存储位到 37 个映射 FF 的裁剪。
- **留下证据**：网表路径草图、单元分类和裁剪依据；不要求新版本始终等于 37。将预测、实际观察和结论写入 [本方向学习表](08_workbook.md)；公开资料引起的理解变化用 [学习日志模板](../learning_log/_template.md) 记录。

### 练习与验收

沿 `div_count_reg[4]` 的 Q→组合逻辑→D 查一条反馈路径，再查 sclk_reg 的 CK 确实连接 clk。检查设计报告无 unresolved、undriven、multidriven；检查 timing intent；核对网表实例与 gates.rpt。

若以后改变 RTL，数量可以变化；判断标准是解释实现而不是机械要求一直等于 37。当前基线的 37 是已验证的参考值。验收要求用代码用途解释两位优化，不能仅引用工具数字。

## 09：分别计算 setup 和 hold

### 目标和讲解

先考虑寄存器到寄存器路径，定义 skew=`t_capture_clock−t_launch_clock`。接收时钟较晚到达，skew 为正。

在简化同频模型中，忽略其他修正项：

```text
setup slack ≈ T + skew − uncertainty_setup
              − t_cq,max − t_data,max − t_setup

hold slack  ≈ t_cq,min + t_data,min
              − skew − uncertainty_hold − t_hold
```

setup 检查下一次捕获前能否到达；hold 检查本次捕获后是否太早变化。正 skew 通常帮 setup、伤 hold。降低频率通常增加 setup 预算，却不会直接解决同一捕获沿的 hold。

数字例子：T=2 ns，skew=0.1 ns，setup uncertainty=0.1 ns，t_cq,max=0.15 ns，t_data,max=1.6 ns，setup=0.15 ns，则 setup slack=0.10 ns。若 t_cq,min=0.05 ns，t_data,min=0.08 ns，hold=0.05 ns，hold uncertainty=0.02 ns，则 hold slack=−0.04 ns。一个路径可以 setup 通过而 hold 失败。

现有最差报告是输入到寄存器路径，不套用发射 DFF 的 t_cq：20−0.1 setup−0.2 uncertainty−5 input delay−0.461 内部路径=14.239 ns。Genus 本次报告显示 ps：14239 ps=14.239 ns。

通过报告时要依次确认起点、终点、捕获沿、路径类型、单位、约束、cell/net delay、arrival、required、slack。current timing.rpt 是 max/setup 报告；本项目没有已验证的 min/hold 报告，不据此宣称 hold 通过。

### 09 参考与实验

- **选读与定位**：K07 · S 第二视角：[Rabaey DIC 第 2 版章节索引](https://icbook.eecs.berkeley.edu/resources/powerpoint-slides)。来源/边界：[RABAEY-DIC2](../references/berkeley_ee141.md)。
- **带着问题读**：按章节索引选 Ch7 Sequential 与 Ch10 Timing，只补电路时序视角；公式与符号以本课定义为准。
- **回到本课做**：EXP-SDC-HOLD：先手算正 skew 对 setup/hold 的相反影响，再审查已有 setup 报告和未获得的 min/hold。
- **留下证据**：两条到达/要求时间线与 max/min 证据分栏。将预测、实际观察和结论写入 [本方向学习表](08_workbook.md)；公开资料引起的理解变化用 [学习日志模板](../learning_log/_template.md) 记录。

### 练习与验收

手算上述两类 slack。然后保持教学输入预算不变，把周期假想改为 5 ns，估计同一路径 slack，并解释为什么“组合逻辑只有 0.461 ns”仍不足以满足预算。此处是固定路径估算，真实重综合后的路径与延迟可能变化。

## 10：约束是边界条件，不是消除红字的按钮

### 目标和讲解

`create_clock` 给出周期；input delay 表示外部数据相对参考时钟的到达预算；output delay 表示外部接收需要留出的预算；input transition 和 output load 描述驱动与负载；uncertainty 表示模型中保留的时钟裕量。

max/min 分别服务于最晚与最早到达分析。时钟 transition 是 CK 引脚的斜率模型，uncertainty 是时间预算，两者不能混用。

教学 SDC 在 sys_clk 下为 MISO 提供 5 ns 最大输入预算，不完整描述真实的外部 SPI 往返路径。真实 Master 内部采样动作由 clk 边沿产生，而外部从设备看到的是经过 t_cq、输出缓冲和板级传播后的 SCLK。

从上一个 SCLK 下降事件到下一内部 MISO 采样事件，可先写概念性 setup 预算：

```text
半周期预算 H ≥ SCLK 输出传播 + 去程互连
               + 从设备最大 clock-to-output + 回程互连
               + MISO 输入到采样 D 端延迟 + 接收 setup
               + 相对时钟/建模裕量
```

例子：H=500 ns，各项依次为 2、3、40、3、1、0.1、5 ns，余量为 445.9 ns。这只是给定数字的计算题，不是任何实际器件的保证。若 D=1，H=20 ns，同一组假设已无法满足。首位还要单独预算 CS 到从设备数据有效；hold 要用最小延迟和数据最早变化时刻另算。

为外部源同步接口选择 generated/virtual clock、定义波形与采样沿，需要与实际的内部捕获结构一致。不能仅在 SCLK 端口创建一个时钟，就以为系统时钟捕获的 MISO 已正确建模。

多周期路径用于功能上确实允许较晚捕获的路径；false path 用于确实不参与相应同步检查的路径。异常要有结构、协议和验证依据，并检查 max/min 关系。多周期 setup 异常往往还需相应 hold 处理，但具体数值依赖参考边沿与工具语义，不能照搬口诀。

### 10 参考与实验

- **选读与定位**：K07 · P 流程方法：[Cornell ECE5745 Tutorial 4：ASIC Tools](https://cornell-ece5745.github.io/ece5745-tut4-asic-tools/)。来源/边界：[C5745-S23](../references/cornell_ece5745.md)。
- **带着问题读**：选约束与 timing report 的相关段落；公开工具例子不是本项目 SPI 板级预算。
- **回到本课做**：EXP-SDC-HOLD：给每条 input/output delay、load、uncertainty 写来源；再按 K07 补充设计一个 min 场景。
- **留下证据**：SDC 逐行假设表、器件/互连预算与例外依据。将预测、实际观察和结论写入 [本方向学习表](08_workbook.md)；公开资料引起的理解变化用 [学习日志模板](../learning_log/_template.md) 记录。

### 练习与验收

逐行写出当前 SDC 的物理假设。为一个假想从设备列出 t_CO,max/min、CS 首位延迟、MOSI setup/hold、SCLK 高低宽度、CS setup/hold、板级往返延迟。验收要求能解释 timing intent=0 仅代表当前检查没有发现约束问题，不能证明预算来自真实系统。

## 阶段验收

解释 37 个触发器与 277 单元；手算 setup 与 hold 并正确判断偏斜方向；列出教学约束与实际器件接口之间的缺口。答案见 [07–10 参考](07_answers.md)。

## 时序与架构比较的按需补强

基础公式与 SDC 不重复建设。需要 min/hold 场景或定点通路比较时，使用 [K06/K07 补充](../practice/timing_and_ppa.md)：固定协议/库/约束，先预测，再审查比较条件与 MMMC 场景。现有教学 setup 结果不扩展为 hold/多角 PASS。
