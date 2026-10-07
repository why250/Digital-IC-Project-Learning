# 个人学习路线

目标：结合模拟 IC 与 CT ΔΣ 环路滤波器经验，能独立完成 ADC 周边控制、校准和数字处理模块。每次练习按“电路图 → 预测波形/数值 → RTL 或模型 → 独立检查 → 综合结构与时序解释”推进。

本页决定先学什么、何时进入支线；逐课目录见各总纲，当前实现与工具证据见 [进度摘要](progress.md)。课程编号保留，个人掌握程度由各学习记录验收。

## 当前起点

从 [第 01 课内的基础入门顺序](course/01_sync_spi.md#第-01-课内的基础入门顺序) 开始：写出 8 位无符号与补码范围，画一个带 enable 和同步低有效复位的寄存器，再预测两个寄存器同沿更新的结果。

接着做 01、02：手画 A5/3C 一帧，标出八个采样点、首位提前有效、末尾 CS 保持与 done。写入 [基础学习记录](course/08_workbook.md)，再与 [参考答案](course/07_answers.md) 对照。工具已有 PASS 不自动通过个人验收。

## 主线与推进门槛

| 顺序 | 学习内容与入口 | 通过后应能做到 |
|---|---|---|
| 1 | [01–06：同步 RTL 与 SPI Master](course/01_sync_spi.md) | 画 Q→组合逻辑→D，预测更新、解释完整帧，验证能发现注入错误 |
| 2 | [07–10：综合与 STA](course/02_synth_sta.md) | 解释映射网表、setup/hold 与 SDC 的接口、负载和 PVT 假设 |
| 3 | [11–15：Slave/CDC/原子配置](course/03_slave_cdc.md) → [16–18：集成/FIFO](course/04_integration.md) → [23–24：配置项目](course/06_capstone.md) | 配置更新一致，事务接受/拒绝与复位恢复明确；APB 为可选扩展 |
| 4 | [25–28：上电/故障](mixed_signal/01_power_reset.md)、[29–32：采样](mixed_signal/02_sampling.md) → [33–36：定点](mixed_signal/03_fixed_point.md) → [37–40：校准](mixed_signal/04_calibration.md)、[41–44：验证](mixed_signal/05_verification.md) | 分开验证上电、测量和平均，再完成 [测量/trim 控制器](mixed_signal/07_project.md) |
| 5 | [DF01–DF08：ΔΣ 后级滤波](delta_sigma_filter/00_course.md) | 形成浮点→定点→RTL 的 [CIC/FIR 抽取链](delta_sigma_filter/09_project.md)，解释混叠、位宽和延迟 |
| 6 | [AD01–AD20：ADC 数字模块](adc_digital/00_course.md) | 完成 [TI 样本重排与 offset/gain 校正](adc_digital/06_project.md)，分析 skew/jitter 的适用条件 |

完整 01–48 阶段索引见 [控制总纲](mixed_signal/00_course.md)。

[19–22 物理基础](course/05_physical.md) 与 [45–48 低功耗/DFT/交付](mixed_signal/06_implementation.md) 随项目穿插。实际布局布线、寄生和多角验证等待配套物理/时序数据；理论学习可以继续。

## 结合 CT ΔΣ 背景的选课策略

上表给出重心顺序，不要求读完全部控制课程才开始滤波。完成公共基础后，优先把 ΔΣ 抽取滤波做成自己的完整项目，再深入 TI-ADC 校准；SAR 可作为较小的控制练习穿插。

| 支线 | 可以提前做 | 进入实现前需补齐 | 学习记录 |
|---|---|---|---|
| DF | DF01–DF06 的数学/浮点预测可与基础课并行 | 01–10 同步 RTL/STA、33–35 定点；先冻结实际 ADC 参数 | [DF 参数与验收](delta_sigma_filter/11_workbook.md) |
| AD | AD01–AD02 架构/SAR，AD09–AD14 失配与估计模型 | TI 后端需 CDC/FIFO、定点和 STA；按 [逐课实验](adc_digital/09_labs.md) 对照 | [AD 参数与验收](adc_digital/08_workbook.md) |
| [TD](dac_digital/00_course.md) | 重构、插值和失配的数学模型 | 公共基础与定点；先码交付/offset-gain，再加 DDS/插值 | [TD 参数与验收](dac_digital/07_workbook.md) |
| [AM](ams/00_course.md) | 01–06 后做 AM01–AM03 的绑定、接口桥和 settling 预测 | AM04 接 SAR，AM05 接 trim；AM06 优先接 DF，真实 AMS 运行先过 [环境清单](ams/07_setup.md) | [AM 参数与验收](ams/10_workbook.md) |

AMS 随控制与转换器项目逐步加入。TD 与复杂后台校准后续展开；PLL/DLL、数字辅助 LDO、BIST 等见 [项目建议](mixed_signal/10_project_choices.md)，当前只集中推进一个完整项目。

## 遇到问题时怎样读公开资料

先从自己的项目提出问题，再在 [知识节点与课程 Mapping](references/course_mapping.md) 找到原课号和首选参考。例：寄存器同沿更新→K02/MIT 6.004；SPI checker 是否有效→K05/Berkeley Lab 4；综合路径/架构取舍→K06/Cornell；宏缓冲→K09；模拟采样、校准和 AMS→本项目主导节点。

一次选一个具体章节或 lab 方法，回到自己的预测、实验和 artefact，写入 [学习日志](learning_log/README.md)，最后回原 workbook 验收。公开课的课时顺序不替代上面的项目顺序，O 选读不强制计入时间预算。

已确认的深度缺口按需使用 [验证补充](practice/verification.md)、[时序/PPA](practice/timing_and_ppa.md)、[RAM/SRAM](practice/memory.md) 与 [物理/DFT](practice/physical.md)。先解释和设计，再按工具/数据条件实现；这些补充没有新课号，也没有新的实验 PASS。

## 时间安排

| 范围 | 起始预算 |
|---|---:|
| 01–24 数字基础 | 60–90 h，包含初始基础练习与 SPI 理解的 20–30 h |
| 25–48 数模控制 | 120–170 h；与基础合计 180–260 h |
| DF / AD / TD / AM | 分别 40–70 / 80–120 / 60–90 / 64–96 h |

控制主线按每周 6–8 h 约 23–44 周。支线按项目需要选学，共用的定点、CDC、频谱与校准知识复用，预算不机械相加。每次约 60–90 分钟，先预测、再实验、最后解释；通过验收再推进。

基础与控制的记录分别在 [01–24 学习表](course/08_workbook.md) 和 [25–48 学习表](mixed_signal/09_workbook.md)。第一课固定为 50 MHz 系统时钟、默认 1 MHz SCLK、Mode 0、8 位、MSB first、内部单 clk；后续项目独立实现。
