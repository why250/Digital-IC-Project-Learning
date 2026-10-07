# K10/K12：物理检查、IO 与测试证据

接 [19–22 物理基础](../course/05_physical.md) 和 [47–48 DFT/交付](../mixed_signal/06_implementation.md)。参考 [Cornell 后端方法](https://cornell-ece5745.github.io/ece5745-S02-back-end/) 与 [Berkeley Lab 4 signoff](https://eecs151.org/asic/lab4/docs/pg4-signoff/)。**本项目尚无 P&R、独立 DRC/LVS 或 scan/ATPG 实跑结果。**

## EXP-ASIC-IMPLEMENT：不同检查回答不同问题

| 检查 | 要回答的问题 | 所需输入 / 结论边界 |
|---|---|---|
| 导入与连接检查 | 实例/引脚/供电是否解析？ | 网表、匹配库/LEF/技术文件、power intent；不代表功能正确 |
| P&R DRV | 当前实现模型下 slew/cap/fanout 等是否合规？ | 库限制与实际场景；不等于版图几何 DRC |
| 实现工具几何检查 | 路由有无可检测的短路/间距等问题？ | 实现规则；不必然等价 signoff deck |
| 独立 DRC | 版图是否满足指定规则集？ | GDS/OASIS、规则 deck、版本/层映射；只覆盖该 deck |
| LVS | 从版图提取的连接/器件是否匹配参考？ | 版图、提取规则、CDL/SPICE/参考网表和宏视图 |
| 提取后 STA | 指定角/模式下 setup/hold 是否满足？ | 匹配寄生/库/SDC/时钟模型；不覆盖未建模接口 |
| IR/EM 与功耗 | 活动下供电/电流/功耗是否满足需求？ | 授权模型、活动、供电网络、角；DRC/LVS 通过不回答这些问题 |

全流程先审查数据闭合：教学 Liberty 只有逻辑/时序信息，不能由它自动得到物理尺寸、层规则、宏版图或提取 deck。Genus/Innovus 可执行文件存在，也不能据此标流程可用。

## 分阶段证据包

从自己的小控制模块选一个实验，核对库数据后按 synth→floorplan→place→CTS→route→提取/STA 推进。每阶段记录源/网表/库版本、约束、完成标记与 exit、未映射/未约束项、utilization、拥塞、cell/net delay、时钟插入延迟/skew、setup/hold。没有生成的阶段不能用预计报告填上。

DRC/LVS 单独记录实际检查器、deck/参考版本、top、宏/IO/供电、层映射、错误分类和修复；修复后重查相关 STA/连接，必要时回归功能。保存自己的摘要与假设，完整报告和专有数据留 results。

缺宏 CDL/版图时不得静默 blackbox 后写“全芯片 LVS PASS”；需要列出 blackbox 对象、原因、外部证据与未覆盖连接。waiver 指向具体规则/位置、理由和审批来源，不能仅因错误难修就忽略。公开 lab 的教学规则范围和工具示例也不升级为工业签核。

## IO、供电与数模边界

core pin 不是完整 IO pad。需按目标 chip/block 层次区分 pad/ESD、电平/电压域、供电 ring/连接、封装与板级负载、slew，以及外部 SPI 时序。暂做 block-level 时写出遗漏，不声称具备 IO ring。

给模拟/RF 邻居写需求：数字更新电流、敏感采样窗口、供电/地共享、走线耦合、guard/isolation、模拟控制码是否无毛刺。DRC 合规不能证明噪声幅度或 settling 达标；这些要用对应的电路、寄生和 AMS 证据。

## DFT 增量：从模式表走向故障覆盖

47 已解释 scan 与模拟输出拥有权。下一步先定义 normal/calibration/scan_shift/scan_capture/analog_test 的进入退出、clock/reset、isolation 和安全输出，不先插链改变原控制器。

概念上 stuck-at 检查节点卡 0/1，transition 类故障检查切换速度；二者是抽象故障模型，不等于所有制造缺陷。ATPG 的 fault coverage 要注明故障集、分母、excluded/untestable/aborted 分类、测试约束和模式。链完整性、shift/capture 仿真、scan timing、ATPG、模拟安全输出分别留证；插链成功不等于测试覆盖达标。

实际 scan insertion/ATPG 需匹配 scan cells、可控测试时钟、流程/许可和约束；当前未核对完这些条件。SRAM BIST/repair 与模拟测试另外制定，不从标准单元 scan 自动推出已覆盖。

验收先交付物理输入清单、阶段矩阵、IO/供电边界、blackbox/waiver 空白登记与测试模式表。实跑时补完整证据，不预填 PASS。关系维护在 [K10/K12 Mapping](../references/course_mapping.md)，学习解释写 [日志](../learning_log/README.md)。
