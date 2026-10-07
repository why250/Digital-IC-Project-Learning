# 当前进度与验证证据

更新日期：2026-10-07。EDA 设计/环境结论来自 2026-10-02 至 2026-10-04 的实际记录，未重新查询服务器或运行设计；本日完成文档整理、学习网站及公开参考体系，文档/网站验证分别记录在末尾。完整过程见 [历史记录](history/2026-10-02_to_04.md)，操作见 [运行指南](running.md)，学习顺序见 [个人路线](roadmap.md)。

## 当前状态

| 范围 | 已有材料与实现 | 实际证据 / 下一步 |
|---|---|---|
| 01–24 数字基础 | 讲义、答案、验收；SPI Master RTL/TB/SDC | SPI 仿真与逻辑综合通过；基础微实验、Slave/配置结课项目待实现 |
| 25–48 数模控制 | 讲义、答案、测量/trim 项目契约 | 其余控制模块待逐课实现 |
| DF01–DF08 | 抽取链课程、候选架构与规格 | 解析算例已核对，系数/模型/RTL 待实现 |
| AD01–AD20 | 数值模型、七个 RTL top、独立回归与连续流 | 教学条件下模型/RTL/setup 已验证；真实 ADC/物理证据另做 |
| TD01–TD12 | DAC 课程、架构与项目契约 | 解析算例已核对，模型/系数/RTL 待实现 |
| AM01–AM06 | 六课操作、接口、答案与验收 | 自建模型/OA/TB 待实现；官方 PLL 尝试在网表阶段失败 |

各 workbook 的个人学习状态仍待填写。课程设计完成、工具 PASS、个人掌握和真实芯片签核分别记录。

## SPI Master：已验证基线

2026-10-02 执行，2026-10-03 复核已有产物。规格为 50 MHz 单系统时钟、Mode 0、8 位、MSB first、默认 1 MHz SCLK；详细接口见 [工程参考](01_spi_master.md)。

| 半周期分频 | 逻辑 SCLK | 完整交易 | 结果 |
|---|---:|---:|---|
| 1 | 25 MHz | 258 | PASS |
| 3 | 8.333… MHz | 258 | PASS |
| 25 | 1 MHz | 258 | PASS |

共 774 笔完整交易，各参数另有一笔复位中止。覆盖 256 个发送值、独立接收、忙时 start、锁存后输入变化、复位恢复、协议沿/半周期/CS 与单周期 done。首帧 A5/3C，CS 有效 8.5 μs。

Genus 25.10-p002_1、默认分频 25，使用服务器自带 tutorial.lib（typical_case、5 V、25°C）：37 fflopd、56 inv1、171 nand2、13 nor2，共 277 单元；面积 440.500 教学库单位。最差 setup slack 为 14.239 ns，路径 miso→rx_data_reg[0]/D，使用 5 ns 教学输入预算。映射前后 timing intent 为 0，check_design 无 unresolved/empty/undriven/multidriven/unloaded，网表无 latch 或残余通用逻辑。

仿真/综合退出及完成标记已核对，19 个收集产物与远端 SHA-256 一致。证据在 `lessons/01_spi_master/results/`（Git 忽略）；解释见 [第一份报告](02_read_first_reports.md)。库属性提示与 logical-only 实例的原因保留在历史记录。

## ADC：已验证范围

2026-10-04 完成，[逐课实验指南](adc_digital/09_labs.md) 映射到模型与 RTL。模型、仿真、连续流、综合检查均 exit 0 且完成标记已确认。

- 架构回归：SAR 全部 1024 码及超时/忙启动/复位，Flash 全部 65536 二值输入，Pipeline 对齐/错标签，DWA 边界与非法码。
- 数据通路：异步 FIFO 10/14 ns 域的满空/环绕/协调复位；定点 14103 向量含 RNE、饱和与 flush。
- TI：18 个接口场景，独立采样台账、标签/重排、故障 HALT、复位/旧 epoch、系数原子版本与冻结统计。
- 连续流：65540 份输出丢弃四份旧版本后，65536 连续 id/epoch/version/整数值一致。受控 offset/gain 合成失配下，SFDR 36.478→98.060 dB，校正后 SNDR 67.791 dB（N=65536、bin=6001、Fs=4 MHz、A=1000 LSB）。

