# K05：从检查通过到验证闭环

接 [01–06 SPI/TB](../course/01_sync_spi.md) 与 [41–44 验证](../mixed_signal/05_verification.md)，外部首选 [EECS151 Lab 4 路径](../references/berkeley_eecs151.md)。本页为原创练习设计；**lint/SVA/形式任务尚未执行**，不改变已有 SPI 回归。

## 先列契约，再选检查手段

| 契约 / 失效 | 独立观察 | 最小反例与证据 |
|---|---|---|
| start 只在空闲接受 | 接受事件台账与 latched TX | busy 中发不同 tx_data/start，发送值仍来自原请求 |
| done 只持续一周期且 CS 已释放 | clk 边沿 monitor / SVA | 将 done 清零去掉，检查必须失败 |
| RX 来自独立从机，第八采样更新 | 独立 slave 与 sampling ledger | 将接收位序或采样沿改错，计分板必须失败 |
| reset 取消当前事务并回空闲 | 复位与完成事件台账 | 在首位/中间/最后采样/释放边界复位 |
| FIFO 不丢不重，接受受 full/empty 限制 | reference queue / 计数守恒 | 边界并发读写、环绕、旧 epoch 数据 |

monitor 检查已发生的轨迹；lint 查静态结构；形式检查所声明假设下的全部或有界轨迹。三者分别留下证据，不能用同一个 PASS 互相替代。

## EXP-RTL-LINT：诊断要解释成电路

一手参考：[Verilator 参数](https://verilator.org/guide/latest/exe_verilator.html) 与 [warnings](https://verilator.org/guide/latest/warnings.html)，2026-10-07 核对 latest 文档显示 5.052；实际安装版本未核对。它支持 lint-only，具体 warning 名称/选项按本地版本确认。

若已有可用 Verilator，在独立项目副本记录版本，再执行以下示例；不要求安装系统包或改 PATH：

```sh
verilator --version
verilator --lint-only -Wall --top-module spi_master lessons/01_spi_master/rtl/spi_master.sv
```

命令只是计划入口，未声明在当前环境运行成功。分别 elaborate 分频 1/3/25；参数覆盖语法按该版帮助核对。不要先全局关闭 warnings；记录 exit code 与完整诊断，决定修复或有限 waiver。

| 独立副本注入 | 运行前预测 | 修复依据 |
|---|---|---|
| 组合分支漏赋值 | 可能推断锁存，行为依赖旧值 | 默认赋值或完整覆盖，再查综合结构 |
| 符号/位宽不匹配 | 扩展、截断或比较改变 | 明确每个操作数类型与范围，极值整数 oracle |
| 未使用寄存器/常量分支 | 逻辑可能被裁剪 | 先查是否漏接功能，再解释有意优化 |
| 同一信号多个过程驱动 | 硬件拥有权不明确 | 将状态更新归一个明确过程 |

waiver 至少写 rule、文件/范围、原因、功能证据和复查条件。lint 无警告也不证明协议正确、CDC 安全或数值准确；编译成功不等于完成 lint。

## EXP-VERIFY-CONTRACT：先理解 SVA 的采样

把 `@(posedge clk)` 的并发断言理解为每个边沿先观察寄存器旧 Q。RTL 的非阻塞赋值在本沿稍后更新；本沿算出的输出一般在下一个断言采样点观察到。`|->` 在同一采样点检查，`|=>` 从下一采样点检查；`$past` 在首个采样点没有可靠历史，需 past-valid/复位保护。

以下是放在独立 checker 中的教学片段，端口连到 SPI。未编译或运行；先检查所用工具支持的 SVA 子集：

```systemverilog
// clk / rst_n / done / busy / cs_n / sclk / start 来自 DUT 接口。
a_done_one_cycle: assert property (@(posedge clk) done |=> !done);
a_done_released:  assert property (@(posedge clk) done |-> (cs_n && !busy));
// 同步低有效 reset 的本沿效果，在下一采样点观察。
a_sync_reset: assert property (@(posedge clk)
  !rst_n |=> (!busy && !done && cs_n && !sclk));
a_accept: assert property (@(posedge clk)
  (rst_n && start && !busy) |=> (busy && !cs_n));
```

这些只覆盖四条接口性质。busy-start 不改变已锁存 TX、八次采样与 RX 更新仍需要独立 ledger/scoreboard；不能误写 `busy && start |=> $stable(busy)`，因为合法完成可能恰好发生在该周期。

`disable iff (!rst_n)` 通常用于异步终止性质评估，不能直接解释成 DUT 同步复位的电路行为；必须另检同步复位输出、明确在途义务如何取消。TB 避开 DUT 活动边沿驱动，或采用明确 clocking/sampling 约定，避免竞争。

先在纸上标采样时刻，再分别注入“done 两周期”“done 时 CS 未释放”“reset 未取消 busy”，要求对应检查真的失败。当前 Icarus 环境不自动视为支持完整 SVA，可保留等价程序 monitor；迁移至支持工具再登记断言结果。

## 随机测试与覆盖闭环

先确定合法域：分频≥1、start 一周期、MISO 符合接口窗口；对 busy-start、复位中止等**允许但需拒绝/取消**的输入单列场景。模拟前提被破坏的测试另列 expected error，不用一个随机域混在一起。

场景采样于真实接受/完成/复位事件，而非“试图发送”。建议覆盖分频×结果（完成/取消）、TX 等价类、独立 RX、busy-start 所在阶段、reset 所在边界，以及有意义的交叉。全 256 TX 是已有基线，约束随机要补序列变化，不能替代它。

| 缺口 | 处置 | 关闭依据 |
|---|---|---|
| 未命中合法边界 | 定向用例，再调整随机分布 | 事件计数和 seed 可重放 |
| 约束排除了想验证的故障 | 拆合法与故障 sequence | 注入能触发 checker |
| 代码执行了但输出没检查 | 补 oracle / monitor | 已知错误必定失败 |
| 不可达或不适用 bin | 给出协议/参数依据，有限 waiver | 评审记录而非删除统计 |

记录 seed、参数、序列、源版本与覆盖缺口。若无 covergroup 工具，先用显式场景计数；此时不能宣称工具功能/代码覆盖达到 100%。UVM 按需要加入，当前不增加框架迁移成本。

## 小形式任务：assumptions 也是设计的一部分

从 depth=4 的同步 FIFO 或 SPI done 性质开始。声明 clock/reset 初始条件、合法输入与参数；将设计义务写 assert、环境契约写 assume、非空轨迹/关键事件写 cover。不要 assume “结果正确”或约束掉 full/empty、busy-start 等允许场景。

证明前先 cover 接受与完成，确认 reset 后能离开空闲；没有 start 的轨迹会让某些 implication 空洞通过。活性必须写清环境保证或有界截止；ready 永远不来时不能要求无条件成功。bound 内未找到反例属于有界结果；timeout/undetermined 不能写 proof PASS。

交付 property/harness、assumptions、工具/引擎版本、bound、cover witness、反例与结论范围。性质证明不等于 RTL↔网表 LEC，也不等于模拟 settling/MTBF/物理签核。

本页验收：用三种故障证明检查器有效，解释 SVA 与 NBA 观察点，关闭或解释覆盖缺口，能重放一个失败。实际记录使用 [日志模板](../learning_log/_template.md)，关联 [K05 与实验索引](../references/course_mapping.md)。
