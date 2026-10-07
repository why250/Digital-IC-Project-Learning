# 失配、前台校准与定点：TD08–TD10

## TD08：重构核也会失配

模型 y(t)=Σa[n]p_i(t−nTs)，i=n mod4，a[n]=g_i c[n]+o_i。offset/gain改幅度；skew、脉宽、带宽和settling改p_i。单项隔离后组合，不能把全部误差当gain。

固定宽Ts的脉冲整体移δ_i，则起止同移，lane间差分skew产生gap/overlap。只移开启沿还改变width，是另一模型。TI-ADC的x'(t)δ采样近似不能直接替代TI-DAC边缘误差。

周期失配网格Fs/M=1MHz：offset在k·1MHz，gain单音在k·1MHz±fin产生副本，经各核加权。模拟谱保留这些频率，不全部折回0…2MHz；DC、共轭、sinc零点会使部分线重合/消失。

共同移动所有门控边沿只平移输出；差分skew改变拼接。随机jitter与静态skew分开；SNR≈−20log10(2πfinσt)是特定正弦小扰动近似，不能直接作任意脉冲DAC完整预算。

连续时间核对可精确积分矩形脉冲：幅度A、[a,b)在非零ω下贡献A·(exp(−jωa)−exp(−jωb))/(jω)，ω=0时A(b−a)；除以记录长度得有限窗系数。相干/周期边界闭合时比较周期谱线，带宽模型用对应核。细网格法需步长收敛，粗网格不能研究ps skew。

### TD08 参考与实验

- **选读与定位**：K15/K16/K18 · Own DAC 失配：[本项目 TI-DAC 项目契约](05_project.md)。来源/边界：Own：重构与模拟输出窗口由本项目主导。
- **带着问题读**：本课按 offset/gain/时移/脉宽/残留核分别建模，ADC 失配公式不无条件搬来。
- **回到本课做**：TD mismatch 练习：逐个注入误差，先预测谱线/连续输出变化，再与零失配基线比较。
- **留下证据**：误差注入位置、码域/时间域/模拟域分层对照。将预测、实际观察和结论写入 [本方向学习表](07_workbook.md)；公开资料引起的理解变化用 [学习日志模板](../learning_log/_template.md) 记录。

练习：fin=100kHz列offset/gain首批模拟频点；比较common shift、差分skew、width错误。验收：码FFT和模拟谱分开报告。

## TD09：观测条件与前台估计

已知c−、c+，若能单独测lane的settled输出，g_i=(y+−y−)/(c+−c−)，o_i=y−−g_i c−。校正命令c=(x−o_i)/g_i，再量化并查码范围。观测与码统一为差分LSB，明确参考幅度/零点和sense path增益。

单lane台架或片内sense ADC需测试模式。只测四路长期DC平均通常不能分辨每lane系数，低带宽ADC不能天然解析短脉冲。可延长测试门、逐路选通或已知调制拟合，但需观测核、带宽和秩条件。

timing/width/bandwidth需多频或边缘观测，单正弦的幅相可能混淆误差。clock trim需真实执行器、范围/分辨率/单调性/PVT。分数延迟/预加重只在明确核、频带、因果性、延迟和码余量下近似补偿，不保证消除gate gap/glitch。

### TD09 参考与实验

- **选读与定位**：K15/K18 · Own DAC 估计：[本项目 TI-DAC 项目契约](05_project.md)。来源/边界：Own：重构与模拟输出窗口由本项目主导。
- **带着问题读**：先确认观测通道与模型可辨识，ADC 测得的误差可能来自两端而非 DAC 一端。
- **回到本课做**：TD 校准练习：为 DC/单音/多音写能识别哪些参数，注入测量延迟与 clipping 构造反例。
- **留下证据**：激励/观测/假设表、估计残差与失败范围。将预测、实际观察和结论写入 [本方向学习表](07_workbook.md)；公开资料引起的理解变化用 [学习日志模板](../learning_log/_template.md) 记录。

练习：c±=±512、g=1.02、o=4，求两点观测、估计与x=100校正码；给总DC不可辨识反例。验收：参考源/sense误差可追溯。

## TD10：固定宽度与版本

x为signed12/F0，o为signed18/F4，a=1/g为signed18/F16。先扩展操作数到signed19，d=(x<<4)−o为signed19/F4；p=d·a为signed37/F20。nearest-even除2^20，再饱和到signed12。负数ties/极值由独立整数oracle检查。

默认o=0、a=65536。admission为|o|≤128LSB、0.8≤a≤1.25，对整数即o∈[−2048,2048]、a∈[52429,81920]。合法系数也可能饱和，输出余量要按各lane可用码范围预算。

x=100、o_int=64、a_int=64251：d=1536、p=98689536，p/2^20≈94.1176758，码94、sat=0。实际g=1.02、o=4时输出99.88LSB；最终DAC整码量化仍有残差。

shadow→pending→active保存四lane整组，pending受理冻结，同一帧边界应用；在途帧保存实际系数副本与version，不能读取后来active。算术全范围测试与admission拒绝测试分开。

### TD10 参考与实验

- **选读与定位**：K06/K14/K15 · Own 校正；S 综合方法：[EECS151 ASIC Lab 2：Synthesis](https://eecs151.org/asic/lab2/docs/pg6-synthesis-intro/)。来源/边界：[B151-F26](../references/berkeley_eecs151.md)。
- **带着问题读**：借算术映射与路径分析；RNE/饱和、系数版本和滤波历史仍用 DAC 自己的精确契约。
- **回到本课做**：TD 校正练习：独立整数 oracle 预测正负 tie/端点/version 切换，再排连续输出的 arithmetic deadline。
- **留下证据**：逐级格式/误差、版本历史与延迟/吞吐表。将预测、实际观察和结论写入 [本方向学习表](07_workbook.md)；公开资料引起的理解变化用 [学习日志模板](../learning_log/_template.md) 记录。

练习：推演±2.5、±3.5偶舍入与在途提交版本表。验收：码、sat、frame/version逐样本一致。
