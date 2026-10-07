# 结课项目：ΔΣ 码流的固定多级抽取链

这是待实现的教学项目，系数尚未生成、RTL 尚未编写或运行。目标是建立算法→系数量化→bit-accurate→RTL 的证据链。

## 1. 冻结参数与构建 manifest

输入 6.144 MHz，信号带宽 20 kHz，输出 48 ksample/s；1-bit 0/1 映射 −1/+1，归一化物理 FS 峰值为 1。候选为 CIC N3/R16/M1、HB31/R2、HB47/R2、补偿 FIR161/R2。

项目另建独立实验目录，不修改第 01 课。系数、倍率、tap 数和位宽在构建时固定，首版不支持运行时重载。每次构建记录：各级 Fs、L、R、相位、设计边界/权重、浮点系数、量化规则/整数系数、W/F、DC/L1、hash、分析工具版本、源版本和目标指标。

如果起始参数无法通过 DF06 指标，先修改 manifest 和模型，再实现。不同 tap/word length 的结果不能混用原 latency/启动阈值。

## 2. 数值与相位契约

CIC 各积分与 comb 用当前样本的 next 结果逐级传播，全级 signed14 modulo，无 saturation/剪位；输出 raw/4096 视作 signed14/F12。

FIR y[n]=h0·当前样本+其余系数·旧历史，每级保留第二个输入。组合相位为 127；最终数学输出 m 对应原输入 n=128m+127。复位前历史与全部状态按 0 初始化。

各 FIR 使用 DF07 的起始格式，累加保留全精度，最后 ties-to-even、缩放到 signed24/F20；越界 saturation 并标志，不悄悄回绕。半带对称/零/中心与 DC 规则在量化后复查。

物理 FS 不是输出容器范围；幅度 0.5 对应输出码 524288，DC=+1 对应 1048576，DC=−1 对应 −1048576。幅度/系数造成的 overshoot 需用 L1 与数值测试确认，不能根据 passband 增益猜极值。

## 3. Core 输入接口

| 信号 | 语义 |
|---|---|
| clk_core | 49.152 MHz，全部功能寄存器使用它 |
| rst_n | 同步低有效，覆盖至少一个上升沿 |
| in_valid | 单周期，新样本在 core 上升沿接受 |
| in_bit | 有效时 0→−1、1→+1，满足 core 同步输入时序 |
| cadence_fault | sticky，错误输入节奏，需 reset 恢复 |

复位释放后允许任意时刻接受第一个样本；之后每 8 个 core 周期恰好一个单周期 in_valid。默认 RUN 不允许漏样、重复样或任意暂停。出现错误节奏后锁存 cadence_fault、取消未完成结果，边沿后不再发布 out_valid，直到 reset；不能把丢失的一份样本悄悄当成采样率降低。

这里输入已在 core 域。真实 ADC/异步 FIFO 适配器需要证明样本不丢失、顺序/速率正确及同步时序；不把同步一个 bit 电平等同于传递完整样本事件。49.152 MHz 与输入时钟的物理来源/相位也要在实际设计中说明。

## 4. 输出接口与流水

| 信号 | 语义 |
|---|---|
| out_data[23:0] | signed24/F20 |
| out_valid | 一周期 push，表示数值已完成，包括 startup 输出 |
| out_seq[31:0] | 从 0 开始的输出序号，自然回绕 |
| out_warm | 等效完整支持窗口已覆盖，随数据/seq 对齐 |
| out_saturated | 当前样本曾在 FIR 级输出被饱和，随结果对齐 |
| saturation_sticky | 当前 epoch 发生过 FIR saturation |

每级FIR的历史同时保存上游saturation标签；本级输出标签为自身饱和与所有非零系数所用历史样本标签的OR。这样前级饱和对后续若干输出的影响不会只标记一份样本。单纯把一个sat位延迟到最后一级不足以表达卷积支持窗口。

最终结果在全部 pipeline drain 后，N 个合法输入应有 floor(N/128) 个输出，不为缺少的样本自动补零。CIC natural wrap 不置 saturation。reset 清状态、所有 valid/任务、seq、warm、sticky；不发布复位前的迟到结果。

输入索引 n=128m+127 是数学标签，core 运算延迟另外记录。无 task stall 的固定实现输出间隔应为 1024 core 周期；每级任务在该级下一个输入前完成，或使用经过验证的缓冲机制。因加流水改变时刻时，data/seq/warm/saturation 必须一起推进。

