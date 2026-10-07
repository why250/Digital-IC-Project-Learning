# 数据交付与模拟时序：TD05–TD07

## TD05：分路不是复制

高速序列按i=n mod4、k=floor(n/4)分路。一帧保存四个不同时间的值；复制一个x[k]到四路不能实现四倍重构。四路同拍预处理和错相模拟输出可以并存。

身份采用frame_id/epoch/lane/sample_id/coeff_version。参考从原输入生成应交付台账，不根据DUT输出的lane标签倒推golden。

### TD05 参考与实验

- **选读与定位**：K04/K18 · Own 分路身份；S 接口方法：[EECS151 FPGA Lab 4：Ready-Valid Interfaces](https://eecs151.org/fpga/lab4/docs/pg3-readyvalid/)。来源/边界：[B151-F26](../references/berkeley_eecs151.md)。
- **带着问题读**：只借事务保持与接受条件；四个时间样本不能复制成同一值伪装成正确分路。
- **回到本课做**：TD 分路练习：独立列 12 输入/三帧，码相同也注入 lane 交换或重复 frame，检查身份。
- **留下证据**：frame/lane/sample_id/epoch/version 台账。将预测、实际观察和结论写入 [本方向学习表](07_workbook.md)；公开资料引起的理解变化用 [学习日志模板](../learning_log/_template.md) 记录。

练习：列12份输入的三帧，注入lane1/2交换、重复帧。验收：即使码完全相同，身份检查仍发现错序。

## TD06：code先稳定，再开gate

同时改多位码并开门，会把译码/驱动延迟差转成glitch。采用门关时预加载，预留译码、驱动和settling时间，再开启模拟输出；100ns只是教学预算。需要实际code-load→gate-on最小时间与gate-off后可改码窗口。

名义gate-on g(n)=20+25n个core tick，lane=n mod4。码在g−10加载，gate在[g,g+25)开启。每lane上次关门到下次加载有65ticks=650ns，加载到开门10ticks=100ns；门开期间码保持。

正常边界同拍关旧门、开新门仅在理想RTL无间隙。clock-to-Q、布线、模拟开关延迟会带来overlap/gap，需要门控边沿/脉宽约束与电路实现。one-hot检查不证明物理non-overlap。若增加dead time，平均增益、镜像和重构核要重算。

### TD06 参考与实验

- **选读与定位**：K07/K13/K18 · Own 模拟窗口；S 时序电路：[Rabaey DIC 第 2 版章节索引](https://icbook.eecs.berkeley.edu/resources/powerpoint-slides)。来源/边界：[RABAEY-DIC2](../references/berkeley_ee141.md)。
- **带着问题读**：按 Ch7/10 选读寄存器/clock 时序；one-hot RTL 不证明物理 non-overlap。
- **回到本课做**：TD preload 练习：先画 n=0…7 的 load/on/off，把译码/驱动/settling 加入 code→gate 预算。
- **留下证据**：预加载/关门窗口与 overlap/gap 的电路待验证项。将预测、实际观察和结论写入 [本方向学习表](07_workbook.md)；公开资料引起的理解变化用 [学习日志模板](../learning_log/_template.md) 记录。

练习：画n=0…7的load/on/off，加入reset/fault截断。验收：用最坏译码/驱动/settling预算解释预加载时间。

## TD07：欠载与停启

模拟时基不能随任意ready无条件暂停。FIFO吸收有界停顿，长期平均供给仍需满足4M。12bit×4M=48Mbit/s，不含身份/协议；1MHz SPI用于配置、有限RAM装载，持续波形用内部DDS、预装RAM或其他接口。

首版单core、四样本帧push；CDC作为扩展，用异步FIFO、协调复位、启动水位与有界停顿证明。错相模拟gate不等同于多个RTL clock域。

欠载、坏帧采用sticky HALT、立即关gate并清有效位，协调reset恢复。立即关闭可能截断脉冲，需记录故障时刻；电路的关断安全另定。淡出、保持最后值、补零是不同产品政策，不混入首版。

### TD07 参考与实验

- **选读与定位**：K04/K08/K09 · P FIFO 方法；Own 连续时基：[EECS151 FPGA Lab 4：FIFO](https://eecs151.org/fpga/lab4/docs/pg5-fifo/)。来源/边界：[B151-F26](../references/berkeley_eecs151.md)。
- **带着问题读**：只借有界停顿和容量分析；模拟采样时基不能跟着 ready 任意停，CDC 扩展另验。
- **回到本课做**：TD 欠载练习：先算 64 样本覆盖时长，再注入供应暂停/坏帧，预测 HALT 和 gate 截断。
- **留下证据**：水位/吞吐预算、错误策略和协调复位台账。将预测、实际观察和结论写入 [本方向学习表](07_workbook.md)；公开资料引起的理解变化用 [学习日志模板](../learning_log/_template.md) 记录。

练习：64份样本FIFO忽略水位/流水能覆盖多少停顿？验收：计算容量、余量与长期速率，不能把FIFO当无限缓冲。
