# ADC 内部数字模块课程：从架构到时间交织校准

版本：2026-10-04。面向已有 CT ΔΣ 环路设计经验的模拟 IC 工程师，补足 ADC 内部控制、编码、数据通路和校准设计能力。

## 学习目标与位置

能把不同 ADC 架构中的数字模块对应到寄存器、组合逻辑、接口时序和数值算法；能实现样本对齐与固定系数校正；能分析时间交织 offset、gain、skew、bandwidth 失配及其可辨识性。

本专题 AD01–AD20 独立编号，保留 [48 节控制主线](../mixed_signal/00_course.md) 和 [DF01–DF08 ΔΣ 后级滤波](../delta_sigma_filter/00_course.md)。已有定点、CDC、FFT 内容直接复用，不必重复从头学习。

数学/架构课可以先读。RTL 前完成基础同步设计、综合/时序、CDC 和专项定点运算；先从原 SPI 第一课建立寄存器直觉，不将新功能塞进第一课。预计 80–120 小时，按每周 6–8 小时约 10–20 周，包含模型与实验。

## 二十课目录

课号链接直接进入该课“参考与实验”：在原知识点旁选择具体官方阅读，带着问题回来完成原练习，再记录证据。P/S/O 表示首选/第二视角/可选，Own 保留本项目专属契约。

