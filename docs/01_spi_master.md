# 第一课：用 SPI 学 RTL 和综合

## 目标

能把 RTL 对应到实际电路，解释 A5 的发送波形，并知道 Genus 的输入和输出是什么。
先学 Master，再学适用于模拟芯片寄存器接口的 Slave；Slave 涉及外部时钟和 CDC。

## 规格与接口约定

| 信号 | 方向 | 含义 |
|---|---|---|
| clk | 输入 | 50 MHz 系统时钟，周期 20 ns |
| rst_n | 输入 | 同步低有效复位，低电平必须覆盖至少一个 clk 上升沿 |
| start | 输入 | 一个 clk 周期的请求脉冲；busy 时的请求丢弃，不排队 |
| tx_data[7:0] | 输入 | start 被接受时锁存，之后变化不影响本次发送 |
| rx_data[7:0] | 输出 | 第八个 SCLK 上升沿更新，接收方在 done 时使用 |
| busy | 输出 | CS 有效期间为 1 |
| done | 输出 | CS 释放时置 1，持续一个系统时钟周期 |
| cs_n | 输出 | 单从设备片选，低有效 |
| sclk | 输出 | Mode 0 时空闲为低 |
| mosi | 输出 | 主机发送，MSB first |
| miso | 输入 | 从设备发送，必须满足下面的同步时序假设 |

start、tx_data 来自 clk 域，start 高电平跨越接收上升沿。
如果 start 保持为高直到下一次空闲，会再次发起交易，所以接口要求单周期脉冲。
复位后 cs_n=1、sclk=0、mosi=0、busy=0、done=0、rx_data=0。
传输中复位中止交易，不产生 done，复位后可重新发送。

默认 HALF_PERIOD_CYCLES=25：
f_sclk = f_clk / (2 × HALF_PERIOD_CYCLES) = 1 MHz。
CS 拉低到第一个 SCLK 上升沿为 500 ns，每个半周期 500 ns；
最后一个 SCLK 下降沿之后再保持 CS 500 ns，然后释放。
默认 CS 有效时间为 (16+1) × 500 ns = 8.5 μs。

## 从电路看 RTL

- tx_shift：8 位发送寄存器，交易开始锁存 tx_data，下降沿事件时移位。
- rx_shift：8 位接收寄存器，上升沿事件时把 miso 移入。
- rx_data：8 位结果寄存器，保存最后接收的字节。
- div_count：半周期计数器，默认 5 位，不是“产生一个新的内部时钟”。
- bit_count：3 位计数器，表示当前 bit 位置。
- state：IDLE / TRANSFER / FINISH，控制交易的阶段。
- sclk、cs_n、mosi、busy、done：寄存输出，降低组合毛刺风险。

全部 always_ff 都由 clk 触发；RTL 里的 sclk 是寄存器保存的输出电平。
`if (!sclk)` 使用的是该系统时钟上升沿之前的旧值。
非阻塞赋值 `<=` 描述本时钟边沿统一更新的寄存器，不是软件逐句执行后立刻改变变量。

观察：
`tx_shift <= {tx_shift[6:0], 1'b0};`
对应移位连线和寄存器。
`mosi <= tx_shift[6];`
读取旧 tx_shift 的次高位，更新后刚好成为下一位，不是读取移位后的 [6]。

## Mode 0 的一笔交易

1. 空闲：cs_n=1、sclk=0。
2. 接受 start：cs_n=0、busy=1，mosi 提前输出 tx_data[7]。
3. 等待一个半周期：sclk 变高，读取 miso，外部从设备在该沿采样 mosi。
4. 再等待一个半周期：sclk 变低，mosi 更新为下一位。
5. 重复至 8 次采样；第八个上升沿形成完整 rx_data。
6. 第八个下降沿回到 sclk=0，保持 CS 一个半周期。
7. 释放 CS：busy=0、done=1，下一系统时钟 done 清零。

发送 A5：上升沿依次采样 1 0 1 0 0 1 0 1。
测试从设备独立返回 3C：MISO 依次是 0 0 1 1 1 1 0 0。
MOSI 和 MISO 同时传输；全双工不是先发完再接收。

## 仿真怎样证明它正确

