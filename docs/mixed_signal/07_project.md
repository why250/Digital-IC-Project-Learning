# 结课项目：SPI 数模控制与前台校准

这是课程设计的教学规格，尚无已验证的新 RTL 实现。先完成 [中期 SPI 配置项目](../course/06_capstone.md)，再在独立实验目录扩展，保持第 01 课 Master 不变。

## 1. 目标与范围

主机经 SPI 配置模拟使能、12 位 DAC 码和校准目标；数字控制器管理 bias/reference 启动、8 位 trim 试探与稳定、ADC 测量和块平均，执行有限次数前台校准，提供成功、取消、故障与恢复状态。

首版所有功能寄存器使用 50 MHz clk，rst_n 同步低有效。ADC 响应和模拟状态可异步，但须遵守下面的保持/CDC 协议。门控、多电源与 DFT 作为独立扩展实验，先验证单时钟基本功能。

## 2. 模拟接口与教学预算

| 接口 | 方向/语义 | 条件 |
|---|---|---|
| bias_en | 输出，打开偏置 | 启动顺序第一步 |
| ref_en | 输出，打开参考 | 偏置最小等待及 ready 确认后开启 |
| analog_enable | 输出，允许模拟功能 | 依 ready 和模式管理；故障置 0 |
| trim_code[7:0] | 输出，unsigned 试探/有效码 | 寄存输出，只在更新状态改变 |
| bias_ready/ref_ready/trim_settled | 输入电平 | 源端维持到消费；同步后连续四周期有效才确认 |
| adc_req/id/version | 输出测量请求 | 一次只允许一个未决请求，跨域请求遵守保持/握手 |
| adc_req_ack | 输入请求确认 | 对端接受一次请求后保持确认，见四相协议 |
| adc_valid/data/id/version/invalid | 输入响应 | payload 在发布 valid 前稳定，保持到 ack；正确 CDC 捕获 |
| adc_ack | 输出响应确认 | 表示接收或明确丢弃，不能重复消费 |
| adc_reset_req/adc_reset_done | 复位握手 | 重建接口 epoch，确保旧响应已取消 |
| analog_fault | 输入保持的故障电平 | 被识别后故障优先；无时钟时的互锁需独立硬件 |
| quiet | 输出活动窗口 | acquisition 到响应处理期间禁止内部配置切换 |

异步数据遵循基础 mailbox 的稳定窗口要求，valid 不能是无约束窄脉冲。id 和 version 各为 unsigned16；有未决/迟到响应时不复用相同标识，取消与重启通过接口复位握手清空旧 epoch。物理 bundled-data 延迟约束仍要检查。

请求采用四相握手：本端保持 req/id/version→对端接收一次并置 req_ack→本端降 req→对端降 req_ack。响应也采用 valid/payload→ack→valid 降低→ack 降低的四相握手；本端对一次 valid 激活只消费一次。下个请求需前一响应完成、两组握手均回空闲；取消由 reset 握手清空两组状态。请求 id/version 在整次未决事务期间保持，不只在 req_ack 前保持。

| 参数 | clk 周期 | 名义时间 | 定义 |
|---|---:|---:|---|
| BIAS_MIN | 100 | 2 μs | bias_en 后最小等待 |
| BIAS_MAX | 10000 | 200 μs | 启动阶段截止 |
| REF_MIN | 250 | 5 μs | ref_en 后最小等待 |
| REF_MAX | 20000 | 400 μs | 启动阶段截止 |
| TRIM_MIN | 50 | 1 μs | trim_code 应用后最小等待 |
| TRIM_MAX | 500 | 10 μs | 包含 settled 确认的截止 |
| ACQ_MIN | 20 | 400 ns | conversion 前的 acquisition |
| RESPONSE_MAX | 200 | 4 μs | 请求发布到有效响应被捕获的截止，含 CDC |
| BLOCK_SAMPLES | 16 | — | 同一版本的有效样本数 |
| BLOCK_MAX | 16 | — | 每次校准允许的测量块上限 |
| CAL_MAX | 100000 | 2 ms | 接受校准到完成/错误的总截止 |

计时从控制动作的 clk 边沿开始，经过 N 个完整周期才满足 MIN；MAX 边沿仍未完成视为超时。超时与 ready/响应同截止边沿，超时优先。所有参数是教学假设，实际电路应重定预算和最快 clk 条件。

analog_ready 只有 bias/reference 有效、当前 trim 最小等待和 settled 确认均完成、使能有效、无故障时为 1；试探码更新后重新失效。只有 analog_ready 且静默窗口已建立才允许 ADC 请求。

## 3. SPI 与寄存器

