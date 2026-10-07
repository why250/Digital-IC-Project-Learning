# AM04：SAR 控制、DAC、比较器与逐块视图替换

SAR 的每一位决定依赖模拟电压已建立、比较结果已有效。你熟悉 DAC 和比较器，本课重点是把其建立时间、判决延迟和负载变成数字控制的条件。

前置 AM03、[AD 架构讲义](../adc_digital/01_architectures.md)。[总纲](00_course.md) · [设置](07_setup.md) · [答案 AM04](09_answers.md#am04) · [记录](10_workbook.md)。预计 12–18 小时。

## 小系统规格

- 单 clk=50 MHz、同步低有效 rst_n，start 为一拍；busy 时忽略 start。
- unsigned 10 bit SAR，Vref=2 V，DAC trial 电压 `2 V×trial/1024`，LSB=1.953125 mV。
- 输入在接受 start 前已完成 acquisition，首版理想 sample/hold 将 Vin 保持整个转换；不要把变化中的 Vin 直接送给十次比较并期待静态 floor 结果。
- `cmp_ge=1` 表示保持的 Vin≥Vdac。相等时保留 trial，结果对应 floor/clip；理想 equality 是模型约定。
- 首版 DAC 为理想源＋10 kΩ/10 pF 低通；cmp 为理想差分判决加明确响应延迟。同步适配器只在当前 cmp_req 合法窗口取值，并锁存该值。

控制状态为 ACQUIRE（顶层）→APPLY_TRIAL→WAIT_DAC→WAIT_COMPARE→DECIDE→NEXT_BIT→DONE。MSB 先试；cmp_ge 时保留当前位，否则清除；最后一次判决后发布结果。这里每个状态可以多拍，也可在 RTL 中合并；必须画出实际实现的边沿表。

## 复用现有 RTL 的边界

已有 [sar_controller.sv](../../lessons/adc_digital/rtl/sar_controller.sv) 提供 `clk/rst_n/start`、`cmp_valid/cmp_ge`、`trial/result`、`busy/done/error` 与 `cmp_req`。参数 BITS、SETTLE、TIMEOUT 必须 ≥1。其 cmp_req 在 COMP_WAIT 状态保持高，响应需要教学适配器；该 RTL 未包含 acquisition、异步 CDC 或 trial_id。

该实现从 APPLY 更新 trial 后，经过 SETTLE 拍 DAC_WAIT 才进入 COMP_WAIT。标称一阶 RC 可用 SETTLE=39（780 ns）做探索；最坏教学角落用55。比较器适配器示例选择同步有效延迟3拍，TIMEOUT=8，然后从波形确认真实计数关系。RTL 当前在同一 COMP_WAIT 边沿先检查 cmp_valid，再检查超时，所以截止边沿同时 valid 会接受；AM05 的校准项目另用“timeout 优先”。不得把两者写成同一规则。

首版限定同步比较应答：每个请求只产生一个、只属于当前 trial 的 valid 脉冲，reset/error 后适配器清除待返回应答。要接异步比较器，新增保持/确认与身份隔离适配器，再跑独立协议测试；不能只接一条裸 E2L 输出来代替结果有效信号。

## 先手算十次比较

Vin=677.4 LSB=1.323046875 V。写出十个 trial：512、768、640、704、672、688、680、676、678、677；逐次记录 DAC 目标、比较结果、kept 值，最终677。

理想 floor 参考只是首层 oracle。含有限 settling 时，判决是否一致取决于 Vin 距当前比较门限的裕量；AM03 的半 LSB 条件不能保证所有 Vin 的 floor 码完全一致。677.4 LSB 的最小门限裕量为0.4 LSB，先检验残差；扫 threshold±ε 时逐项降低 RC 误差与数值误差，或报告边界不确定区。

## 实验步骤

1. **纯数字基准。** 用零延迟理想 DAC 数值与同步比较应答得到预期 trial 台账，先运行已有 AD 测试或检查既有结果，不把它登记为新的 AMS 结果。
2. **全行为 AMS。** config 中绑定 SAR RTL、sample/hold 行为、RC DAC 和比较器行为。保存 Vin_hold、trial、Vdac、cmp_req、sample_event、cmp_ge、valid、result 和 done/error。
3. **等待扫描。** SETTLE=1/5/39/55，检查相同输入下出错的第一位。独立监视器对每次 sample_event 比较 Vin_hold 与当时模拟 Vdac，定位等待不足，而不是只看最终码。
4. **边界扫描。** 测0、接近满量程、超量程、677.4 LSB，若干 `k±0.1 LSB`、恰好k LSB，以及保持期间输入源变化。外部源变化不应改变理想 held input；真实 S/H droop 另做实验。
5. **比较器替换。** 只将 cmp 实例绑定 transistor schematic，保留行为 DAC。定义输入共模、reset/evaluate、输出供电、E2L 阈值、有效信号获取方式和最大判决时间。动态比较器输出翻转不必然表示该次判决已有效，不能把 X 硬转0继续。
6. **DAC 替换。** 恢复行为 cmp，再单独替换 DAC，加入实际开关/负载/寄生或可用提取视图。核对参考端负载、输出极性、量程和建立时间，然后才组合两种替换。

transistor/提取步骤依赖你的可用 PDK、模型和电路。没有数据时完成接口和替换计划，记录“待电路”，不制造虚假结果。不同 view 使用相同逻辑功能端口；需要 level shifter 或 comparator clock 时显式引入适配层。

## 故障与验收

注入 never-valid、迟到旧比较应答、busy-start、转换中复位、比较器 polarity 反接和模拟未建立。同步首版需检测 error/done 一拍、result 仅成功时更新；异步扩展必须验证旧 trial 不能污染下一位。

提交：十次手算与实际比较台账、非边界输入码检查、门限附近的不确定区、每次视图替换的延迟/负载/码变化。检查延迟增加时先错哪位、offset 如何移动转换门限，以及只加 maxstep 精度为何不能补救不够的真实等待。

完成目标是一个小 SAR 验证案例。晶体管级噪声、亚稳态、kickback、参考扰动、DNL/INL 需要对应统计/电路测试；本课理想 floor 验证不自动覆盖这些性能。
### AM04 参考与实验

- **选读与定位**：K03/K17/K19 · Own SAR 联验；P FSM 方法：[EECS151 ASIC Lab 3：FSM Style Guide](https://eecs151.org/asic/lab3/docs/fsm-style-guide/)。来源/边界：[B151-F26](../references/berkeley_eecs151.md)。
- **带着问题读**：借状态/输出拥有权，SAR 每位 WAIT_SETTLE/decision 的模拟条件依自己的电路。
- **回到本课做**：AMS SAR 练习：在逐块 view 替换前预测 trial→settled→decision；先数字模型，再 DAC/比较器电路。
- **留下证据**：每位 decision 台账、逐实例绑定与行为/电路差异表。将预测、实际观察和结论写入 [本方向学习表](10_workbook.md)；公开资料引起的理解变化用 [学习日志模板](../learning_log/_template.md) 记录。
