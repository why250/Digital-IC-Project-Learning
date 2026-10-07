# AM03：改码 → 等待 settling → 采样

数字 code 已更新，不等于模拟结果已可测。本课将 RC 误差转换为 ADC 码，并把采样做成可归属的请求/应答。

前置 AM01–AM02、FSM 与基本量化。[总纲](00_course.md) · [设置](07_setup.md) · [答案 AM03](09_answers.md#am03) · [记录](10_workbook.md)。预计 8–12 小时。

## 模型与误差定义

沿用 AM01 的 8 bit DAC、2 V/256、R=10 kΩ、C=10 pF、rout=0、理想阶跃。measurement ADC 为 unsigned 10 bit，LSB=2 V/1024=1.953125 mV。

量化明确定义：`Q(v)=clip(floor(v/LSB),0,1023)`，禁止把负数转 unsigned 后再裁剪。对 0→128 阶跃，稳态=1 V，理想稳态码512。结果分成连续误差 `1 V−Vsample` 和量化码差 `Q(Vsample)−512`，这两者不能混成一个“精度”。

对于此 1 V 阶跃，连续残差小于半 ADC LSB 需 `twait>τ ln(1024)≈693.147 ns`。若允许所有 8 bit 码之间最大 1.9921875 V 阶跃，需 `twait>τ ln(2040)≈762.070 ns`。50 MHz 的整周期等待分别至少 35 拍/700 ns 与 39 拍/780 ns，前提是从 DAC 实际改码计时、零额外输出延迟。

floor 量化的稳态值若恰好在512码边界，有限时间从下方接近1 V依然可能读到511；“小于半 LSB 连续误差”不能保证等于稳态 floor 码。对码一致性实验另加非边界目标，并记录距阈值的裕量。

## 请求与时序契约

controller 顺序为 LOAD→WAIT_SETTLE→REQUEST→WAIT_RESPONSE→DONE。接受任务时锁存 code 与 transaction_id，busy 时拒绝新任务。LOAD 边沿 t0 更新 code，等待计数从该次真实更新开始；预定采样边沿是 t0+N×20 ns。用逐周期表消除“数了 N 拍但实际等待 N−1 拍”的错误。

测量模型在约定采样时刻取得 v_rc 一次并保持 Q 值，稍后发布有效应答；发布延迟不改变采样时刻。首版由 clk 同步采样适配器驱动，采样边沿上 code 不再更新，结果最早下一拍有效，避免同一边沿竞态。

异步扩展采用四相握手：req/payload 保持→valid/data/id 保持→req 降低→valid 降低，payload 在整个事务内稳定。同步 valid 后才捕获稳定总线，按设计的保持与确认窗口实现，不给每个 data bit 各放两级 FF 来代替总线握手。复位清空握手、旧应答排空后才允许重用 id；超时和取消也需关闭/排空事务。

## 操作与实验

1. 先画 LOAD、DAC 跳变、sample、valid、done 五个时刻，注明时钟周期和单位。对照 [结课接口规格](08_project.md)。
2. 在同一个 top/config 中替换 counter 为小 FSM，加入测量模型；保存 code、state、sample_event、v_rc、req、valid、id、data。
3. 每个等待时间都重新从 Vc=0 建立 0→128，跑 5/25/35/39 拍，即 100/500/700/780 ns。不要在连续四次转换中假设每次初态为0。
4. 独立脚本/计算器根据实际 t0、sample 时刻预测模拟值，使用另写的 floor/clip 参考预测量化值；不能从 DUT 输出反推期望。
5. 保持 sample 不变，只把 response latency 改为 1/3/10 拍，检查数据相同、done 推迟。再移动 sample，检查误差变化。
6. 注入 busy-start、旧 id 应答、never-valid、超时边界应答及等待中复位。将“模拟未稳”与“测量没回来”分别报告。

## 边界与 PVT

首版采用固定理想参数。另建教学角落：R 最大1.2倍、C最大1.1倍、rout最大1 kΩ，则 τmax=(12 kΩ+1 kΩ)×11 pF=143 ns；最大阶跃的半 ADC LSB 连续误差条件需要 >1089.760 ns，因此至少55拍/1100 ns。780 ns 在此角落不再足够。

该角落只是明确的练习假设，不是实际 PDK corner。若 DAC 有延迟、slew、额外极点、glitch 或负载，重新预算；不能把一阶 RC 时间直接写成真实 ADC 的 SDC 或签核结论。

### AM03 参考与实验

- **选读与定位**：K13/K18/K19 · Own settling；S 接口方法：[EECS151 FPGA Lab 4：Ready-Valid Interfaces](https://eecs151.org/fpga/lab4/docs/pg3-readyvalid/)。来源/边界：[B151-F26](../references/berkeley_eecs151.md)。
- **带着问题读**：只借保持/接受/确认的语义；采样、ADC 延迟、settling 不由 ready-valid 页定义。
- **回到本课做**：EXP-AM-SETTLE：先比较四个等待时间的残差/码，记录 sample_time 与 response_time，再注入迟到 id。
- **留下证据**：RC/量化表、id/version 台账和有效采样窗口。将预测、实际观察和结论写入 [本方向学习表](10_workbook.md)；公开资料引起的理解变化用 [学习日志模板](../learning_log/_template.md) 记录。

## 验收

交付四个等待时间的电压/残差/量化表，标出 floor 边界效应；采样与应答延迟必须分别测量。完成忙时拒绝、身份检查、超时与复位台账。用有效 id、sample_time、code_version 证明每个结果属于哪次改码。

理想电压参考沿用 ≤0.1 mV，整数结果精确比较；边界处另注明数值裕量，不能为了让511变512而放宽容差。进入 AM04 前能独立给出等待拍数和最坏参数来源。
