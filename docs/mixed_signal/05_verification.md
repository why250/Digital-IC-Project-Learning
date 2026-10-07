# 专项五：性质、行为模型与故障验证（41–44）

目标：在实现控制器前就知道如何发现错误。数字行为模型只验证声明的抽象，模拟稳定性、亚稳态概率和供电完整性需要其他证据。

## 41：用不变量约束控制器

### 讲解

不变量表达所有合法序列都要满足的条件；例如 sampling→analog_ready，busy→不接受第二个 start，sample_accept→id/version 匹配，fault→禁止新 conversion，cal_success→最终确认通过。

安全性质说明不能发生什么，例如不能使用旧样本；活性性质说明在外部条件满足时最终发生什么，例如 ready 与响应在期限内到来后校准有限结束。若外部永久不响应，应该要求 timeout/FAULT，而不是无限期要求成功。

程序监视器可检查每个周期的状态和计数。Icarus 对完整 SVA/形式流程支持有限，本课可以用普通 SystemVerilog `if (...) $fatal`、独立计数器和超时；不因为讲义写了性质就宣称完成形式证明。

采样调度要避免竞态：刺激在合适的非采样时刻变化；检查要区分边沿前接受条件和边沿后输出。将 DUT 内部状态原样复制到 reference model 会共享错误，应从接口事件维护参考状态。

### 41 参考与实验

