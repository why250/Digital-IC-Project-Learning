# 四通道 TI-ADC 数字后端：结课项目规格

状态：教学规格已有 [模型/RTL与回归实现](09_labs.md)，实际工具证据见 [进度记录](../progress.md)。真实ADC参数填写在 [记录表](08_workbook.md) 后另行修订。本项目独立于第一课SPI，不改变其50MHz契约。

## 1. 固定参数与里程碑

| 项目 | 首版定义 |
|---|---|
| 通道 | M=4，lane顺序0、1、2、3 |
| 总/lane采样率 | 4M / 1M samples/s |
| 教学core | 100MHz，10ns周期，所有首版寄存器用core |
| 原始码 | signed12/F0，−2048…2047，ADC LSB为单位 |
| 样本间隔 | 25core周期，同lane100周期 |
| 转换延迟 | 示例[18,52,9,31]core周期；合法响应1…60周期 |
| 重排槽 | 8个，每槽独立payload/valid/full tag |
| 重排释放 | 采样后80core周期，不按返回顺序 |
| 校正 | 固定/可原子更新offset与inverse_gain；signed18/F4输出 |
| 校正流水 | 首版固定P=4，回归逐样本核验输出边沿 |
| 连续输出 | 每25core周期一次push，不接受无限背压 |

A1：SAR/Flash/Pipeline/DEM推演；A2：四lane采样台账和重排模型/RTL；A3：前台DC系数估计与定点校正；A4：skew/带宽模型及集成证据。首版timing校正不要求RTL，后续明确带宽与延迟后另建实验。

## 2. 样本身份、接口与时序

复位释放后第一个运行边沿作为tick=0：采样n在tick=25n请求，lane=n mod4。首版lane模型与core同步，sample_req为单周期；接受时保留sample_id、epoch、lane和系数版本。以此边沿代表模拟采样/保持事件，仅是功能模型定义。

建议端口分层：

- scheduler输出：`sample_req[3:0]`、`sample_id`、`epoch`；正常one-hot。
- lane返回：四组独立 `rsp_valid/raw/sample_id/epoch`，lane由端口索引识别。
- reorder输出：每份raw及其标签、捕获的offset/inverse_gain/version。
- correction输出：`out_valid/data/sample_id/epoch/lane/coeff_version/sat`。
- control输出/状态：配置接受/拒绝、applied_sample_id、sticky_fault和冻结快照。

示例n=0在18返回；n=1在77；n=2在59；n=3在106。释放仍在80、105、130、155，输出寄存器在80+P、105+P、130+P、155+P边沿之后更新，下游在下一边沿接受。比较台账时区分返回、重排与下游接受。每lane相邻请求100周期，合法转换≤60，每lane最多一份未完成转换；迟到不获得此保证。

sample_id首版32bit。4M/s下约1073.74s回绕；不允许静默回绕。用64bit运行tick，id到0xfffffffc时走guard fault停止并清未交付valid，协调重启后更新16bit epoch（外部提供、运行时固定、不得静默重用）。首版不实现无损drain。无限连续采集应扩大id或定义已证明的模序比较，不能拿有限标签作永久唯一ID。

## 3. 重排与故障政策

槽idx=n mod8在采样时分配，存完整tag、时间、系数副本；响应需匹配未完成槽和lane，重复写入为错误。四个lane可能同拍返回，使用可支持独立槽写入的寄存器结构或证明仲裁buffer足够；首版不假定单端口RAM完成多写。

每slot重用相隔200周期；合法样本80周期释放，因此不会撞到仍在途的同slot。释放与采样同拍可能发生，但合法情况下作用于不同slot。8槽覆盖正常约4份在途数据；该推导依赖固定释放与有界转换，不是适用于任意延迟的通用FIFO深度。

正常返回必须在采样+60以内；deadline为采样+80。时间检查必须区分准时响应、超60的违例以及完全缺失；不延长正常输出时序来掩盖违例。同拍valid的采集规则需写在参考模型，不能依赖仿真进程执行顺序。

首版错误策略：missing/late、重复、未知tag、错误lane、槽冲突或输出sink违约时，置sticky_fault并进入HALT，停发新请求，丢弃并记录后续lane响应，清空未交付槽/流水有效位；通过协调复位重启。不发补零正常样本，不把后续样本向前移动。错误拍抑制输出，已经在此前交付的样本保留真实id；fault cycle及样本id进入诊断。真实模拟采样停启是否允许需另定协议。

输出接口首版是push：sink必须接收所有out_valid。可选FIFO允许有界停顿，但须计算容量、满时故障及丢失范围。它不能通过降低长期平均消费速率维持连续采样。

