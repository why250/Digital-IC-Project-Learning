# 四路时间交织 DAC 数字前端：结课规格

状态：待实现教学契约。见 [课程](00_course.md) 和 [记录表](07_workbook.md)。未来源码放独立 `lessons/dac_digital/`；当前无DAC模型、RTL或脚本，不修改SPI/ADC实验。

## 首版与接口

四路门控脉冲求和，总4M、lane1M、core100MHz、signed12码。先实现高速四样本帧输入、offset/inverse_gain校正、分路和gate；插值/FIR、DDS、DEM、异步FIFO逐级扩展。系数由host/model前台估计，RTL做固定系数校正。

gate开时理想贡献g_i·code+o_i，关时差分信号为零，共模另定。总输出按250ns拼接。内部所有寄存器用core，不用gate作时钟。

同步低有效reset清gate/valid/fault、恢复默认系数，上游协调flush。start单周期，仅IDLE且同拍首帧有效、id=0、epoch匹配外部配置时接受；无首帧或错误身份则拒绝启动、保持gate关闭并报告start_rejected。成功边沿为tick0，锁存外部16bit epoch，run中固定。RUN每100ticks必须push四个signed12样本，frame_id=k、epoch一致、sample_id=4k+i。其他时刻push、重复/缺帧或错身份为fault；busy时start忽略。

按边沿旧状态判定，寄存器结果指边沿之后。四路并行校正固定P4：tick100k接收、100k+4结果可用。采用两组帧缓存和独立有效位，上一帧末lane的输出码/身份保留在lane寄存器；下一帧不得覆盖旧门开期间的码。

样本n：on g=20+25n，off g+25，load g−10。帧0 load=[10,35,60,85]、on=[20,45,70,95]；帧1 load=[110,135,160,185]、on=[120,145,170,195]。结果需首load前完整可用；100ns提前是教学预算，真实接口另验证。

load带sample_id/lane/epoch/version/sat供台账/诊断。真实DAC消费码及接口时序。fault在当前边沿更新后立即gate=0，清在途valid、置sticky HALT，抑制该拍正常load/on/commit。优先级reset>fault>正常；立即关门可能截断脉冲，不计为完整输出。

## 系数、标签与统计

格式/RNE/sat按 [TD10](03_calibration.md)。commit仅IDLE/RUN且无pending受理，复制shadow四路到pending；非法范围拒绝整组，busy pending拒绝第二次，HALT拒绝commit。已有pending在输入帧边界应用、version加1，当拍才受理则下一帧用；IDLE pending可在start帧应用。每帧保存实际系数副本/version。

version16到ffff拒绝新commit并给status，需reset/新epoch，不静默回绕。frame_id32到ffffffff后guard HALT；sample_id34覆盖4k+i，诊断tick64/计数64不得静默回绕。epoch16由外部协调提供，不重用仍可能在日志或输入引用的旧epoch。首版不承诺无限流，边界前协调停机/复位。

建议冻结快照frames_accepted、samples_loaded、pulses_completed和sat计数；fault另含code/tick/id。正常completed≤loaded≤4·accepted；完整脉冲在off计数，故障优先时截断脉冲不给completed。SPI/APB桥作为集成扩展。

首版运行中stop使用reset/HALT，可截断波形，不实现无损drain/淡出。频谱记录截取指定完整时隙，不把关断瞬态混作稳态。

## 模型与频谱

参考从输入生成身份、精确整数码与计划事件，再按独立模拟核重建。建议N=65536总速率样本、bin1601、fin=97717.28515625Hz、峰值1000LSB；以正常on作记录原点、覆盖N完整时隙、单版本/整数帧/周期闭合。

失配例o=[−8,4,10,−6]LSB，g=[0.99,1.02,0.98,1.01]；c=±512做前台两点。真值/估计分离、测量噪声另扫。skew=[0,1ns,−0.8ns,0.4ns]只在独立波形模型注入，width/settling单项扫。不将offset/gain校正宣称为timing/glitch修复。

分别报告带内0–100kHz、首Nyquist0–2MHz和更高镜像，声明模拟滤波。定义DC/基波/谐波/镜像/lane spurs/噪声的统计规则与FS；不同频带指标不能直接比较。实际目标SFDR/SNDR、负载/电平待填写，无预设通过结果。

## 验收与交付

| 层次 | 必测 | 证据 |
|---|---|---|
| 台账 | 三帧、长流、同码错lane、帧切换 | 独立id/load/on/off |
| 数值 | 全raw、极值/随机系数、正负ties、sat | 整数oracle逐样本 |
| 配置 | 在途/当拍commit、busy、非法组、guard | 整帧版本/系数副本 |
| 故障 | 缺/早/迟帧、错tag/epoch、reset、guard | 优先级/截断/无伪完成 |
| 波形 | ZOH、offset/gain/skew/width/settling | 解析与独立连续模型 |
| 扩展 | 直接/多相FIR、DDS、DEM、FIFO | 独立契约/回归 |
| 实现 | exit/标记、mapped/STA、外部窗口 | 实际工具报告/网表 |

首版至少16384个sample_id并跨帧提交；频谱另采65536完整时隙，均待运行。100MHz/P4若不满足库时序，修订契约重验。结果留Git外，传输普通scp/SHA-256。SPI不能承载48Mbit/s连续码；本轮未部署或运行DAC设计。