| top | 教学库单元数 | 最差 setup slack（ps） |
|---|---:|---:|
| sar_controller | 581 | 6885 |
| flash_encoder | 241 | 5653 |
| pipeline_align | 1327 | 6429 |
| dwa_encoder | 162 | 7464 |
| adc_fixed_correct | 3691 | 2474 |
| adc_async_fifo | 1162 | 8106 |
| ti_adc_backend | 18625 | 2317 |

七 top 映射前后 timing intent 为 0，无未知/未映射单元、procedural 逻辑或 latch，check_design 无 unresolved/empty/undriven/multidriven。每 top 的 `verification.json` 保存单元、setup、报告哈希与未执行 hold 信息。155 个结果文件普通 scp 收集且 SHA-256 一致，证据在 `lessons/adc_digital/results/`（Git 忽略）。

未实现通用后台校准、真实时钟 trim 或 SPI 桥；FIFO 的 Gray bus 物理 skew/max delay 与 MTBF 未验证。数值模型与受控码流结果不代表真实 ADC 性能。

## AMS 与服务器环境

2026-10-04 已确认 Virtuoso IC25.1-64b.38、Spectre 25.1.0.054、DDI 25.10-p002_1。其他工具与候选组合见 [工具栈评估](mixed_signal/13_tool_stack.md)，组件存在不等于流程可用。

官方 AMSDInADE 在独立 `.tools/` 目录解压并核验 2394 普通文件，source 快照保留。PLL 顶层 22 个实例只读检查成功；runams exit 255、AMS-1172 缺 connectLib，未进入编译/展开/仿真、无波形，诊断 `AMS_NOT_RUN`。10 个诊断产物已收集并核验哈希，见 [实际尝试](mixed_signal/12_ams_tutorial_run.md)。

已检查的 PATH/Cadence 目录未定位 xrun/irun 与所需连接库，不排除其他位置；AMS/Xcelium 许可与兼容组合未验证。恢复条件见 [AMS 环境清单](ams/07_setup.md)，无需重复解压已有教程。

## 未完成与下一步

所有已有综合均为教学逻辑证据。尚未做门级仿真、形式等价、布局布线、CTS/提取寄生、多角 setup/hold、功耗活动或真实器件接口签核。SPI SDC 是教学预算；ADC setup 报告也不覆盖 hold/CDC 物理签核。

当前先完成 [SPI 基础学习与个人验收](course/01_sync_spi.md)，再按个人路线推进。2026-10-07 的整理统一入口、顺序、运行命令与证据归属，合并重复导航，保留原课程编号、工程契约、历史与设计源码。

本次检查：`python tools/check_docs.py` exit 0，73 份 Markdown、287 个本地链接（其中 1 个为可选生成波形）、六套讲义/答案编号与 README 导航通过；`git diff --check` 通过。历史正文完整保留，RTL/TB/模型/SDC/运行脚本与整理前一致，未重跑仿真或综合。

## 2026-10-07 学习网站

新增独立 `web/` Astro 静态网站，直接读取现有 Markdown，提供六个方向、94 课入口、课程正文搜索、阅读导航/目录、源码查看与 Markdown 下载。学习状态与笔记按课保存在浏览器，支持备份导出和校验后的合并导入；工具证据与个人验收继续分开。

第 01 课新增理想 SPI 时序演示：50 MHz 单 clk、Mode 0、MSB first，独立 TX/RX 和分频 1/3/25，显示八次采样、rx_data 更新与 20 ns done。演示是协议契约的教学模型，不替代 RTL 仿真或真实 MISO 时序验证。

兄弟项目 circuits-and-systems-classroom 的首页与共享顶部导航新增数字课堂入口，本站导航/页脚返回模拟课堂。运行与发布说明见 [网站 README](../web/README.md)。既有数字设计、EDA 仿真/综合脚本与服务器工具未修改，也未重跑 EDA。

