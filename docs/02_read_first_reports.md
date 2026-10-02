# 读第一份综合报告

这是第一课完成后的阅读练习，使用 2026-10-02 的实际 Genus 结果。

## 先看 gates.rpt

| 单元 | 数量 | 含义 |
|---|---:|---|
| fflopd | 37 | D 触发器 |
| inv1 | 56 | 反相器 |
| nand2 | 171 | 二输入 NAND |
| nor2 | 13 | 二输入 NOR |
| 合计 | 277 | 映射到教学库的全部实例 |

本教学库只提供少量简单单元，所以 MUX、比较、计数器和其他逻辑会被拆成基础门。
真实标准单元库通常还有更丰富的 MUX、AOI/OAI、不同驱动能力和触发器类型。

声明的存储位总计 39：
tx_shift 8 + rx_shift 8 + rx_data 8 + div_count 5 + bit_count 3 + state 2 + 输出寄存器 5。
综合后只有 37 个触发器，原因是：
tx_shift[7] 和 rx_shift[7] 的保存值都没有后续读取用途，被优化删除。
首个 MOSI 直接读取 tx_data[7]；
接收更新只需要旧 rx_shift[6:0] 与当前 miso。
这说明 RTL 变量数不总是实际硬件数量，综合会删除不可观察的存储。

## 再看 timing.rpt

第一条路径的报告：
- 起点 miso：外部输入。
- 终点 rx_data_reg[0]/D：接收结果寄存器。
- required time：19700 ps。
- input delay：5000 ps。
- 内部数据路径：461 ps。
- slack：14239 ps。

计算：
20 ns - 0.1 ns setup - 0.2 ns uncertainty - 5 ns input delay - 0.461 ns path
= 14.239 ns。

它表示这个输入路径在当前教学时序预算下满足 setup。
它不表示 SPI 接口在任何从设备、任何板级延迟下都正确。
report_timing 显示单位固定为 ps；SDC 的 20 是库时间单位下的 20 ns。

## 最后看 mapped.v

搜索：
`fflopd \\div_count_reg[4]`
观察其 CK 连接 clk，D 连接综合出的组合逻辑，Q 连接 div_count[4]。
再搜索 sclk_reg，它也由 clk 驱动，验证 SCLK 只是一个输出寄存器。

本次全部 37 个触发器均由 clk 驱动，RTL 没有使用 SCLK 作为内部时钟。
37 个触发器的连接和 240 个组合单元构成了这个 SPI 控制器。

## 三个问题

1. 为什么同步复位通常会出现在触发器 D 端的组合逻辑里？
2. 为什么没有 MUX 单元名，网表仍然实现了保持/更新选择？
3. 如果把 clock period 从 20 ns 改为 5 ns，路径 slack 大约会怎样变化？
   注意同时保留 5 ns 输入预算会产生什么结果，不能只考虑内部门延迟。
