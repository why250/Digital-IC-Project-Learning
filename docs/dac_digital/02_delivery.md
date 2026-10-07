# 数据交付与模拟时序：TD05–TD07

## TD05：分路不是复制

高速序列按i=n mod4、k=floor(n/4)分路。一帧保存四个不同时间的值；复制一个x[k]到四路不能实现四倍重构。四路同拍预处理和错相模拟输出可以并存。

身份采用frame_id/epoch/lane/sample_id/coeff_version。参考从原输入生成应交付台账，不根据DUT输出的lane标签倒推golden。

练习：列12份输入的三帧，注入lane1/2交换、重复帧。验收：即使码完全相同，身份检查仍发现错序。

## TD06：code先稳定，再开gate

同时改多位码并开门，会把译码/驱动延迟差转成glitch。采用门关时预加载，预留译码、驱动和settling时间，再开启模拟输出；100ns只是教学预算。需要实际code-load→gate-on最小时间与gate-off后可改码窗口。

名义gate-on g(n)=20+25n个core tick，lane=n mod4。码在g−10加载，gate在[g,g+25)开启。每lane上次关门到下次加载有65ticks=650ns，加载到开门10ticks=100ns；门开期间码保持。

正常边界同拍关旧门、开新门仅在理想RTL无间隙。clock-to-Q、布线、模拟开关延迟会带来overlap/gap，需要门控边沿/脉宽约束与电路实现。one-hot检查不证明物理non-overlap。若增加dead time，平均增益、镜像和重构核要重算。

练习：画n=0…7的load/on/off，加入reset/fault截断。验收：用最坏译码/驱动/settling预算解释预加载时间。

## TD07：欠载与停启

模拟时基不能随任意ready无条件暂停。FIFO吸收有界停顿，长期平均供给仍需满足4M。12bit×4M=48Mbit/s，不含身份/协议；1MHz SPI用于配置、有限RAM装载，持续波形用内部DDS、预装RAM或其他接口。

首版单core、四样本帧push；CDC作为扩展，用异步FIFO、协调复位、启动水位与有界停顿证明。错相模拟gate不等同于多个RTL clock域。

欠载、坏帧采用sticky HALT、立即关gate并清有效位，协调reset恢复。立即关闭可能截断脉冲，需记录故障时刻；电路的关断安全另定。淡出、保持最后值、补零是不同产品政策，不混入首版。

练习：64份样本FIFO忽略水位/流水能覆盖多少停顿？验收：计算容量、余量与长期速率，不能把FIFO当无限缓冲。
