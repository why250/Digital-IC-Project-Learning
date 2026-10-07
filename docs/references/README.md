# 公开资料：按项目问题选读

本项目的学习顺序由 [roadmap](../roadmap.md) 决定。外部课程、教材和视频只为当前工程问题提供解释与方法，统一挂到 [K01–K19 知识节点与课程映射](course_mapping.md)。

## 怎么使用

1. 从项目提出一个可检验的问题，例如“为什么忙时 start 不应覆盖 tx_data？”
2. 在当前原课正文的“课号 参考与实验”找推荐章节与阅读问题；总纲课号和网站记录均可直达。中心 mapping 用于查节点与新增资料归属。
3. 先选课内的一个 Primary Reference；按给出的小节/问题阅读，回来完成同一课的实验产物。
4. 在 [学习日志](../learning_log/README.md) 记录预测、实验、证据与结论，再回原 workbook 验收。

每次阅读都应带回一个可审查产物：寄存器图、波形预测表、独立参考模型、RTL/TB、约束来源表或报告解释。可先完成手算；工具实验仍标“未运行”。

## 当前资源

核对日期：2026-10-07。状态表示来源访问情况，不表示本人学完。

| 资源页 | 定位 | 已核对版本 / 访问边界 |
|---|---|---|
| [Berkeley EECS151/251A](berkeley_eecs151.md) | RTL、验证与 ASIC labs 首选 | Fall 2026 公开站；校内环境未验证 |
| [Cornell ECE5745](cornell_ece5745.md) | ASIC 方法与设计空间评估首选 | Spring 2023；handout 保留自身年份 |
| [MIT 6.004](mit_6004.md) | 从 CMOS 到同步数字抽象 | OCW Spring 2017 / 配套站 |
| [EE141 / Rabaey DIC](berkeley_ee141.md) | 门、线、负载、延迟和功耗 | 核对的是第 2 版教材配套站 |
| [Stanford EE271](stanford_ee271.md) | VLSI/DFT/验证第二视角 | 公开主题可读；详细 syllabus 在 Canvas |
| [MIT 6.375](mit_6375.md) | 高级模块化、流水与架构选读 | Fall 2019；BSV 工具链不加入必修 |

## 项目化补充

已有讲义的公共概念继续复用；以下只补审计发现的缺口，不设新课号。

- K05：[lint、性质、SVA、随机与覆盖闭环](../practice/verification.md)。
- K07：[min/hold、MMMC 与受控 PPA 比较](../practice/timing_and_ppa.md)。
- K09：[从 FIFO 到同步 RAM / SRAM 宏](../practice/memory.md)。
- K10/K12：[物理验证与 DFT 的证据边界](../practice/physical.md)。

## 新资料的纳入规则

先复用节点，再讨论新增节点。一个有用资源必须说明：来源/作者、版本、具体阅读入口、解决哪个问题、对应项目课号/实验、为何优于或补充已有首选、工具依赖和核对日期。YouTube 系列只取作者原始频道或可追溯官方入口，按内容挂节点，不照播放列表另建课程树。

P/S/O/Own 的关系只维护在中心 mapping；资源页解释自身取舍。失效链接先更新版本/访问状态，保留旧来源身份，不能悄悄把一学期的 lecture 编号套到另一学期。

只保存链接、推荐章节与自己的理解，不保存受保护的 slides、教材、答案、视频或学校 PDK。具体工具命令参考实际安装版本；公开 lab 可读不等于许可证和配套库可用。实验数据与个人学习状态分别在 progress、日志和 workbook 维护。