网站检查：Astro 严格类型检查零错误/警告；四项数据/模型测试、八项 Chromium 浏览器测试通过，覆盖搜索/导航、笔记持久化、备份、SPI 控件与 390 px 手机布局。生成网页的站内文件/锚点检查通过；兄弟站的链接与布局在 1440 / 390 px、首页/路线/ADC 三类页面检查通过。

正式发布：[Digital IC Classroom](https://why250-digital-ic-classroom.pages.dev/) 与 [模拟课堂](https://why250-circuits-classroom.pages.dev/) 均已部署到各自 Cloudflare Pages 项目。新站八个关键地址（首页、路线、目录、第一讲、SPI、Markdown、RTL 源码、sitemap）返回 HTTP 200。真实浏览器在 390 px 下验证“模拟课堂顶部入口→数字课堂→SPI 分频/第八沿→返回模拟课堂”通过。网站发布不包含 EDA 产物，也未自动提交或推送 Git。

本地 `tools/deploy.ps1` 的文件清单排除独立网站 `web/`，避免把网页路由或前端依赖部署到 EDA 服务器；scp/哈希校验流程保留。PowerShell 语法与部署清单检查通过，SPI/ADC 源文件均保留，未实际发起服务器部署。

## 2026-10-07 公开参考体系与课程补强

经用户确认 mapping 方向后，接入 [19 个知识节点与课程映射](references/course_mapping.md)、六个版本化资源页和 [学习日志/模板](learning_log/README.md)。资源以具体工程问题挂回原课程和实验，不新建学校课程树；94 个课号与数模特色保留。实际范围与验证过程见 [本次历史](history/2026-10-07_references.md)。

补充 K05 lint/SVA/随机/覆盖/formal、K06/K07 PPA/min/hold/MMMC、K09 RAM/SRAM、K10/K12 物理检查/IO/DFT 的教学与练习设计，从原讲义连接。新增练习和 SVA 片段未执行；未代填个人学习或变更既有工程 PASS。源码/TB/模型/SDC/runner 等 28 个 lessons 文件与本次起点 SHA-256 一致，未查询服务器或重跑 EDA。

文档检查共 89 份 Markdown、437 个本地链接（含 1 个可选生成产物链接），UTF-8、导航与六套课程编号检查通过，`git diff --check` exit 0。网站类型检查零错误/警告；四项数据/模型测试与八项现有浏览器测试通过。浏览器使用现有 Edge，未安装新工具。14 个新增内容页的 1440/390 px 专项阅读与入口检查通过；手机多列表格增加最小列宽并可局部横向滚动。静态构建与生成页链接/锚点检查通过。

本次只完成本地文档/教学补强及阅读验证；未提交、推送或重新发布网站。公开课核对不等于本人学完，新增说明不等于工具实验完成。

## 2026-10-07 公开课逐课融入原课程

上节记录的是参考体系初次接入时的本地状态；该批次随后已作为 `15f3ec3` 提交/推送并发布。用户反馈中心 mapping 与原课程脱节后，本轮进一步在六方向、35 份原讲义的 **94 个课号** 内加入具体选读、阅读问题、自己的实验与预期 artefact。总纲课号、网站正文导航和逐课记录均能直达本课处方；mapping 继续维护知识关系，网站不另存一套推荐数据。

示例：[03：NBA→SPI 寄存器](course/01_sync_spi.md#03-参考与实验)、[06：TB/coverage→独立验证](course/01_sync_spi.md#06-参考与实验)、[20：CTS→setup/hold](course/05_physical.md#20-参考与实验)、[AD15：综合→定点校正](adc_digital/04_calibration.md#ad15-参考与实验)。校准、频谱、DEM 和 AMS 的特有契约保持 Own。实际范围和检查见 [逐课融入历史](history/2026-10-07_lesson_readings.md)。

文档/链接检查和 diff 空白检查通过；网站类型检查零错误/警告，四项数据/模型测试、九项 Edge 浏览器测试、静态构建通过。六方向 1440/390 px 的目录→处方专项导航及布局检查通过；121 个 HTML 的 11502 个站内页面/锚点引用通过。28 个 lessons 文件与起点哈希一致，未运行新 EDA 或代填个人学习。
