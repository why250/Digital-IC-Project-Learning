# 专项二：采样、更新和数据通路（29–32）

目标：把采样电路、转换器和更新窗口的实际条件转换为可验证的控制时序。所有时间先标出来源，再换算系统周期。

## 29：ADC 采样与转换不是一个动作

### 讲解

一种外部控制 ADC 的教学流程：配置输入→等待 acquisition→发起 conversion→等待响应→捕获结果→发布 sample_valid。实际 ADC 可能自由运行或使用不同握手，不能把本流程当成通用引脚标准。

acquisition 时间满足输入电容充电等模拟要求；conversion 时间来自转换架构；结果有效时间来自接口协议。数字控制器分别保证这些窗口，不能在 conversion start 的同一个边沿直接读取 data。

每次请求分配 transaction_id，并记录使用的配置版本 config_version。迟到结果只能匹配尚未完成的当前请求；abort 后即使 EOC 到来，也不能归入下一次测量。

异步 EOC 若是窄脉冲，不能只接两级同步器。采用保持 valid/data/id 直到 ack 的响应协议或受约束的事件传输；多位 data 用保持加握手/缓冲保证一致，不逐位同步后拼起来。

教学计时：acquisition=400 ns，50 MHz 下需 20 周期；最大转换响应等待 4 μs 对应 200 周期。异步接口同步/握手开销单独计入，不在转换器的典型时间里隐藏。

### 29 参考与实验

