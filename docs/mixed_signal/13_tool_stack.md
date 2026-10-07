# IC25.1 数模混合工具栈评估与安装建议

评估日期：2026-10-04，服务器IC_Server。依据实际版本查询、安装目录、DDI README与本机AMS文档。当前目标是数字基础、ADC/DAC控制/校准、滤波与Virtuoso AMS，不进行软件安装或环境变更。

结论：保留现有IC25.1、Spectre25.1、DDI25.1与Calibre，优先补齐兼容的Xcelium/AMS工具和许可。先解决数字引擎/接口库，再按课程增加形式、独立时序或功耗工具；目前无需购买或部署全部产品。

## 已核实的软件

| 软件 | 实际版本/证据 | 作用与评估 |
|---|---|---|
| Virtuoso | `virtuoso -W`：IC25.1-64b.38，安装组件25.10-p038 | 原理图、版图、ADE、config/AMS集成；保留 |
| Spectre | `spectre -W`：25.1.0.054 | 模拟/Verilog-A求解；保留，AMS配套须确认 |
| DDI | README：DDI25.10-p002_1 | 产品合集，不是数字仿真器 |
| Genus | DDI25.10-p002_1；此前真实综合通过 | RTL综合；保留 |
| Innovus | DDI README列25.10-p002_1，可执行文件存在 | 数字布局布线；本课程尚未实际物理实现 |
| Joules/Joules Studio | DDI README列25.10-p002_1，可执行文件存在 | RTL功耗/设计分析；尚未验证许可和实际运行 |
| Quantus/QRC组件 | Innovus内qrc/quantus存在，ExtCce/extQrcx版本24.10-s201 | 已有提取组件；完整模拟提取流程尚未验证 |
| Calibre | `calibre -version`：2025.2_38.18 | DRC/LVS/可选提取；版图任务和规则许可尚未验证 |
| ADS | 有ADS2025/2026/2027安装目录 | 本次未逐一查可执行版本/许可，不能按目录断言可用 |
| Icarus | 项目内既有12.0，SPI/ADC回归已用 | 轻量RTL教学，继续保留 |

当前PATH未定位xrun/irun/SimVision，此前搜索Cadence安装树也未找到Xcelium/Incisive引擎。Tempus、Voltus、JasperGold、Conformal、Modus在当前PATH/检查的DDI可执行目录未发现；不排除其他安装位置。

DDI README明确列出的三个产品是Innovus、Genus、Joules。它列出的license选项不代表相应独立工具全部安装或可用。ADE/AMS设置界面包含在IC中，不等于Xcelium或AMS联合许可已经齐备。

## 最小推荐组合与版本

| 优先级 | 软件/能力 | 推荐版本策略 | 理由 |
|---|---|---|---|
| 现在保留 | Virtuoso | IC25.1.38作为当前基线 | 已可读取教程OA并签出框架许可 |
| 现在保留 | Spectre | 25.1.0.054作为当前基线 | 无需为新增数字引擎先升级模拟工具 |
| 第一补项 | Xcelium＋AMS集成/接口库＋SimVision | 优先评估Xcelium25.03维护版作为候选；精确ISR须以IC/Spectre/OS兼容资料确认 | 补RTL事件引擎、混合接口与数字调试 |
| 现在保留 | Genus/Innovus/Joules | DDI25.10-p002_1整套基线 | 已有综合结果，不为AMS更换数字实现工具 |
| 现在保留 | Calibre | 2025.2_38.18，先配实际PDK认证规则 | 无需同时再部署另一套DRC/LVS工具 |
| 提取时检查 | Quantus | 当前24.1-s201组件优先核对；不足再补完整提取安装 | DDI README明确列其兼容版本，避免重复安装 |

Xcelium25.03是本次提出的候选主线，**不是已验证的IC25.1.38＋Spectre25.1.0.054＋RHEL9.7配对结论**，也不声称是2026年最新版本。本次公开检索未取得可据以锁定具体ISR的完整矩阵，当前安装缺少Xcelium自己的兼容控制文件。因此不能可靠地指定一个sXXX补丁号。供应商/下载门户若针对当前组合指定其他release或ISR，应按该资料选择。

Spectre AMS Designer是联合仿真能力，不应理解为“只安装一个名字叫AMS的独立可执行程序”。需要匹配的数字工具安装、模拟求解器、接口组件和所需许可证。SimVision通常随Xcelium工具环境提供，先检查该安装包，不单独寻找来源不明的调试器。

## 为什么不能只按25系列配套

本机官方文档 `IC251/doc/ams_dms_simug/Compatible_Spectre_Version_Control_File.html` 指出，应查看Xcelium安装中的：