- **选读与定位**：K05 · P 首选：[EECS151 ASIC Lab 4：Formal Verification](https://eecs151.org/asic/lab4/docs/pg3-formal/)。来源/边界：[B151-F26](../references/berkeley_eecs151.md)。
- **带着问题读**：只读 assert/assume/cover、可达性与复位；证明条件不能排除本来允许的故障。
- **回到本课做**：EXP-VERIFY-CONTRACT：十条不变量各配一个违反它的注入，先程序 monitor，再按 K05 补充评审 SVA。
- **留下证据**：property/assumption/cover 表、故障检测证据与 vacuity 检查；formal 未运行时留空。将预测、实际观察和结论写入 [本方向学习表](09_workbook.md)；公开资料引起的理解变化用 [学习日志模板](../learning_log/_template.md) 记录。

### 练习与验收

为结课项目写至少十条性质，并给每条一个能违反它的故障。注入“settling 提前结束”“旧 id 被接受”“busy-start 覆盖 target”等错误，确认监视器实际失败。验收要求性质有明确观察点和复位例外。

## 42：构造可控的模拟行为模型

### 讲解

模型分成 bias/reference ready、trim plant、settling 和 ADC 响应。ready 可以早/晚/抖动/缺失；trim 改变后标记一段时间无效；ADC 在 request 后经过可变延迟返回量化样本，并保持 valid/data/id 到 ack。

plant 可用有符号整数或 testbench 的 real 运算表达，再明确量化、饱和与噪声。real 仅用于仿真参考，不写进普通可综合控制器来代替定点硬件。

模拟模型必须能拒绝不合法请求：未 ready、settling 中、已有未确认响应时不接受新请求，并让测试失败或返回明确 invalid。若模型始终立刻返回理想值，会把控制器过早采样的问题隐藏起来。

随机测试有固定 seed，失败记录 seed、参数和输入序列。模型的 ready 与 DUT 等待计数不能用同一个内部变量驱动；采用独立时序参数才有机会发现 off-by-one。

### 42 参考与实验

- **选读与定位**：K05/K13 · Own 模拟模型；P TB 方法：[EECS151 ASIC Lab 2：Testbenches](https://eecs151.org/asic/lab2/docs/pg3-testbenches/)。来源/边界：[B151-F26](../references/berkeley_eecs151.md)。
- **带着问题读**：只借 DUT、stimulus、oracle 的分离；ready/settling/ADC 模型参数不共用 DUT 的计数。
- **回到本课做**：测量模型练习：独立构造四组件，故意把等待缩短一拍，预测模型如何拒绝早采样。
- **留下证据**：模型接口图、非法请求台账和未建模的模拟效应。将预测、实际观察和结论写入 [本方向学习表](09_workbook.md)；公开资料引起的理解变化用 [学习日志模板](../learning_log/_template.md) 记录。

### 练习与验收

实现四个独立模型组件，分别验证正常和错误请求。确认将 DUT 的等待少写一周期时，模型/监视器能发现。验收要求明确哪些模拟非理想性没有建模，例如真实 RC、毛刺幅度、相关噪声频谱和连续时间环路。

## 43：参数扫描与故障矩阵

### 讲解

数字参数扫描覆盖延迟和接口变化：clk 相位/周期、ready 时刻、settling、转换响应、CDC 时钟关系、offset/gain、噪声、饱和和故障。每个参数范围标“器件规格”或“教学假设”。

行为模型的 slow/fast 参数代表假设场景，不是读取工艺库后的真实 PVT 仿真。PVT 还会影响数字 t_cq、slew、互连和亚稳态特性，这些由库、STA 与物理实现分析。

用等价类和边界优先减少测试规模：N−1/N/N+1 时刻，最小/最大码，零/正/负误差，合法/非法 id，噪声界限，故障与完成同周期。随机回归补充序列变化，不能取代确定性边界用例。

电路前提被破坏时要验证“正确失败”，例如非单调 plant、增益为零、参考不 ready、ADC clipping。不能要求任意异常场景仍校准成功。

### 43 参考与实验

- **选读与定位**：K05 · P 首选：[EECS151 ASIC Lab 4：Coverage](https://eecs151.org/asic/lab4/docs/pg1-coverage/)。来源/边界：[B151-F26](../references/berkeley_eecs151.md)。
- **带着问题读**：选场景/交叉覆盖，让参数边界与故障分类决定测试，而非随机次数决定完成。
- **回到本课做**：EXP-VERIFY-CONTRACT：N−1/N/N+1 定向边界后加入固定 seed 随机序列，重放一次失败。
- **留下证据**：合法域/故障域分开的矩阵、seed/参数与覆盖缺口处置。将预测、实际观察和结论写入 [本方向学习表](09_workbook.md)；公开资料引起的理解变化用 [学习日志模板](../learning_log/_template.md) 记录。

### 练习与验收

写矩阵并区分预期 success、error、abort、FAULT 和不在契约内的输入。至少重放一次随机失败。验收要求失败原因可定位到协议、运算、模型前提或实现，而不是统一归为“收敛不好”。

## 44：集成、覆盖与证据

### 讲解

先独立验证 sequencer、measurement、average、search controller，再整合 SPI 寄存器与控制器。集成还要检查模式/状态副作用：busy 中写 shadow、故障时读状态、abort 后迟到结果、清错与新错同周期。

计分板记录开始时快照、每个已接受样本的 id/版本、校准结果和最终 committed 码。结果判定以接口契约与独立 plant 为依据，不复制 DUT 的二分分支来判定自己。

功能覆盖记录状态/分支/异常是否被触发，代码覆盖记录实现是否被执行，二者不互相替代。当前已启用的工具没有完整覆盖系统时，可以用显式计数和事件矩阵，记录未覆盖项。

交付源版本、参数、seed、命令、退出码、完成标记和证据位置。RTL 仿真与综合分别验证不同方面；新项目也需要自己的 runner、映射检查和时序意图审查，不能借第一课的 PASS 标记算通过。

### 44 参考与实验

- **选读与定位**：K05 · P 首选：[EECS151 ASIC Lab 4：Coverage](https://eecs151.org/asic/lab4/docs/pg1-coverage/)。来源/边界：[B151-F26](../references/berkeley_eecs151.md)。
- **带着问题读**：区别代码覆盖、功能覆盖与 assertion 命中；100% 行覆盖为何仍可能漏掉旧 id？
- **回到本课做**：EXP-VERIFY-CONTRACT：将模块回归与顶层 id/version/应用计数联结，注入共享错误验证 oracle 独立性。
- **留下证据**：覆盖闭环表、计数守恒、失败/恢复和证据 manifest。将预测、实际观察和结论写入 [本方向学习表](09_workbook.md)；公开资料引起的理解变化用 [学习日志模板](../learning_log/_template.md) 记录。

### 练习与验收

完成一次模块到顶层的回归，证明 count、sample 数、应用次数和错误次数一致。提出三项未被当前模型验证的真实电路风险。验收要求能够重现成功与失败两类结果。

## 验证深度的下一步

已有安全/活性、独立模型与事件矩阵继续复用。[K05 补充](../practice/verification.md) 增加 lint/SVA 采样、约束随机/覆盖缺口处置及小形式任务。模拟模型假设仍属于项目契约，形式假设不能排除允许的故障。新工具结果待实际执行。