| 编号 | 主题 | 核心产物 |
|---|---|---|
| [AD01](01_architectures.md#ad01-参考与实验) | ADC 数字模块地图与接口 | 架构/控制/数据/时钟表 |
| [AD02](01_architectures.md#ad02-参考与实验) | SAR 逐次逼近控制 | trial/comparator/结果 FSM |
| [AD03](01_architectures.md#ad03-参考与实验) | Flash 温度计编码与 bubble | 编码参考和错误分类 |
| [AD04](01_architectures.md#ad04-参考与实验) | Pipeline 冗余与数字校正 | residue 权重及样本对齐 |
| [AD05](02_timing_data.md#ad05-参考与实验) | ΔΣ 多比特反馈与 DEM | DWA 选择和环路延迟预算 |
| [AD06](02_timing_data.md#ad06-参考与实验) | 多相采样调度与时钟边界 | 名义相位、物理时钟要求 |
| [AD07](02_timing_data.md#ad07-参考与实验) | 转换延迟、标签与重排 | 按采样时刻合并的通路 |
| [AD08](02_timing_data.md#ad08-参考与实验) | CDC、FIFO、复位与吞吐 | 数据一致性和重启协议 |
| [AD09](03_interleaving.md#ad09-参考与实验) | 时间交织采样模型 | 统一时间轴和误差模型 |
| [AD10](03_interleaving.md#ad10-参考与实验) | Offset/gain 周期误差与杂散 | DFT 失配系数和频率预测 |
| [AD11](03_interleaving.md#ad11-参考与实验) | Timing skew 与随机 jitter | 静态误差与噪声预算 |
| [AD12](03_interleaving.md#ad12-参考与实验) | 带宽失配与可辨识性 | 输入条件与校准范围 |
| [AD13](04_calibration.md#ad13-参考与实验) | 已知 DC 的 offset/gain 校准 | 两点测量及系数求解 |
| [AD14](04_calibration.md#ad14-参考与实验) | 已知正弦的相位/时间估计 | 拟合、参考通道和置信边界 |
| [AD15](04_calibration.md#ad15-参考与实验) | 定点校正与延迟对齐 | offset/gain RTL 与 timing 模型 |
| [AD16](04_calibration.md#ad16-参考与实验) | 后台校准、收敛与业务影响 | 条件、限制及失效用例 |
| [AD17](05_integration.md#ad17-参考与实验) | 原子系数、版本与诊断 | frame 边界提交和快照 |
| [AD18](05_integration.md#ad18-参考与实验) | 行为模型、FFT 与覆盖 | 参数/故障/指标矩阵 |
| [AD19](05_integration.md#ad19-参考与实验) | RTL 回归、综合与 STA | 顺序、数值与路径证据 |
| [AD20](05_integration.md#ad20-参考与实验) | 集成、功耗和交付评审 | 架构选择与证据包 |

## 讲义与辅助资料

- [AD01–AD04：架构中的数字电路](01_architectures.md)
- [AD05–AD08：反馈、时钟和数据对齐](02_timing_data.md)
- [AD09–AD12：时间交织失配](03_interleaving.md)
- [AD13–AD16：估计与校正](04_calibration.md)
- [AD17–AD20：配置、验证与实现](05_integration.md)
- [四通道结课项目](06_project.md)
- [参考答案](07_answers.md)
- [实际参数入口与实验记录](08_workbook.md)
- [AD01–AD20可运行实验与证据分层](09_labs.md)

## 推荐选课顺序

| 阶段 | 课号 | 时间预算 | 推进门槛 |
|---|---|---|---|
| 架构与控制 | AD01–AD04 | 12–18小时 | 能解释控制事件、编码与样本身份 |
| 反馈、时钟和对齐 | AD05–AD08 | 16–24小时 | 有时间轴、重排和复位/吞吐契约 |
| 交织失配 | AD09–AD12 | 16–24小时 | 模型预测频点并说明可辨识性 |
| 估计与校正 | AD13–AD16 | 20–28小时 | 系数/误差/位宽和延迟有独立参考 |
| 集成与实现 | AD17–AD20 | 16–26小时 | 版本、验证和实现证据完整 |

先做 AD01–AD02 的同步控制，再用 AD06–AD11 学时间交织的时序、顺序和误差；接 AD13–AD15 的已知输入校准及定点校正，最后做 AD17–AD20 的集成验收。AD03–AD05 按 Flash/Pipeline/多比特 ΔΣ 需求展开；AD12、AD16 是更复杂校准的前提课。

FFT/PSD 口径复用 [DF01](../delta_sigma_filter/01_spectrum.md)，定点复用 [33–35](../mixed_signal/03_fixed_point.md)，CDC 复用 [11–15](../course/03_slave_cdc.md)。不需要先把控制主线、DF 支线和 AD 支线全部串行读完。

## 教学案例与证据边界

主案例四通道 TI-ADC：总采样率 4 Msample/s，每通道 1 Msample/s，12 位补码，core=100 MHz。每25个core周期调度一份样本，通道依次0、1、2、3；转换响应延迟可不同，不能按返回顺序直接拼接。

先用同 core 域的转换器行为模型、固定 offset/gain 系数做可实现的教学 RTL。时钟相位、skew 和 jitter 在模型中独立注入；100 MHz RTL 状态机不证明实际 GHz 多相时钟、ps 级调相或 aperture jitter 达标。采样脉冲宽度/边沿、PLL/DLL、clock tree、buffer、PVT 和版图需要相应电路证据。

四个里程碑：A1 SAR 控制与编码推演；A2 TI 样本标签/重排；A3 已知输入 offset/gain 校准及定点校正；A4 timing/bandwidth 的模型与集成评审。首版不把未知输入后台校准或可变延迟 ADC 接口包装成通用算法。

实际 ADC 参数待填写。已有数值/行为模型、七个RTL模块、独立回归和端到端码流实验；逐课实现见 [运行指南](09_labs.md)，真实工具状态见 [进度记录](../progress.md)。实际器件参数和系数仍需测量。使用独立batch，报告/波形/工具/许可证/工艺数据留Git外；教程Genus库用于逻辑教学，不承诺真实ADC性能与签核。

## 参考学习材料

主教材是本目录的讲义、练习、答案与结课规格。补充阅读可选 Schreier/Temes 的《Understanding Delta-Sigma Data Converters》（DEM、环路和非理想），Oppenheim/Schafer 的《Discrete-Time Signal Processing》（采样、频谱与重构），以及 Razavi 的 ADC 架构讲义/课程（SAR、Flash、Pipeline与TI）。按对应课的问题检索阅读，不要求整本先读完。

复杂校准论文先检查输入统计假设、误差模型、参考通道、clock actuator与收敛条件，再考虑移植算法。论文中某工艺/频率下的测试结果不直接成为本项目预算。

## 外部资料怎样服务 ADC 项目

SAR/TI/校准、样本身份与系数契约保留在本专题；公共 RTL/验证/实现方法查 [Mapping](../references/course_mapping.md)。已有工程证据不自动完成个人学习；用 [日志](../learning_log/README.md) 记录理解，再回本专题 workbook 验收。