沿用中期项目的 Mode 0、最大 1 MHz、24 位帧和输入稳定窗口，以及地址 00–06。扩展地址见下表；多字节写入仍只在完整合法帧结束后接受。校准忙时原有 COMMIT 拒绝并置 busy_reject，shadow 可继续写，不影响本次锁存参数。

| 地址/十六进制 | 名称 | 属性与含义 | 复位 |
|---|---|---|---:|
| 10 | CAL_CONTROL | W1P，读 0；bit0 start、bit1 abort、bit2 rearm、bit3 手动 trim commit | 0 |
| 11 | TARGET_SHADOW | RW，signed16/F0，合法 −2048…2047 ADC LSB | 0 |
| 12 | TRIM_SHADOW | RW，unsigned8；高八位写 0 | 128 |
| 13 | CAL_CLEAR | W1C；对应 STATUS 的 bits 2、3、4、5、7 | 0 |
| 14 | CAL_STATUS | RO，位定义见下文 | 0，随后按接口启动状态更新 |
| 15 | COMMITTED_TRIM | RO，最近成功应用的手动/校准码 | 128 |
| 16 | TRIAL_TRIM | RO，最近应用的试探码 | 128 |
| 17 | LAST_MEAN | RO，signed16/F0，最近完整块的舍入均值 | 0 |
| 18 | ERROR_CODE | RO，最近失败原因；清 error_sticky 时清零，无新错才有效 | 0 |
| 19 | CONFIG_VERSION | RO，当前 trim 应用版本，unsigned16 | 0 |
| 1A | LAST_MEAN_VERSION | RO，LAST_MEAN 对应版本 | 0 |
| 1B | ADC_DROPPED | RO，旧/重复 id/version 响应的饱和计数，unsigned16 | 0 |

STATUS：bit0 analog_ready、bit1 cal_busy、bit2 done_sticky、bit3 error_sticky、bit4 abort_sticky、bit5 fault_sticky、bit6 adc_link_ready、bit7 reject_sticky、bit8 last_mean_valid、bit9 update_busy；其他位读 0。

CAL_CONTROL 为单命令：0 无操作，四个命令位只允许其中一个为 1；多位或保留位非零为非法帧。start 要求 analog_ready、adc_link_ready、无 cal/update busy；否则拒绝并置 reject_sticky。abort 在忙时取消，空闲时无操作。rearm 只在故障输入已解除且可进行恢复时有效，不自动清诊断 sticky 位。

手动 trim commit 锁存 TRIM_SHADOW，仅在空闲、ready 且无未决 ADC/配置操作时接受；应用、稳定完成后更新 COMMITTED_TRIM。手动应用完成不表示经过校准精度验证，不置 cal_done。update_busy 覆盖手动更新和恢复过程。

TARGET_SHADOW 使用全部 16 位补码表达合法 signed12 范围；上层不能把负数的符号扩展位当作非法保留位。非法写、RO 写等沿用 frame_error。读值在命令解析时取整字快照。

新错优先于 W1C；fault 输入仍有效时不能通过清位让 fault_sticky 维持为 0。开始新校准清 last_mean_valid 和当前块状态，旧诊断 sticky 位保持，成功/失败也需要主机显式清位。

## 4. 上电、故障与响应 epoch

原配置 ACTIVE_ENABLE 请求开启模拟单元，sequencer 按 OFF→BIAS_WAIT→REF_WAIT→TRIM_WAIT→READY 推进；原 ACTIVE_CODE 仍为独立 12 位 DAC 配置，trim_code 是另一路 8 位校准控制。

fault、启动超时或 ADC 链路无法清理时进入 FAULT：停止新转换、analog_enable/ref_en/bias_en 置 0、analog_ready=0，禁止正常配置应用，保留 committed 与诊断。物理关断是否需要先后等待须由真实电路补充，当前教学模型接受此输出策略。

冷复位、取消存在未决响应或故障时，发 adc_reset_req 并要求对端清空请求/响应、返回 adc_reset_done=1；本端随后释放 req，并等待 done=0 完成四相握手，才置 adc_link_ready。故障未解除时保持禁止操作。若 ADC 时钟停止，链路未就绪且不发新请求，不能把 id 清零后立即重新使用。

rearm 在故障解除后显式重建接口和重走启动过程；恢复失败再次记错，不自动无界重试。同步故障响应只在 clk 工作时保证功能行为，时钟/电源失效的立即安全关断是独立数模接口要求。

## 5. 校准算法与拥有权

start 接受时锁存 target、原 committed 和配置版本。校准拥有 trim 输出，正常 ADC 消费者暂停；手动 trim/普通 active commit 拒绝，影子写不影响本次算法。

