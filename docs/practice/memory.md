# K09：从 FIFO 到 RAM / SRAM 宏

接 [17 FIFO](../course/04_integration.md)、DF08 历史缓冲与 AD08 样本缓冲；参考 [Berkeley Lab 3 SRAM](https://eecs151.org/asic/lab3/docs/pg4-sram-and-hard-macros/) 和 [Cornell S05](https://cornell-ece5745.github.io/ece5745-S05-srams/)。**EXP-SRAM-BUFFER 目前是练习设计，尚无宏集成或物理结果。**

## 三个边界分别负责什么

FIFO 是顺序、占用与接受规则；RAM 是地址化存储；SRAM 宏是带电气/时序/物理边界的实现。原 FIFO 的读端若在接受边沿前组合可见，替换成同步读 RAM 会增加延迟，需要 read request/response、预取和输出缓冲；换数组声明并不能维持原协议。

模拟视角看 SRAM 也是有访问时间、setup/hold、slew、负载和供电限制的电路。RTL 数组在综合后可能成为 FF+mux；ASIC 中只有匹配推断规则或显式宏实例与库视图，才可能映射成 SRAM。FPGA BRAM 推断结论不能直接搬来。

## 第一个练习契约

选 **16×16、单 clk、1R1W、同步读** 的行为模型，先不用工艺宏：

| 条目 | 本练习定义 |
|---|---|
| 写入 | 边沿 E_n 的 wr_en/wr_addr/wr_data 接受并写入 |
| 读取 | E_n 接受 rd_en/rd_addr；E_n 后更新 rd_data/rd_valid，消费方在 E_n+1 采样；按边沿接口称一周期响应 |
| 端口冲突 | 不同地址可同沿读写；同址读写是非法请求，由 checker 检测 |
| 初始化 | 存储内容未知，reference 维护 initialized mask；读未写地址不可比较成零 |
| reset | 同步 reset 清 rd_valid/控制，存储内容不清零；协议优先级 reset 高于请求 |
| 无请求 | rd_valid 清零，rd_data 可保持；valid=0 时不把 data 当新响应 |

这里的同址“非法”是教学选择，不是所有 RAM 的规定。接真实宏时逐项确认 read-first/write-first/no-change/undefined、使能极性、字节掩码、输出保持/未知及睡眠模式。多端口/双时钟碰撞不能由本同步练习推出安全结论。

## Prediction → Experiment → Evidence

先手画四沿：写 A=0x1234 → 读 A 同时写 B → 连续读 B/A → reset 与请求并发。标接受沿、输出有效区间、消费沿与 expected data。再故意同址读写、读未初始化地址、读延迟提前/晚一周期，预测 checker 的分类。

后续实现时用独立字典/队列 reference；按契约在事件发生时更新，不照抄 DUT 地址流水。记录接受与 response 一一对应，复位取消规则，冲突次数和已初始化地址。通过模型/RTL 后，比较寄存器实现的单元数和关键 mux 路径；宏面积/时序要等匹配数据，不能用教学 Liberty 推出 SRAM 性能。

若把它用于 DF08，另审查每输出所需历史样本访问次数和 MAC deadline；用于 ADC FIFO 时维持无丢不重、预取、full/empty 边界和复位 epoch。异步 FIFO 的跨域协议、Gray skew/max-delay 仍独立验证。

## 接真实宏前的视图清单

| 视图 / 数据 | 用途 | 必须核对 |
|---|---|---|
| 行为 Verilog / SV 模型 | 验证端口和访问语义 | 极性、延迟、collision、init/reset/power 状态 |
| Liberty 各分析角 | STA / 功耗 | 名称/引脚、单位、时序弧、setup/hold、max/min、条件弧 |
| LEF / 技术 LEF | 放置布线 | 尺寸、pin/layer、obstruction、方向与供电 |
| GDS/OASIS、CDL/SPICE 与规则/映射 | DRC/LVS | 与实例/版本匹配；不可用 blackbox 静默吞掉缺失 |
| 电源/测试文档 | sleep、retention、BIST/repair | 时序、状态、测试拥有权和模型覆盖 |

相同 cell 名称不足以证明视图相容，要记录来源/版本/角和授权路径。专有视图、完整报告与波形留忽略目录。

验收产物为 RAM 契约、四沿预测、独立 checker、冲突/复位用例、视图缺失清单；当前状态仍待实现。记录回 [日志](../learning_log/README.md)，公共关系回 [K09 Mapping](../references/course_mapping.md)。
