# 2026-10-07：公开参考体系接入

用户先要求审计与 mapping 草案，确认“继续完善课程”后实施本次增量。中心入口为 [course_mapping](../references/course_mapping.md)，资源说明见 [references](../references/README.md)。记录针对本次工作，不将此前已存在的文档整理、网站和部署变更算作本次新增。

## 实际改动

- 草案转为 v1.0 关系中心：19 个稳定知识节点、94 个既有课号的分组映射、P/S/O/Own、审计基线与本次补充状态、独立实验 ID。
- 建立六个公开资源页：具体官方入口、版本/访问边界、阅读取舍、自己的实验绑定。EE141 标明教材配套站；Stanford 详细课程受限；不复制课件或公开 lab 答案。
- 建立按日期/节点/工程问题命名的 [learning_log](../learning_log/README.md) 与模板，没有代填个人学习或预建 lecture 日志。
- 四份原创 [项目化补充](../references/README.md#项目化补充)：K05 lint/SVA/随机/覆盖/formal；K06/K07 PPA/min/hold/MMMC；K09 RAM/SRAM；K10/K12 物理检查/IO/DFT。练习和教学代码片段尚未执行。
- README/roadmap/六个总纲及相关原讲义增加短入口，AGENTS 固化资料纳入和证据规则；保留原课号与数模主线。
- 网站只追加一条多列表格最小列宽规则，手机局部横向滚动；不改变课程索引、路由、状态或笔记逻辑。

## 验证记录

文档：`python tools/check_docs.py` 通过 UTF-8、本地链接/锚点、README 可达性与六套讲义/答案课号覆盖；`git diff --check` exit 0。检查统计以 [progress](../progress.md) 的本次摘要为准。

网站：`pnpm check` exit 0（23 文件、零错误/警告/hints）；`pnpm test` exit 0（四项）；`pnpm build` exit 0。构建仍提示部分 JS chunk 大于 500 kB，未因此改依赖或做性能重构。生成页的站内文件/锚点检查通过。

首次 `pnpm test:browser` 因 Playwright 期望的 headless shell 未安装而无法启动，测试正文未执行。通过当前命令环境设置 `PLAYWRIGHT_EXECUTABLE_PATH` 复用已有 Edge 后，八项现有测试全部通过；没有安装包或改全局 PATH。CSS 调整后复查八项仍通过。

新增内容专项浏览器检查：14 个 mapping/资源/log/补充页面，在 1440×844 和 390×844 下 HTTP 200、正文标题可见、无页面横向溢出、pageErrors=0；README→mapping、日志→模板导航通过。手机 mapping 表 client=308 px、scroll=701 px、最小列宽=140 px，可局部横向滚动，截图人工检查通过。截图在网站忽略的 test-results 中。

课程设计/运行文件：本次起点与结束比较 `lessons/` 下排除 results/.tools 的 28 个文件 SHA-256，全部一致（含源码说明 README）。未查询 IC_Server，未运行 EDA、未生成新 RTL/综合/物理/AMS 结果。

## 尚待推进

近期先完成本人 K02/SPI 的预测与解释，再按需要做 lint/错误注入与覆盖闭环；工具可用性、完整 SVA 支持和形式环境待核对。宏集成、真实 min/hold/MMMC、P&R/DRC/LVS、scan/ATPG 与 AMS 继续各自待实现或待运行。

本次仅本地完善与检查，未提交、推送、发布网站或向服务器部署。原有工作区变更保留；线上网站暂不包含本次内容。
