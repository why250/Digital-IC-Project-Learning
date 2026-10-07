# 编码、DEM 与实现：TD11–TD12

## TD11：码相同不等于切换相同

电流舵可用binary、thermometer或分段编码。二进制大进位同时切多位；温度计选择数较平滑，但元件、译码、寄存器负载和走线不同。signed12映射unipolar q=c+2048为0…4095，理想全温度计需4095个单位元件，差分中点/共模关系另由电路定义。

DEM轮换相同理想权重元件，时间交织安排不同lane的输出时隙。DWA可复用 [AD05](../adc_digital/02_timing_data.md)，但ΔΣ环内DEM、独立DAC DEM与lane调度的噪声/延迟预算不同。使用次数均匀不证明带内噪声或SFDR达标，DWA可能产生tones。

小实验用8元件、q=0…8，选q个连续环形元件，pointer加q mod8。q=3连续8次，每元件用3次；q=0指针不变，q=8全选且指针不变。静态元件误差、开关glitch与settling单独建模。

### TD11 参考与实验

- **选读与定位**：K17/K18 · Own DEM：[本项目 TI-DAC 项目契约](05_project.md)。来源/边界：Own：重构与模拟输出窗口由本项目主导。
- **带着问题读**：保留元件数量、选择历史与门控时间；数字码相同不等于模拟切换事件相同。
- **回到本课做**：TD DEM 练习：预测固定选择/轮转的使用分布，分别注入静态单位误差与 switching 非理想。
- **留下证据**：选择与 code/gate 的双台账及 tones/带内误差假设。将预测、实际观察和结论写入 [本方向学习表](07_workbook.md)；公开资料引起的理解变化用 [学习日志模板](../learning_log/_template.md) 记录。

预译码寄存器能让门关时逻辑稳定；实际开关边沿仍需物理证据。练习：比较0111→1000与温度计q=7→8。验收：区别INL/DNL、活动、glitch和DEM噪声。

## TD12：三层验证与综合

第一层身份/时序：输入生成独立台账，检查码、load、gate、版本、故障。第二层数值：整数oracle、边界、负ties、饱和、极系数、startup/reset。第三层模拟重构：用code/gate事件与独立lane核生成y(t)，测镜像、下垂、SFDR/SNDR、脉冲面积。

码FFT干净仍可能overlap/glitch，gate正确仍可能错码。每层包含失败反例；记录参数、seed、代码/工具版本与归一化口径，图形/码流/报告放独立results、Git忽略。

综合解释寄存器、MUX、乘法、译码扇出和关键路径。100MHz是教学目标，不满足时改流水和load契约后重验。code/gate外部约束来自接收电路窗口，仅clk=10ns不证明DAC接口。

运行既有独立Icarus/Genus前读 [进度](../progress.md)。当前无本专题脚本/结果，不借SPI/ADC PASS；后续确认exit、独立完成标记、mapped和timing intent。教学库不证明真实速度、功耗和开关时序。

### TD12 参考与实验

- **选读与定位**：K05/K06/K07 · P 验证方法；Own 三层输出：[EECS151 ASIC Lab 4：Coverage](https://eecs151.org/asic/lab4/docs/pg1-coverage/)。来源/边界：[B151-F26](../references/berkeley_eecs151.md)。
- **带着问题读**：把功能/交叉覆盖用于码值、gate 时间与重构模型；覆盖 RTL 分支不代替模拟核。
- **回到本课做**：TD 集成练习：冻结 oracle，分别注入码错、lane/tag 错、gate 提前；实现后再 synth 并核外部窗口。
- **留下证据**：整数/身份/连续时间三层证据矩阵与未实现 runner 状态。将预测、实际观察和结论写入 [本方向学习表](07_workbook.md)；公开资料引起的理解变化用 [学习日志模板](../learning_log/_template.md) 记录。

练习：注入校正一位错误、lane交换、gate延迟，由哪层捕获？验收：证据包与尚待形式/AMS/物理/器件验证的边界。