- **选读与定位**：K04/K13/K18 · Own 主导；S 接口方法：[EECS151 FPGA Lab 4：Ready-Valid Interfaces](https://eecs151.org/fpga/lab4/docs/pg3-readyvalid/)。来源/边界：[B151-F26](../references/berkeley_eecs151.md)。
- **带着问题读**：借 valid/data 保持与接受思想；sample_time 与 response_time 的差异由本 ADC 测量协议决定。
- **回到本课做**：测量练习：预测早/晚/重复/迟到 response，独立 request ledger 检查每份结果的 id/version。
- **留下证据**：采样、应答与确认时间线和一请求最多一发布台账。将预测、实际观察和结论写入 [本方向学习表](09_workbook.md)；公开资料引起的理解变化用 [学习日志模板](../learning_log/_template.md) 记录。

### 练习与验收

画出 request、sample switch、conversion、valid/data/id、ack 的时间线。测试早/晚/重复/迟到响应和转换超时。验收要求每个有效请求最多发布一次结果，结果具有正确配置版本。

## 30：DAC/trim 更新和 settling

### 讲解

active_code 同沿更新后，实际输出可能先出现毛刺再稳定。最小 settling 必须从实际数字配置应用事件开始计时，不从 SPI 命令发出或写 shadow 时开始。

如果有 analog_ready/settled 检测，允许测量需同时满足最小等待和有效 ready。没有检测时，只能根据给定全条件最坏 settling 预算等待，并说明该预算的来源与适用范围。

不要把计数延迟当成延迟线精确参数：系统时钟周期、时钟误差、传播与模拟响应都参与物理预算。时间不得短于要求时使用向上取整，并保留时钟最快情况的检查。

例：要求至少 750 ns，名义周期 20 ns，需要 ceil(750/20)=38 个完整周期，即 760 ns。若最快允许 clk 为 51 MHz，38 周期约 745.1 ns 已不足，应至少 39 周期或调整预算。

### 30 参考与实验

- **选读与定位**：K13/K18 · Own 主导；S 状态方法：[MIT 6.004 单元 6：Finite State Machines](https://ocw.mit.edu/courses/6-004-computation-structures-spring-2017/pages/c6/)。来源/边界：[M6004-S17](../references/mit_6004.md)。
- **带着问题读**：只借状态保存与转移；数字 code_applied 不等于模拟 settled。
- **回到本课做**：EXP-AM-SETTLE 前置：commit 后继续改 shadow，预测当前快照和禁止采样窗口，接 AM03 的 RC 检查。
- **留下证据**：commit/apply/settled/sample 四事件表与等待预算。将预测、实际观察和结论写入 [本方向学习表](09_workbook.md)；公开资料引起的理解变化用 [学习日志模板](../learning_log/_template.md) 记录。

### 练习与验收

从提交、应用、settling 完成到采样标出四个不同事件。测试等待期间再次写 shadow，不应重置当前快照或把新码用于旧标签的样本。验收要求测量不发生在有效码改变后的禁用窗口内。

## 31：quiet window 需要明确活动范围

### 讲解

quiet window 是模拟敏感期间的数字活动约束，例如采样孔径附近暂停配置切换和校准码更新。它不自动使整颗芯片安静：SPI 引脚、时钟树、后台计数器和其他域仍可能切换。

先定义窗口起止和受控对象。更新控制器只在允许窗口应用 pending；采样控制器保证窗口已经建立。用“请求静默→确认受控模块静默→采样→释放”可以表达需要多模块协调的场景。

若静默时间包含模拟稳定过程，完成确认不能只检查数字 enable=0。模拟端还需给出 settling/隔离条件。真正关钟需要可靠门控与唤醒路径，首版用寄存器使能减少功能切换，保留时钟。

### 31 参考与实验

- **选读与定位**：K11/K13 · Own 主导；S CMOS 视角：[Rabaey DIC 第 2 版章节索引](https://icbook.eecs.berkeley.edu/resources/powerpoint-slides)。来源/边界：[RABAEY-DIC2](../references/berkeley_ee141.md)。
- **带着问题读**：按电容切换与时钟章节选读；quiet 约束哪些活动、哪些耦合必须另测？
- **回到本课做**：quiet-window 练习：在 400 ns 窗口注入 SPI/pending/calibration，逐项预测等待、拒绝或缓存。
- **留下证据**：禁止/允许活动表与噪声/settling 的独立证据需求。将预测、实际观察和结论写入 [本方向学习表](09_workbook.md)；公开资料引起的理解变化用 [学习日志模板](../learning_log/_template.md) 记录。

### 练习与验收

为一个 400 ns 采样窗口规定禁止切换的输出和允许活动的逻辑。注入 SPI 写入、pending commit 和校准请求，检查它们等待、拒绝或正常缓存的规则。验收要求不会因为“quiet”信号为 1 就未经证据宣称模拟噪声达标。

## 32：吞吐量与缓冲

### 讲解

若每个样本包含 acquisition、转换、响应传输和间隔，最大样本率由整条流程决定。例：0.4 μs + 2.0 μs + 0.1 μs + 0.5 μs =3.0 μs，理论连续速率约 333.3 ksample/s；16 个样本至少约 48 μs，尚未含每块开始前的 trim settling。

结果消费者更慢时选择背压、有限 FIFO 或丢弃并计数。不能无声覆盖未读结果。校准优先保证每个平均块收到确定数量、同一 trim 版本的样本，因此首版一次只允许一个未决 ADC 请求。

标签位宽和回绕也要考虑：有限 transaction_id 不是永久唯一。取消操作后需要 drain/cancel ack 或响应 epoch 重新同步，避免旧响应在编号重复后误匹配。结果 FIFO 中的数据也携带版本，而不只保存 ADC 数值。

### 32 参考与实验

- **选读与定位**：K04/K09/K18 · P 性能基础；Own 测量预算：[MIT 6.004 单元 7：Performance Measures](https://ocw.mit.edu/courses/6-004-computation-structures-spring-2017/pages/c7/)。来源/边界：[M6004-S17](../references/mit_6004.md)。
- **带着问题读**：只读 latency 与 throughput 区别，分别套入 sample、conversion、response、平均块。
- **回到本课做**：吞吐练习：消费者暂停时先算峰值积压和块时间，再用独立队列验证恢复顺序。
- **留下证据**：吞吐/超时统一预算、FIFO 容量与停顿上限。将预测、实际观察和结论写入 [本方向学习表](09_workbook.md)；公开资料引起的理解变化用 [学习日志模板](../learning_log/_template.md) 记录。

### 练习与验收

计算给定时序下的样本率、块测量时间和校准总预算。让消费者暂停，检查缓冲不被覆盖，恢复后顺序正确。验收要求吞吐量与超时计数使用同一套时序假设。