```text
tools.lnx86/affirma_ams/etc/files/spectre_compatible_version.xml
```

以及该release的IC/Spectre/平台支持说明，判断Spectre配套版本。该文件的validated/allow配置是版本证据，不通过改宽检查或覆盖安装文件制造“兼容”。程序能启动、版本年份相同、OA能打开，都不等价于联合流程已验证。

DDI安装README明确列：Virtuoso25.1、Tempus25.1、Voltus25.1、Quantus24.1.0-s201是其跨stream配套版本信息；这仅适用于README声明范围，不是AMS矩阵。

IC中Mixed Signal Interoperability Guide的“Validated Innovus and Virtuoso Release Combinations”页面仍列一些旧组合，不能仅凭该页把当前补丁配对认证。当前基线保留，后续Virtuoso/Innovus OA交付实际运行时仍需确认所用接口与PDK。

## 后续可选产品

| 软件 | 学习价值/触发需求 | 版本与优先级 |
|---|---|---|
| Conformal LEC | RTL与综合网表的逻辑等价，补仿真无法穷尽的结构检查 | AMS打通之后，再选支持Genus25.1/库模型的维护版；精确release未核实 |
| JasperGold | FSM、FIFO、CDC/协议性质和形式验证 | 有明确形式任务再选当前平台支持版；不作为AMS前置 |
| Tempus | 独立STA、多角setup/hold及实现后时序 | DDI文档配套25.1；物理课程/签核需求出现再补 |
| Voltus | 电源完整性、IR/EM与数字功耗签核 | DDI文档配套25.1；需实际PG网/活动/工艺数据 |
| Modus | scan/ATPG/DFT | DFT课程落地后选择与现有实现工具配套版本；本轮不锁定补丁 |
| 独立Quantus | 模拟或数字提取流程完整性 | 先检查现有24.1-s201组件、Virtuoso接口/许可/PDK技术文件，缺项再补 |
| Pegasus/PVS | 另一套物理验证流程 | 当前有Calibre，只有PDK/团队要求时增加 |
| ADS/RF相关能力 | PLL/RF、系统/电磁设计 | 当前ADC/DAC数字与AMS入门不优先新增 |

Joules已存在，可先评估RTL活动与功耗分析；Voltus与Joules解决不同层级问题，不能把任一存在解释为完整功耗/IR签核能力。Conformal、JasperGold不互相替代：前者重点是等价，后者按所用app检查设计性质。

## 平台、许可与PDK

服务器实际是RHEL9.7/x86_64、Linux5.14。DDI README列RH8.4+/RH9.X/SLES15，并说明不支持RH7；这些是DDI证据，不能推广到任何旧Xcelium/Incisive。每个新release分别检查具体OS小版本、运行库、许可证客户端要求。

安装包可执行不代表功能许可证齐备。当前仅证明Virtuoso Framework和Genus的既有签出/运行；Xcelium/AMS/模拟高级模式、Calibre任务、Quantus等功能按将要使用的模式确认，不需要在规划阶段曝光许可文件或服务器凭据。

模型、DRC/LVS deck、器件Pcell/CDF、LEF/Liberty、RC/提取技术文件以及其工具版本认证，同样决定实际可用性。GPDK090与tutorial.lib用于教学，不能替代真实foundry PDK或流片签核。本次不扫描/复制专有PDK或许可证正文。

## 建议执行顺序

1. 获取支持现有IC/Spectre/RHEL组合的Xcelium维护版本与混合仿真能力，独立安装目录，按项目/进程配置环境；保留现有基线和已有GUI。
2. 验证xrun/Spectre版本、接口库、许可证与最小logic↔electrical例，再运行已解压的 [官方PLL教程](12_ams_tutorial_run.md)。旧OSS/irun状态、connectLib和TestDir仍需修正，不认为新装工具自动消除全部问题。
3. 固定通过的工具/模型组合，再开展SAR、trim、CT ΔΣ/交织DAC联合实验。
4. 综合和实现课程继续使用DDI；有真实物理数据后再补Tempus/提取与功耗签核；形式/DFT按具体项目需求增加。

当前最有价值的补项是Xcelium/AMS。本轮仅核对软件和编写建议，没有安装、升级、切换全局PATH或修改现有会话。

资料依据：服务器`/opt/eda/cadence/DDI251/README.txt`、IC251上述AMS兼容文档、实际版本命令、组件版本文件及 [此前教程尝试](12_ams_tutorial_run.md)。在线可访问性限制下，候选Xcelium版本与精确ISR的最终确认需该release官方支持矩阵。
