# 时间交织 DAC 数字电路课程

版本：2026-10-04。面向熟练模拟 IC 工程师，接在 [数字基础与数模控制主线](../mixed_signal/00_course.md) 后，复用 [ΔΣ 滤波](../delta_sigma_filter/00_course.md) 的多速率/定点和 [TI-ADC](../adc_digital/00_course.md) 的失配/版本管理知识。独立编号 TD01–TD12，不修改第 01 课 SPI。

目标是从模拟输出结构设计插值、分路、预加载、同步更新和前台校正，区分码流正确与模拟重构正确。当前提供讲义、练习、答案和结课契约；模型、系数、RTL 与工具实验尚待实现。

## 架构选择先于 RTL

时间交织 DAC 可以由多个子 DAC 经模拟开关交替接入输出，或由带时隙门控的电流脉冲求和。若各 lane 持续保持输出并直接求和，总输出不是简单的 x[4k+i] 重建，需要重新推导各支路重构核与数字滤波。

本课程选四路门控脉冲求和：lane i 输出码幅度，只在分配时隙贡献差分信号，其他时间贡献零；每路每四个时隙更新一次。理想四路无缝拼成总速率 ZOH。单路相对自身更新周期为 RZ，占空比1/4；总输出理想为连续 NRZ/ZOH。真实共模、门关残留、overlap/dead time 和负载需电路模型。

并行数字接口到一个高速单核 DAC、四路 DAC 的真实时间交织、DEM 元件轮换，分别解决不同问题，四路数据本身不证明模拟时间交织。

## 课程与产物

课号链接直接进入该课“参考与实验”：在原知识点旁选择具体官方阅读，带着问题回来完成原练习，再记录证据。P/S/O 表示首选/第二视角/可选，Own 保留本项目专属契约。

| 课号 | 主题 | 练习产物 |
|---|---|---|
| [TD01](01_reconstruction.md#td01-参考与实验) | 架构、编码与重构核 | 门控/保持/求和结构图 |
| [TD02](01_reconstruction.md#td02-参考与实验) | ZOH、RZ、镜像与模拟滤波 | 连续时间频谱和下垂 |
| [TD03](01_reconstruction.md#td03-参考与实验) | 插值、抗镜像与多相 FIR | 1→4插值、系数与相位表 |
| [TD04](01_reconstruction.md#td04-参考与实验) | NCO/DDS、幅度与定点 | 相位累加器与误差表 |
| [TD05](02_delivery.md#td05-参考与实验) | 分路、frame 与样本身份 | x[4k+i]交付台账 |
| [TD06](02_delivery.md#td06-参考与实验) | 预加载、settling 与门控 | code-load/gate-on/off时间轴 |
| [TD07](02_delivery.md#td07-参考与实验) | FIFO、CDC、欠载与停启 | 缓冲与安全状态契约 |
| [TD08](03_calibration.md#td08-参考与实验) | offset/gain/skew/脉宽失配 | 单误差频谱及适用条件 |
| [TD09](03_calibration.md#td09-参考与实验) | 已知源前台估计与校正 | 系数、精度和可辨识性 |
| [TD10](03_calibration.md#td10-参考与实验) | 量化、舍入、饱和与版本 | 整数参考与原子提交 |
| [TD11](04_implementation.md#td11-参考与实验) | 分段/温度计编码、DEM、毛刺 | 选择、译码和开关活动 |
| [TD12](04_implementation.md#td12-参考与实验) | 验证、综合与接口评审 | 顺序/数值/波形证据 |

讲义：[TD01–TD04](01_reconstruction.md)、[TD05–TD07](02_delivery.md)、[TD08–TD10](03_calibration.md)、[TD11–TD12](04_implementation.md)。另有 [结课规格](05_project.md)、[参考答案](06_answers.md)、[记录表](07_workbook.md)。其他方向见 [数模混合项目建议](../mixed_signal/10_project_choices.md)。

## 参数、前置与节奏

| 参数 | 教学值 |
|---|---|
| 总 Fs / 通道数 M | 4 Msample/s / 4 |
| 单 lane 码更新率 | 1 Msample/s |
| 数字 core | 100MHz，首版内部寄存器同域 |
| 总时隙 / 帧 | 250ns / 1μs，即25 / 100 core周期 |
| DAC 码 | signed12/F0，−2048…2047，差分信号LSB |
| 扩展插值输入 | 1M→4M；首版先接4M序列 |
| 插值示例通带 / 阻带 | 0–100kHz / 从900kHz起 |
| 理想脉冲 | 幅度为该码输出，宽250ns，lane周期1μs |

1MHz输入的镜像围绕1、2MHz等复制，100kHz信号的首镜像下边缘为900kHz。通带0.01dB、抗镜像70dB可作浮点设计目标，尚无taps/系数或通过结果；需明确区间、增益和定点残差。模拟输出还有4MHz周围的重构镜像，插值FIR不能代替模拟重构滤波。

数学可先学TD01–TD03、TD08。RTL前完成基础01–10、11–17的CDC/流控及专项33–35定点。建议60–90小时，公共内容复用；先通过四路顺序/校正，再加插值/DDS，最后扩展多时钟/DEM。

里程碑：D1理想重构/镜像模型；D2四路交付/预加载台账；D3前台offset/gain估计和整数校正；D4连续时间失配频谱/接口评审。当前个人与工具状态均待记录。

100MHz同步RTL只规定名义事件。真实开关jitter、clock tree、settling、glitch、ps级trim及PVT需电路/物理证据；本例不证明GHz DAC可实现性。首版不要求未知业务后台校准或真实clock actuator。

## 外部资料怎样服务 DAC 项目

重构/插值、预加载、门控、DEM 和核失配仍由本专题主导；流水/接口/验证方法按 [Mapping](../references/course_mapping.md) 选读。实际学习写 [日志](../learning_log/README.md)，验收仍在本专题 workbook。
