# K06/K07：受控架构比较与 MMMC 场景

接 [07–10 综合/STA/SDC](../course/02_synth_sta.md) 和 [19–22 物理时序](../course/05_physical.md)。这些基础已有覆盖；本页补比较设计与场景表，**尚未执行 EXP-FIXED-PPA 或 EXP-SDC-HOLD**。流程方法参考 [Cornell](../references/cornell_ece5745.md)，实际命令按已安装工具文档核对。

## EXP-FIXED-PPA：先固定“做了同一件事”

基线用已有 [adc_fixed_correct](../../lessons/adc_digital/rtl/adc_fixed_correct.sv)。在独立副本选一个改动：拆乘加流水，或共享算术单元；不同时换库、频率、精度和接口。先预测新增 FF、关键组合路径、最大可接受速率、latency 和活动变化。

冻结输入/系数范围、精确整数运算、RNE/饱和规则、tag/version/flush、吞吐要求。流水可改变延迟，但 reference 必须按样本身份匹配，不能以“延迟一拍”掩盖丢样或用错系数。共享资源要验证最坏时刻是否赶得上每个 sample deadline。

| 受控因素 | 需要记录 | 比较如何成立 |
|---|---|---|
| 数值与协议 | oracle、位宽、吞吐/latency、复位/flush | bit-accurate 与接受/输出计数一致 |
| 综合条件 | 工具版本/选项、库/角、SDC、slew/load | 基线与替代同条件，改动单独说明 |
| 面积与时序 | 单位、FF/组合单元、最差路径、WNS/TNS、未约束项 | 看代价和路径变化，不只看一个 slack |
| 物理条件 | 利用率、floorplan、RC、时钟与 seed | 有真实结果后再比较；逻辑面积不冒充版图面积 |
| 功耗 | 电压、频率、活动文件、标注率、idle/active | 同 workload；默认 toggle 估算单独标记 |

增加流水可能增加时钟负载与功耗；共享资源可能降低单元数却增加 mux/控制和切换。先回归，再综合；若修改已有设计，执行其完整验证契约。当前只新增实验说明。

## EXP-SDC-HOLD：max 与 min 各有物理来源

保持原 SPI 教学 SDC 不变，在独立实验中分别变化输入 min/max、uncertainty 和时钟模型，先手算再对报告。令 skew=`capture clock arrival − launch clock arrival`，概念性的同周期寄存器路径：

```text
setup slack = T + skew − setup − U_setup − (t_cq,max + d_max)
hold  slack = t_cq,min + d_min − (skew + hold + U_hold)
```

正 skew 帮助 setup、恶化 hold。在给定教学数字 T=2 ns、skew=0.1 ns、setup=0.1 ns、U_setup=0.1 ns、t_cq,max=0.2 ns、d_max=1.2 ns 时，setup slack=0.5 ns。若 hold=0.05 ns、U_hold=0.02 ns、t_cq,min=0.05 ns、d_min=0.08 ns，hold slack=−0.04 ns。把 T 加倍不改变这个 hold 算例；把 d_min 增加 0.06 ns 得到 hold=0.02 ns，但也需复查新增延迟对 setup 的影响。

上述是给定参数计算，实际工具还涉及具体边沿、derate、CRPR、时钟相关性与库弧。不能随意把同一个 uncertainty 加两次或把 input transition 当 uncertainty。

输入 min/max 来自外部设备 clock-to-output、互连和相对时钟；输出约束来自接收端 setup/hold 与互连。SPI MISO 由内部 clk 采样，不能直接套端口 SCLK 的时钟而不对齐真实捕获结构。例外要有协议依据与覆盖审计，不能用 false path 隐藏真问题。

## MMMC：先设计可解释的场景

MMMC 把功能模式、库/电压/温度、RC、时钟和例外配成 analysis views。setup 的最坏角不一定总是“最慢”，hold 也不一定固定“最快”；应由真实库/RC/温度反转与路径分析决定。

| 场景（计划） | 模式 / clock | cell / RC 数据 | 约束与检查 |
|---|---|---|---|
| FUNC-SETUP | 正常运行、真实输入输出预算 | 经确认的 max 分析库与 RC 组合 | setup、恢复/移除等适用检查；每个端点约束来源 |
| FUNC-HOLD | 同一功能契约 | 经确认的 min 分析库与 RC 组合 | hold、CDC 接口约束；不能复制 max 报告 |
| TEST-SHIFT | 仅当 scan 已实现；测试时钟/拥有权 | 适用测试角与 RC | shift 时序、模拟安全输出/隔离 |
| TEST-CAPTURE | 对应真实 capture 模式 | 适用角与 RC | capture clock、功能路径/测试例外 |
| LOW-POWER | 仅当门控/电源域实际实现 | 支持该状态的库/电源数据 | 门控检查、唤醒、隔离/保持/电平转换 |

这些是表设计，不是已配置的 Genus/Innovus view。第一课只有单 clk、无 scan/多电源，不能为完整表格虚构 test/low-power 场景。tutorial.lib 单一教学角不足以建立真实多角结论。

每个场景交付名称、mode、clock/reset、库与 RC 版本、约束文件、例外理由、ideal/propagated clock、提取阶段和未约束项。比较 CTS/route 前后报告时先对齐场景与路径，别把场景切换造成的差异归给布线。

验收：手算两类 slack、写每条约束来源、评审场景适用性、用同条件 PPA 表解释一个架构取舍。工具 evidence 未获得时明确留空。记录在 [日志](../learning_log/README.md)，工程执行结果再进入 [progress](../progress.md)。