testbench 独立实现从设备：CS 拉低时提供首位，SCLK 下降沿切换后续位，
上升沿检查 MOSI，不能直接把 MOSI 回接 MISO 作为唯一验证。

脚本分别测试分频参数 1、3、25：
- A5/3C 首笔交易。
- 256 个发送字节和独立接收字节。
- busy 时插入 start 和改变 tx_data，验证没有重启、没有破坏原交易。
- 传输中复位，验证中止、空闲输出、结果清零及复位后新交易。
- 8 个上升沿、8 个下降沿、半周期、CS setup/hold、done 单周期。
- 总超时和明确 PASS 标记，失败返回非零退出码。

打开 `results/sim/div25/spi_first_frame.svg` 看第一笔交易，
或用 GTKWave 查看 `spi_master.vcd`。重点看首位、最后一位和 done 的关系。
第一版是 RTL 仿真，尚未做门级仿真或形式等价验证。

## 从 RTL 到 Genus

标准单元库 Liberty 保存单元逻辑、时序弧、面积等；MOS 模型文件不能代替它。
这里引用 Genus 自带 tutorial.lib，库是 5 V、25°C 的教学模型；数值仅供教学。

流程：
read_hdl → elaborate → read_sdc → syn_generic → syn_map → syn_opt。
输出：
- mapped.v：标准单元网表，观察 DFF、MUX、计数器加法/比较逻辑。
- mapped.sdc：导出的约束。
- area.rpt / gates.rpt：面积及单元类型。
- timing.rpt：关键路径和 setup 裕量。
- timing_intent.rpt / design_check.rpt：缺失约束及结构问题。

计时单位由 Liberty 确认：本教学库 time_unit=1ns、负载单位为 pF。
SDC 约束系统时钟 20 ns、时钟不确定度 0.2 ns；
主机内部 start/tx_data 假定外部延迟 max 2 ns/min 0.2 ns。
同步复位同样按同步输入约束，不把复位路径粗暴全部 false path。

SPI 端口在第一版采用保守的系统时钟域预算：
MISO 输入 max 5 ns/min 0.2 ns；输出 max 5 ns/min 0.2 ns；负载 0.05 pF。
没有用 multicycle 放宽路径，也没有 blanket false path。
MISO 的实际接收协议预算通常由 SCLK 下降沿、从设备 clock-to-output、
板级延迟和下一上升沿决定；当前 SDC 不完整表达这套源同步关系。
HALF_PERIOD_CYCLES=1 只是逻辑边界测试，不表示满足真实器件的 25 MHz SPI 时序。

因此：
内部同步路径的时序报告可以作为本课教学结果；
外部 SPI setup/hold、SCLK 输出时序及板级接口尚未做完整签核。
后续课再引入 generated clock、外部时序模型以及按采样沿设置的约束。
不要将此 SDC 用作真实板卡或工艺的签核约束。

## 怎样读报告

先确认没有未映射逻辑、意外 latch 和未解析模块。
然后看触发器和组合逻辑数量，和你对上述电路结构的预期比较。
Genus report_timing 的显示单位固定为 ps，即使 SDC/Liberty 使用 ns；14239 ps = 14.239 ns。
最后看关键路径的起点、终点、逻辑级数、负载、arrival、required 和 slack。

近似 setup 关系：
时钟周期 ≥ clock-to-Q + 组合/布线延迟 + setup + 时序裕量。
正 slack 表示在当前模型和约束下通过，负 slack 表示违例。
综合报告不能替代布局布线后带寄生的 setup/hold、多角分析。

## 你的动手练习

1. 不改代码，标出 A5 的 8 个采样点，解释为什么首位没有丢失。
2. 将系统保持 50 MHz，计算 2 MHz SPI 是否能用整数 HALF_PERIOD_CYCLES 精确产生。
3. 使用分频 10，预测 SCLK=2.5 MHz、CS 有效时间=3.4 μs，再用波形验证。
4. 在 busy 时改变 tx_data，解释为什么发送字节不变。
5. 比较移位寄存器 RTL 与 mapped.v 里的触发器；找出关键路径涉及哪些控制逻辑。
6. 解释同步复位与异步复位的区别，以及为什么这里不直接把 SCLK 写进 always_ff。

回答这些问题后再扩展连续多字节、SPI Slave 或配置寄存器，不急着添加全部模式。
