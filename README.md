# 数字 IC 设计学习

面向熟练模拟 IC 工程师的实践项目。先从电路结构理解 RTL，再通过仿真、综合报告和门级网表建立数字设计直觉。

个人目标是向数模混合 IC 发展，结合已有 CT ΔΣ 环路滤波器经验，按“数字基础与 SPI→综合/时序→配置与 CDC→测量/校准控制→ΔΣ 抽取滤波→TI-ADC 校准”推进。见 [个人学习路线与阶段成果](docs/roadmap.md)；首次学习先完成 [第 01 课内的基础入门练习](docs/course/01_sync_spi.md#第-01-课内的基础入门顺序)。

## 完整课程

已选择数模混合控制方向。全课程 48 节：前 24 节建立 RTL、验证、综合/时序、Slave/CDC 和配置基础；后 24 节学习上电管理、ADC/DAC 时序、定点处理、校准、低功耗、DFT 和实现交付。

- [数模混合方向总纲与学习安排](docs/mixed_signal/00_course.md)：48 节路线、四个里程碑和推进门槛。
- [01–24 基础课程](docs/course/00_course.md)：保留已有讲义与验证平台。
- [开始第 01–06 节](docs/course/01_sync_spi.md)：先从 A5/3C 波形与同步电路开始。
- [参考答案](docs/course/07_answers.md)：24 节练习及原有讲义问题的解答。
- [实验记录与验收表](docs/course/08_workbook.md)：记录预测、结果、证据和个人学习进度。
- [中期项目规格](docs/course/06_capstone.md)：通过 SPI 原子更新模拟配置。
- [25–48 专项参考答案](docs/mixed_signal/08_answers.md)与[专项学习记录](docs/mixed_signal/09_workbook.md)。
- [结课项目规格](docs/mixed_signal/07_project.md)：SPI 配置、上电/采样管理与 8 位 trim 前台校准。

讲义、练习和答案已提供；第01课Master已有验证，ADC专题另有独立模型/RTL实验。控制主线其他模块按课程推进；物理实验需要配套且获授权的物理/时序数据。

建议总投入 180–260 小时，每周 6–8 小时；先完成当前 SPI 基础，按项目验收推进。模拟行为模型用于数字契约验证，真实模拟性能与工艺签核另需对应证据。

## ΔΣ ADC 后级数字滤波专题

针对已有 CT ΔΣ 环路滤波器经验，另设 DF01–DF08 八课专题：频谱/STF/NTF、FIR、抽取/混叠、CIC、半带/多级、补偿预算、定点与 RTL。保留原 48 节编号，数学/浮点部分可先学习，硬件实现接在同步 RTL 与定点基础之后。

- [专题总纲](docs/delta_sigma_filter/00_course.md)：40–70 小时、前置与四个里程碑。
- [开始 DF01](docs/delta_sigma_filter/01_spectrum.md)：PSD、dBFS、信号/噪声口径。
- [抽取链结课规格](docs/delta_sigma_filter/09_project.md)：固定候选架构、相位、格式与验收。
- [参考答案](docs/delta_sigma_filter/10_answers.md)与[实际参数/实验记录](docs/delta_sigma_filter/11_workbook.md)。

教学例为 6.144MHz→48ksample/s、20kHz 带宽；实际调制器参数待填写。候选系数和新 RTL 尚未生成/验证，课程不预先承诺 ADC SNR/ENOB。

## ADC 内部数字模块与时间交织专题

新增 AD01–AD20：SAR 控制、Flash 编码、Pipeline 冗余、ΔΣ DEM，以及 TI-ADC 时钟/样本对齐、失配、前后台校准、定点实现和验证。以四通道时间交织为贯穿案例，保留控制主线和 DF 滤波专题。

- [二十课总纲与学习安排](docs/adc_digital/00_course.md)：80–120 小时，前置与选课路径。
- [四通道结课项目](docs/adc_digital/06_project.md)：标签/重排、系数版本和 offset/gain 校正。
- [参考答案](docs/adc_digital/07_answers.md)与[实际参数/实验记录](docs/adc_digital/08_workbook.md)。

教学例总4Msample/s、12bit、100MHz core，已有七个RTL模块、独立数值/接口参考和连续码流实验，见 [可运行实验](docs/adc_digital/09_labs.md)。真实工具状态见进度记录，多相时钟和模拟性能仍需对应电路证据。

## 时间交织 DAC 数字前端专题

新增独立 TD01–TD12：重构/镜像、插值与多相 FIR、DDS、四路分路与预加载、欠载/CDC、通道失配、前台校准、定点/版本、编码/DEM 和三层验证。

- [课程总纲](docs/dac_digital/00_course.md)：60–90 小时，选择四路门控脉冲求和架构。
- [结课规格](docs/dac_digital/05_project.md)：总4M、12bit、100MHz core，码先加载，再按时隙输出。
- [参考答案](docs/dac_digital/06_answers.md)与[学习记录](docs/dac_digital/07_workbook.md)。
- [其他数模混合项目建议](docs/mixed_signal/10_project_choices.md)：测量/trim、SAR/BIST、PLL/DLL、数字辅助LDO及ADC→DSP→DAC集成。

当前是课程与待实现实验契约，尚无 DAC 模型、系数、RTL 或工具结果。实际多相门控、glitch、settling 与时钟校正须对应电路证据。

## Virtuoso AMS 入门

[AM01–AM06完整实验课程](docs/ams/00_course.md)：计数器/DAC/RC→接口桥→settling采样→SAR→trim→CT ΔΣ或交织DAC联合验证，含逐课操作、参考答案、模型接口规格和学习记录。预算64–96小时；课程设计已完成，自建模型/OA/testbench及实际AMS实验尚待逐课实现。

[AMS 官方教程入口与六个实验建议](docs/mixed_signal/11_ams_intro.md)：config视图、AMS UNL、Xcelium/Spectre、logic/electrical桥、RC/settling、SAR与trim联合验证。服务器已找到官方文档/教程包和Virtuoso/Spectre；当前未定位xrun，尚未确认AMS联合仿真可运行。

[AMSDInADE实际解压与运行记录](docs/mixed_signal/12_ams_tutorial_run.md)：PLL原理图已批量读取，首次runams退出255，缺connectLib/数字引擎依赖，未进入仿真。

[IC25.1工具栈评估与版本建议](docs/mixed_signal/13_tool_stack.md)：现有IC/Spectre/DDI/Calibre/Quantus清单，优先补Xcelium/AMS，区分候选版本与已验证组合。

## 第一个练习：SPI Master

规格：50 MHz 系统时钟、1 MHz SPI、Mode 0、8 bit、MSB first、单个从设备。
内部只使用系统时钟，通过使能控制 SCLK 输出和移位；不把 SCLK 用作内部寄存器时钟。

- [第一课讲义](docs/01_spi_master.md)：接口、结构、波形、RTL 阅读与综合。
- [学习路线](docs/roadmap.md)：SPI Master → 综合/时序 → SPI Slave/CDC → 实现。
- [第一份综合报告解读](docs/02_read_first_reports.md)：37 个触发器与时序裕量的来由。
- [验证记录](docs/progress.md)：真实运行结果及尚未完成的工作。
- RTL：`lessons/01_spi_master/rtl/spi_master.sv`
- 自检查测试：`lessons/01_spi_master/tb/tb_spi_master.sv`
- 综合：`lessons/01_spi_master/synth/run_genus.tcl`
- 时序约束：`lessons/01_spi_master/constraints/spi_master.sdc`

## 运行方式

本地保存源码，SSH 到 IC_Server 运行工具。独立服务器目录：
`/home/userone/AAAIC/test_tb/digital_ic_learning`。

PowerShell，在本项目根目录：

```powershell
./tools/deploy.ps1
./tools/remote.ps1 -Action sim
./tools/remote.ps1 -Action synth
./tools/collect_results.ps1 -IncludeVcd
```

服务器上也可直接执行：

```bash
cd /home/userone/AAAIC/test_tb/digital_ic_learning
bash tools/bootstrap_iverilog.sh  # 第一次需要；项目内安装，不修改系统
bash lessons/01_spi_master/scripts/run_sim.sh
bash lessons/01_spi_master/scripts/run_synth.sh
```

运行产物位于 `lessons/01_spi_master/results/`，不纳入 Git。
波形为 VCD，可用 GTKWave 查看；仿真脚本也生成第一笔交易的 SVG。
Genus 自带教学库仅适用于学习，不代表实际工艺的面积、功耗或时序。

## 先做什么

打开个人路线和第 01 课内基础练习，先画寄存器电路并预测同步更新，再完成第 01、02 节：阅读已有 SPI 时不改代码，解释首位数据为什么在第一个 SCLK 上升沿之前有效，标出 `A5/3C` 的八个采样点和 done。
把预测与观察写入实验记录，再继续 RTL、分频与验证。原有第一课讲义作为工程接口参考保留。