## 4. 系数、定点和原子提交

默认offset=0，inverse_gain=1。offset signed18/F4、inverse_gain signed18/F16，校正公式和nearest-even/saturation按 [AD15](04_calibration.md)。首版admission：|offset|≤128LSB，0.8≤inverse_gain≤1.25；边界按编码后整数比较，越界拒绝整个四lane提交。

shadow保存四lane整组，commit受理后冻结pending，pending未应用时再commit返回busy。只在帧边界n mod4=0把pending切为active、增加版本。此边沿之前已存在pending时本帧用新系数；当拍才提交则下一帧用。每个slot采样时复制该lane两系数及version，独立于后续active变化。

校准先由host/math使用已知±512LSB采样估计，RTL只做系数校正。默认失配：offset=[−8,4,10,−6]LSB；gain=[0.99,1.02,0.98,1.01]。offset/gain隔离实验令skew=0；另一个skew实验采用[0,1ns,−0.8ns,0.4ns]，说明不是校正RTL已消除此误差。

raw=100、offset=4、inverse_gain的整数nearest-even(65536/1.02)=64251时：v=1536，p=98689536，输出整数1506，即94.125LSB；浮点理想为94.117647…LSB。该差是格式/舍入误差，需同独立整数参考比较。

## 5. 复位、版本和统计

core同步低有效复位清valid、fault、计数和pipeline，恢复默认配置；协调lane模型取消旧响应。没有协调flush时不得简单重置epoch/id并继续；独立域复位实验须设计握手并保留不会撞到旧响应的新epoch。

系数版本首版16bit，避免在旧样本/日志仍引用时重用。硬件冻结快照包含请求、有效响应、交付三个64bit计数；故障另有sticky flag/code/id/tick，饱和flag随每份输出。host验证器统计故障事件和饱和输出，累计硬件诊断计数是后续扩展。正常运行按在途槽/流水证明计数守恒。

## 6. 模型与频谱实验

模型与RTL参考分离，先按sample_id生成理想序列，再模拟响应。保持独立“应释放样本”台账，不从DUT输出推回golden顺序。模型参数、seed和版本放manifest，原始采集、FFT图和报告放Git忽略的results。

相干单音：N=65536、Fs=4MHz、bin=6001，fin=366271.97265625Hz，峰值A=1000LSB（FS peak=2048）。6001与N互质，减少短周期采样重复。校准模式和正常模式分开，正常采集前排除流水startup，并确认记录含连续id和单一版本。

offset网格1/2MHz，gain/skew在1MHz±fin及2MHz±fin折叠位置；按失配DFT预测幅度。区分未校准、仅offset、offset+gain、另注入skew/带宽四组，不保证未测的SFDR提升。理想均匀量化且量化误差可视为独立白噪声时，A=1000约67.78dB全Nyquist SNR，仅供尺度检查。

需要列出目标SFDR/SNR、输入频带和残差预算后才能宣称性能达标。至少要求模型真值与估计误差有解释、定点残差逐样本可追溯、校正后谱线符合预算；没有实际结果就填写“待实验”。

## 7. 验收矩阵和提交物

| 层次 | 必测 | 证据 |
|---|---|---|
| 顺序 | 示例与随机合法延迟、同拍返回、槽环绕 | 独立台账与逐样本比较 |
| 故障 | missing/late/duplicate/wrong tag/lane、sink违约 | fault周期、id、HALT及恢复 |
| 复位 | 请求/返回/释放/校正过程中reset、旧响应 | 无伪valid或跨epoch混样 |
| 数值 | 正负端点、半值偶舍入、随机码/系数、饱和 | 整数参考、逐级格式 |
| 配置 | 帧边界、转换在途、pending忙、非法范围 | 每样本系数/version一致 |
| 模型 | 单误差扫频、噪声/量化/带宽、失效输入 | 真值、预测频点及预算 |
| 实现 | 独立回归/综合完成标记、mapped/STA | exit code、报告与网表解释 |

已有独立run_sim/run_synth及连续流脚本，报告放独立results。通过相应实验后登记PASS，见运行指南/进度；普通RTL仿真不是形式等价或模拟签核。100MHz与P=4是首版架构，若换库后STA不满足则修改流水和延迟契约，新配置需重做受影响验证。

SPI用于系数配置、状态和有限快照；18bit×4M=72Mbit/s持续流需要另设计输出接口，不通过现有1MHz SPI输出。真实ADC接口还需电路/时钟/物理数据，当前结课不能替代其验证。
