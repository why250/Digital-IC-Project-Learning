# ADC 架构中的数字模块（AD01–AD04）

## AD01：先画控制、数据和时钟

### 讲解

ADC 数字部分不仅是输出滤波：SAR 需要试探码和比较决策；Flash 需要编码与错误处理；Pipeline 需要级间对齐和冗余校正；ΔΣ 可有反馈编码/DEM；TI-ADC 需要相位控制、通道重排和失配校准。

每个模块先写四张表：时钟/复位域、控制事件、数值编码、数据有效性。sample_req 不等于结果有效；conversion_done 不等于模拟输入仍与当前配置一致。样本标签由采样/保持事件分配，不由结果返回时才分配。

量化码采用补码、offset binary 或无符号时，比较/累加/饱和语义不同。温度计码、one-hot 和二进制码也不能只看总线位宽混用。模拟接口还要定义 acquire、DAC settling、comparator response 和违例行为。

### 练习与验收

为一个已有 ADC 架构列出至少五个数字模块和各自接口；将模拟采样时刻与数据到达时刻分开。验收要求每份输出都能追溯输入样本、通道及配置。

## AD02：SAR 控制器

### 讲解

同步教学流程为 ACQUIRE→APPLY_TRIAL→WAIT_DAC→WAIT_COMPARE→DECIDE→NEXT_BIT→DONE。每次先设当前 bit，保持试探 DAC 码直到稳定、比较结果有效，再决定保留或清除，从 MSB 向 LSB 推进。

comparator 有效性是协议的一部分；异步 ready/结果需可靠捕获。亚稳态、动态比较器 reset/evaluate、非重叠相位和 switch settling 不是 RTL 中一个 `#delay` 可以实现的物理保证。异步 SAR 是后续独立架构，不将同步 FSM 结果直接移植。

示例10位无符号SAR，定义比较阈值code×Vref/1024，Vin=677.4 LSB。trial依次512、768、640、704、672、688、680、676、678、677，最终结果677=0x2A5。这个教学量化定义取floor，不与其他ADC模型的nearest量化混用。

如果一bit预算含DAC/比较等40ns，10bit至少400ns，另加acquisition、初始化、输出和接口开销；不能仅看10次状态转移就认定吞吐。传输中reset/abort不发正常完成，比较超时保留诊断。

### 练习与验收

手算上述十次decision，再实现小位数同步SAR控制与独立DAC/comparator模型。测试端点、比较迟到、reset和busy-start。验收要求决策只用对应trial的有效比较，且结果不混入下一次转换。

## AD03：Flash 编码与 bubble

### 讲解

理想阈值有序时形成111…000温度计码，再编码为二进制。真实比较器可能有offset、延迟差、metastability和bubble；简单popcount与priority encoder处理非法码时行为不同，需要按架构定义。

局部三点majority可修复特定孤立bubble，但不保证任意错误都正确。靠近真实transition的bubble可能移动边界；连续多位错误、阈值乱序或X必须按错误模型处理。

例如理想1111111100000000，远离transition翻一位为1110111100000000，三点majority可恢复原边界。若错误紧邻transition，仅知道当前码可能不足以唯一推断真实输入。

### 练习与验收

枚举理想码、内部孤立bubble、边界错误和双bubble，写明算法能修复和只能报错的情况。编码器组合路径可能很深，注册分组/流水增加延迟时要对齐valid。验收要求不把“修一个例子”说成通用metastability修复。

## AD04：Pipeline 冗余校正

### 讲解

以归一化教学residue `r[k+1]=2r[k]−d[k]`、d∈{−1,0,+1}为例：`r0=sum(d[k]/2^(k+1))+rK/2^K`。数字组合按权重还原，前提是每级residue/decision属于同一输入样本。

冗余允许不同decision在残差仍合法时表示同一输入，例如阈值误差未导致residue超量程；数字carry/符号处理可以合并重叠区。它不自动补偿有限增益、非线性settling、电容失配或已饱和残差。

例r0=0.8，d=[1,1,0,1]，r4=−0.2，则0.5+0.25+0+0.0625−0.0125=0.8。符号和移位需要明确定点格式。

各stage latency不同，前级decision要经过延迟寄存器后与后级对应sample_id合并；不能用当前stage1码加上一拍前stage2码。

### 练习与验收

推导权重并用两组合法冗余decision验证相同输入；注入标签错位和residue clipping。验收要求区分数字冗余可纠正的决策误差与必须建模/校准的模拟误差。