默认模型 `y=offset+gain×(code−128)+noise`，gain 为正，输出量化到 signed12。先测端点确认可达性和方向；采用单调搜索缩小区间，保留合法候选；候选判断基于 16 个有效样本的精确累加及 ties-to-even 平均。

单调性是电路/教学模型的前提，端点检查不能独自证明全码单调；独立模拟码扫描或电路规格提供该前提。额外发现顺序不一致时可报 code=7，不宣称控制器能检测任意非单调情况。

每次测量块之前应用候选、增加 CONFIG_VERSION、等待 TRIM_MIN 和 settled，随后收同一版本样本。任何 invalid/超量程响应导致本次测量失败，重复/旧 id 不计入平均并记录诊断；无法完成有效块受总 watchdog 限制。

数字成功标准为最终候选两个连续测量块 |mean−target|≤2 ADC LSB。成功时将候选保存为 committed，确保当前码稳定，cal_busy 清零、done_sticky 置位，并发一周期 cal_done。该标准不直接保证真实模拟误差也是 ±2 LSB。

失败/abort 不改变旧 committed。模拟条件仍有效时恢复旧码并等待稳定；不能恢复则进入 FAULT 且使能关闭。超时、块数耗尽、范围/单调前提失败、invalid 响应和无法确认各有错误码。abort 置 abort_sticky，不置 done_sticky；错误置 error_sticky，不发 cal_done。

ERROR_CODE：0 无错；1 bias 超时；2 reference 超时；3 trim 稳定超时；4 ADC 响应超时；5 invalid/超量程样本；6 目标不可达；7 单调前提不成立；8 候选确认失败；9 测量块耗尽；10 总校准超时；11 恢复/接口重建失败；12 analog_fault。一次流程保留第一致命原因，恢复失败通过 FAULT 表示，除非原来无错误才写 code=11。旧/重复响应被明确丢弃并增加 ADC_DROPPED，不单独使校准立即失败，但等待正确响应仍受 watchdog 限制。

cal_busy 持续到本次正常成功或必要恢复结束；FAULT 时可终结本次校准并清 busy，但 analog_ready 保持 0。外部链路重新可用之前不接受新测量。

## 6. 预算练习

假设每样本还需最多 10 周期状态/确认开销，每块决策最多 10 周期，则粗预算为：

```text
16 块 × [500 settling + 16×(20 acquisition + 200 response + 10 overhead)
          + 10 decision] = 67040 周期 = 1.3408 ms
```

2 ms 总截止为其他状态和恢复留空间。最终实现需统计全部路径；本式不是已运行的最坏执行时间证明。起始时必须已 READY，因此启动的 BIAS/REF_MAX 不包含在此校准预算内。

## 7. 验收矩阵

| 类别 | 必测序列 | 检查 |
|---|---|---|
| 启动 | ready 早/晚/缺失/抖动 | 顺序、MIN/MAX、四周期确认 |
| 请求 | 空闲/忙时 start，busy 写 target | 接受次数与参数快照 |
| 算术 | signed 极值、正负 tie、平均和边界 | 精确整数参考模型 |
| 测量 | 早/晚/重复/旧 id/version、invalid | 不混块、不重复消费、有限等待 |
| 搜索 | 正 gain、范围外、零/负 gain、饱和 | 正确成功或明确失败 |
| 噪声 | 无噪声、有界噪声、相关漂移 | 数字成功判据及证据边界 |
| 拥有权 | 校准中 commit/手动 trim | 无两个来源争用输出 |
| 异常 | 每状态 abort/fault/timeout | 结果失效、恢复或关断 |
| 截止 | response 与 timeout 同周期 | 超时优先 |
| epoch | abort 后迟到、ADC 停钟、恢复 | 不误匹配新请求 |
| 状态 | W1C 与新错、读状态期间变化 | 新事件优先、整字快照 |
| 更新 | settling/quiet 中新请求 | 不提前测量或无声覆盖 |
| 复位 | 启动/采样/搜索/恢复中 reset | 默认输出、链路重建、可恢复 |

PVT 与噪声参数范围用教学矩阵标注，实际硅片性能另需测量/电路仿真。完成模块和顶层仿真后运行新项目自己的综合流程，审查未映射、时钟、结构、max/min 和外部协议假设。物理、AMS、UPF、DFT、形式流程未执行则保持未执行。

## 8. 学习交付

提交接口/寄存器规格、架构与状态图、数值格式和误差预算、独立 RTL/testbench、模型参数、性质和覆盖、故障复现与恢复、综合/约束解释。波形和报告放 results，记录位置与版本。

评审必须回答：何时允许测量？样本属于哪个码？校准成功证明了什么？取消后旧结果如何处理？时钟/电源失效由谁保障安全？已验证数字逻辑与尚未验证的真实模拟条件分别是什么？