候选等效长度 K=12238，m=95 时首次可标 out_warm；完整历史首次建立后 warm 保持，直到 reset/fault，不因计数自然回绕清除。启动输出不删除，但性能分析使用明确 steady 窗口。

输出不提供能冻结输入历史的 backpressure。消费端必须持续接收，或由外部 FIFO 处理并报告 overflow/丢弃数；实际调制器能否暂停是另一个系统规格。

## 5. 各层性能验收

| 层 | 检查 | 通过依据 |
|---|---|---|
| float 原系数 | DC、0–20 kHz ±0.05 dB、目标阻带与 delay | 实际数值频响 |
| alias | 输入 PSD、各级 image 到带内贡献 | 相同归一化的功率预算 |
| float 量化系数 | 结构、DC、量化后频响 | 实际整数系数对应的 H |
| bit-accurate | 极值、RNE、wrap、sat、phase、startup | 独立等效/整数参考 |
| RTL | 每份 data/seq/warm/sat 与整数模型一致 | 逐样本计分板及计数 |
| 综合 | 结构、时钟、映射、timing intent、时序路径 | 新项目真实报告 |

最终 FIR 起始 stopband 目标为其输入 96 kHz 下 24–48 kHz 至少 100 dB；整链 alias 增量/绝对指标依输入模型判断。定点额外带内噪声起始目标≤0.5 dB，不能只比较幅度或删掉 saturation 样本后宣称通过。

真实调制器参数未提供，不对 ADC 总 SNR/ENOB 写固定保证。linearized NTF 数据、first-order 离散调制器模型和真实码流分别标记，不互相替代。

## 6. 必测矩阵

| 类别 | 激励 | 检查 |
|---|---|---|
| 编码 | 全 0、全 1、交替 0/1 | −1/+1、DC 归一化 |
| 响应 | 两合法码流仅一处不同 | 相位固定的 2×冲激差响应 |
| 计数 | N=127/128/129/65536 | 0/1/1/512 输出，drain 后判定 |
| 绕回 | 长时间 DC 与随机码流 | CIC 正常绕回，数值一致 |
| FIR 算术 | 正负 tie、极值、对称 pre-add | 舍入/位宽/饱和一致 |
| 时序 | in_valid 连续高、早/晚/缺失 | cadence_fault 与恢复 |
| 启动 | reset 及第一份输入 | m=95 首次 warm，当前构建重算 |
| 复位 | CIC、MAC、输出完成各阶段 | 无旧 valid，seq 重启 |
| 数值性能 | DC、小信号、扫频、带外音、不同 seed | 幅度/噪声/alias 与标记 |
| 数据通路 | 历史写与 MAC 读、任务 deadline | 不混样本、不遗漏 |
| 实现 | 原/量化系数、不同位宽/流水 | manifest、结果与 latency 一致 |

65,536 输入记录有 512 输出但包含 startup。频谱实验采用 12,288 样本预热后再收 65,536：合计 77,824 输入、608 输出；保守去掉前 96 输出后得到 512 steady 输出。

## 7. SPI 集成扩展

1 MHz SPI 不能承载 48k×24=1.152 Mbit/s payload，还未计协议开销。首版只做配置/状态和偶发 snapshot，连续流需要重新评估接口。

SNAPSHOT 请求一次锁存 data/seq/warm/sat，随后读低 16 位与高 8 位；读期间保持整组快照，RELEASE 后允许下一次冻结。采样流继续运行，不因 SPI 读慢停住。reset 使快照无效，读出协议需检查有效性/复位 epoch。

如果配置侧仍用 50 MHz 而滤波 core 为 49.152 MHz，snapshot request/payload/ack 需明确 CDC，不能直接复用同域寄存器读取。原 Slave 的频率、输入稳定窗口和输出 MISO 预算也需对应其实际时钟重新验证。

## 8. 实现证据

保持单 core 时钟，按约 20.345052 ns 约束；输入/输出 max/min、load、transition 与实际同步边界对应。没有证明时不 blanket false path/multicycle，不用低 out_valid 频率自动放宽乘法路径。

按模块→顶层仿真→新项目综合推进，检查命令退出、完成标记、未映射/结构/时钟/时序意图和映射网表。现有 SPI 的 774 笔通过结果只属于第一课。

系数设计和 RTL 完成后才标记相应实测指标，物理、形式、ADC 电路性能与时钟接口签核分别提供证据。报告/码流/图放 results，源/manifest 与摘要可入 Git。
