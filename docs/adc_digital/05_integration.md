# 配置、验证和实现（AD17–AD20）

## AD17：原子系数、版本与诊断

### 讲解

四lane的offset/gain是一组配置。SPI写shadow，检查范围后提交pending，在下一帧采样边界n mod4=0一次切换active，并分配版本号。不能四个lane在不同帧使用半套新系数。

本项目采样时把该lane的实际系数值及version复制到样本槽；转换返回和校正使用该副本。仅存bank号却立即覆写旧bank，会让在途样本错误使用新值。其他实现可采用引用计数或足够的bank保留，但都需要生命周期证明。

定义同拍commit/采样的优先级：已在该边沿之前登记的pending参与新帧；边沿当拍刚到的commit只进入pending，下一帧应用。结果带sample_id、epoch、version和错误状态。校准统计读回用冻结快照，避免软件读到跨版本的一半。

### AD17 参考与实验

- **选读与定位**：K04/K18 · Own 版本契约；S 接口方法：[EECS151 FPGA Lab 4：Ready-Valid Interfaces](https://eecs151.org/fpga/lab4/docs/pg3-readyvalid/)。来源/边界：[B151-F26](../references/berkeley_eecs151.md)。
- **带着问题读**：只借 transaction acceptance；active coeff 改变不能让在途样本使用错版本。
- **回到本课做**：EXP-TI-CAL：转换尚未返回就 commit，先预测每个 id 的版本，检查重复/非法提交的拒绝政策。
- **留下证据**：生效 sample_id、旧版本保留与 in-flight/commit 台账。将预测、实际观察和结论写入 [本方向学习表](08_workbook.md)；公开资料引起的理解变化用 [学习日志模板](../learning_log/_template.md) 记录。

### 练习与验收

转换尚未结束时切换系数，预测每个样本的版本；测试重复commit、非法范围和多lane响应。验收要求原子性、旧样本系数保留、明确拒绝/覆盖政策，以及可追溯的生效样本编号。

## AD18：独立模型、FFT 和覆盖

### 讲解

参考模型按采样时间生成数值，响应调度器独立生成转换延迟；golden台账按sample_id而非DUT输出顺序记账。否则DUT重排错误可能被同样错误的参考“验证”通过。

模型开关分别注入offset、gain、skew、jitter、带宽、噪声、量化、clipping；协议开关注入迟到、重复、错标签、复位旧响应和消费停顿。模型参数、随机seed、代码/系数版本和FFT口径必须随报告保存。

复用DF01的PSD/窗口/FS规则：先用相干理想单音确认bin和幅度，再评估校准前后。输出signed18/F4需除16才回到ADC LSB；标签顺序、饱和、缺样和启动区检查通过后，才把频谱用于模拟误差分析。

### AD18 参考与实验

- **选读与定位**：K05/K15/K18 · P 覆盖方法；Own 频谱：[EECS151 ASIC Lab 4：Coverage](https://eecs151.org/asic/lab4/docs/pg1-coverage/)。来源/边界：[B151-F26](../references/berkeley_eecs151.md)。
- **带着问题读**：用场景与交叉覆盖组织失配×频率×幅度×版本×故障；FFT 的单位和预测仍用本课。
- **回到本课做**：EXP-TI-CAL：先查逐样本/身份正确，再对预测频点和指标预算，补最差场景而非选最好图。
- **留下证据**：覆盖缺口闭环、逐样本 oracle 与 FFT 口径卡。将预测、实际观察和结论写入 [本方向学习表](08_workbook.md)；公开资料引起的理解变化用 [学习日志模板](../learning_log/_template.md) 记录。

### 练习与验收

创建“误差×输入频率×幅度×系数版本×故障”矩阵；预测offset/gain/skew频点。验收要同时有逐样本正确性和指标预算，不能只挑校正后最好的一张FFT。

## AD19：RTL、综合与 STA

### 讲解

先实现scheduler/tag/reorder，再接定点校正和系数控制，分别验证后集成。已有源码位于独立 `lessons/adc_digital/`，自己的运行脚本与完成标记均已接入；逐课代码和实际结果见 [实验指南](09_labs.md)。

回归须覆盖12bit完整数值边界与随机范围，不能套用SPI的8bit覆盖结论。关键项是simultaneous response、槽环绕、duplicate/missing、deadline、reset、版本切换、负数舍入、饱和和计数守恒。错误测试期望明确fault，不能把“仿真没崩溃”算PASS。

Genus查exit code、完成标记、unmapped、check_design、timing intent、综合网表寄存器/算术结构及关键路径。100MHz core周期10ns，乘法/加法/重排选择的逻辑深度、负载、setup和clock uncertainty共同决定裕量。P级流水改变输出延迟，需更新规格和参考。

在教学单core模型中，模拟skew不是RTL的input delay。真实源同步ADC接口须提供clock、input delay、jitter/uncertainty、CDC及异常路径依据；异步路径例外不等于接口被验证。教程Liberty结果只用于逻辑教学。

### AD19 参考与实验

- **选读与定位**：K06/K07 · P 首选：[Cornell ECE5745 Tutorial 4：ASIC Tools](https://cornell-ece5745.github.io/ece5745-tut4-asic-tools/)。来源/边界：[C5745-S23](../references/cornell_ece5745.md)。
- **带着问题读**：选综合与 timing 报告的评价方法；已有 ADC flow 是 setup-only，hold/多角另设计。
- **回到本课做**：EXP-FIXED-PPA / EXP-SDC-HOLD：识别实际乘法/mux 路径，预测一个流水改动，保持库/SDC 后比较。
- **留下证据**：映射结构、同条件关键路径与 max/min/物理未执行项。将预测、实际观察和结论写入 [本方向学习表](08_workbook.md)；公开资料引起的理解变化用 [学习日志模板](../learning_log/_template.md) 记录。

### 练习与验收

阅读映射后的乘法器、寄存器、mux和buffer，判断最慢路径；修改一个流水位置后仅在有实际结果时比较。验收包含回归与综合的独立证据，明确未做形式等价、门级、物理或多角签核。

## AD20：功耗、模拟影响与交付

### 讲解

动态功耗近似αCV²f，但数字切换还通过供电、衬底和时钟耦合影响ADC。校准乘法器/总线的活动模式、模块位置、返回电流和去耦可能让数字功能正确而模拟性能下降。

lane并行处理能降低单路速率，但增加面积、布线和跨域负担；clock gating需无毛刺单元和恢复协议。真实高速系统通常保持并行输出或低速聚合，不能假定单串行总流寄存器在任意Fs都可行。

SPI适合配置/状态/少量快照。4M×18bit=72Mbit/s，仅有效负载就远大于1MHz SPI；持续数据输出要单独选择并行/源同步/串行链路并计入编码与协议开销。

### AD20 参考与实验

- **选读与定位**：K11/K18 · Own 数模交付；S 后端评价：[Cornell ECE5745 S02：ASIC Flow Back-End](https://cornell-ece5745.github.io/ece5745-S02-back-end/)。来源/边界：[C5745-S23 / S02-2022](../references/cornell_ece5745.md)。
- **带着问题读**：借能量与实现评价的条件记录；真实采样 jitter、settling 和噪声仍须模拟证据。
- **回到本课做**：AD 交付练习：idle/acquire/continuous/update 分活动场景，把数字顺序/版本与模拟时钟/负载责任分开。
- **留下证据**：架构/clock/reset/位宽/预算/活动/覆盖与分层交付矩阵。将预测、实际观察和结论写入 [本方向学习表](08_workbook.md)；公开资料引起的理解变化用 [学习日志模板](../learning_log/_template.md) 记录。

### 练习与验收

提交架构图、clock/reset表、接口假设、位宽/延迟表、失配预算、覆盖和失败记录、综合/时序解释及未完成列表。模拟团队确认采样时钟/settling/负载/噪声证据；数字团队确认顺序/数值/版本/吞吐。每项标明模型推演、RTL实测或真实电路证据。

首版已交付讲义、练习、答案、项目规格及可运行模型/RTL，真实工具PASS见 [进度记录](../progress.md)。个人记录表继续由学习者填写，不以自动化工具通过代替掌握。
