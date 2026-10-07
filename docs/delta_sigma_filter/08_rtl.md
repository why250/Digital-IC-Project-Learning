# DF08：RTL、sample-valid、验证与综合

## 目标

用单 core 时钟实现固定抽取链，保持数学样本序列正确，并解释实现成本和时序路径。

## 单时钟架构

clk_core=49.152 MHz，周期约 20.345052 ns。输入 6.144 MHz 相当于每 8 周期一次 in_valid；CIC 输出每 128 周期一次，后续三个输出间隔为 256、512、1024 周期。全部状态/数据寄存器由 clk_core 驱动，不给每级输出 valid 建一个新内部时钟。

真实 ADC 若在另一时钟域输出，先用符合吞吐和可靠性要求的接口/异步 FIFO 跨域。同步后的 bit 不能因重复采样而当作多份新样本。首版输入契约先假定已在 core 域，CDC 适配器独立设计与验证。

历史移位、CIC 更新、抽取计数只在样本接受时推进。reset 清空全部积分/差分/历史/计数与输出 valid；复位中止未完成的 MAC 任务，不发布旧结果。

## FIR 与调度

直接并行 FIR 清楚但面积大；折叠 MAC 在多个 core 周期完成一个输出，必须保证 deadline 和历史一致。首版每级独立 MAC，任务在下一个该级输入样本到来前完成，分别检查 128、256、512 周期的输入间隔，给历史读取留确定窗口。

读写环形缓冲时锁定逻辑起点，并证明计算期间所需历史不被覆盖；“系数固定”不意味着历史样本不会变化。输出 valid 只在舍入/饱和结果就绪后发一周期。

当前样本与 h0 相乘，其余系数使用旧历史。`history <= shift` 后同一 always_ff 直接读 history 仍读到旧值；用清楚的 next/输入组合或分阶段寄存，避免整体错一份样本。

若乘法/预加/累加无法在当前 core 周期满足 setup，可加流水级，但要同步推进 valid、样本索引与 warm 标志。允许新增 core 延迟，不能修改抽取样本相位或结果序列。

数据相关标签也有滤波支持范围。上游饱和标签随数据存入历史，本级输出对所有实际参与卷积的输入标签作OR，再合并自身饱和，不能只延迟当前输入的一个标志位。

## 输出与集成

out_valid 是 push 接口，消费端必须接受全部输出或由外部缓冲提供可观测 overflow。自由运行 ADC 通常不能为了下游慢而暂停采样，不能让 out_ready 将 CIC 历史冻结。

48 ksample/s×24 bit=1.152 Mbit/s，仅 payload 就超过原 1 MHz SPI 的理论线速；连续数据不能默认通过该接口传出。SPI 首版用于寄存器、状态和偶发冻结快照，持续流使用重新设计的数据接口/速率。

读取多字样本时一次锁存 data/sequence/valid 再拆字读，不能低字取旧样本、高字取新样本。冻结快照不停止滤波，snapshot 与原始 stream 的有效性分开。

## 验证层次

数值 reference 用 DF04 等效 FIR/直接卷积与明确相位，RTL scoreboard 用 bit-accurate 输出；先对齐规定流水延迟/索引，之后每份输出逐位比对。输入激励和检查调度避免与 DUT 边沿竞态。

测试包含 reset/恢复、正负 DC、交替码、两合法码流差响应、边界舍入、随机 seed、完整长流、计数、cadence 违规、任务 deadline 与 saturation。仅集成 Master/Slave 一起通过不能作为唯一验证。

同样检查退出码、明确完成标记、输出样本数、未映射/未解析实例、时钟连接和 timing intent。STA 默认按真实 core 周期分析；sample-valid 间隔大不自动允许所有组合路径多周期，例外要逐路径证明并审查 hold。

当前 tutorial.lib 不代表真实工艺面积/功耗/频率。新项目综合可能暴露 MAC 时序、门数或高扇出问题，这些需要实际报告，不在课程里预写“通过”。

### DF08 参考与实验

- **选读与定位**：K04/K06/K09/K14 · P 存储方法；Own 抽取调度：[EECS151 ASIC Lab 3：SRAM and Hard Macros](https://eecs151.org/asic/lab3/docs/pg4-sram-and-hard-macros/)。来源/边界：[B151-F26](../references/berkeley_eecs151.md)。
- **带着问题读**：只读 SRAM 端口/视图；宏读延迟怎么进入 FIR deadline，不能照搬 dot-product lab 当滤波实现。
- **回到本课做**：EXP-DF-CHAIN / EXP-SRAM-BUFFER：比较历史样本用 FF 还是同步 RAM，先排 MAC 时间表与 valid/phase/warm。
- **留下证据**：存储契约、资源调度、整数 oracle 与真实综合路径；宏/P&R 另验。将预测、实际观察和结论写入 [本方向学习表](11_workbook.md)；公开资料引起的理解变化用 [学习日志模板](../learning_log/_template.md) 记录。

## 验收

bit-accurate、count、phase、warm 和 reset 均通过；延迟/吞吐和实际时序可解释；明确 ADC 输入 CDC 和输出传输接口边界。结课契约见 [项目规格](09_project.md)，答案见 [DF08 参考](10_answers.md)。
