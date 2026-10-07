# 运行与结果检查

运行前先读 [当前进度](progress.md)。已有结果可用于学习；只有设计/约束变化、证据缺失或新的实验目标需要时才重跑。当前可运行设计是 SPI Master 与 ADC 专题，其他课程的实验任务按各项目规格实现。

## 环境与操作边界

本地保存源码，SSH 别名 `IC_Server` 使用既有密钥。远端项目为 `/home/userone/AAAIC/test_tb/digital_ic_learning`。

- Genus：`/opt/eda/cadence/DDI251/GENUS251/bin/genus`，已验证 25.10-p002_1。
- Innovus：`/opt/eda/cadence/DDI251/INNOVUS251/bin/innovus`，尚无本项目物理实现结果。
- Icarus：项目 `.tools/iverilog/`，不安装系统包或修改全局 PATH。
- 独立 batch job，不改既有 GUI 会话或共享服务。
- 普通 scp 传输并逐文件核验 SHA-256；不一致时先检查损坏原因。
- 波形、报告、工具、许可证、官方教程库与专有 PDK 留在 Git 外。

## SPI Master

在本地项目根目录的 PowerShell 执行。设计修改后必须先完整 sim，再 synth：

```powershell
./tools/deploy.ps1
./tools/remote.ps1 -Action sim
./tools/remote.ps1 -Action synth
./tools/collect_results.ps1 -IncludeVcd
```

只收集既有结果时执行最后一条。服务器直接执行的等价入口：

```bash
cd /home/userone/AAAIC/test_tb/digital_ic_learning
bash lessons/01_spi_master/scripts/run_sim.sh
bash lessons/01_spi_master/scripts/run_synth.sh
```

`tools/bootstrap_iverilog.sh` 仅在项目内 Icarus 缺失时使用；现有安装无需重复。运行产物在 `lessons/01_spi_master/results/`；VCD 可用 GTKWave 查看，默认首帧 SVG 在 `sim/div25/spi_first_frame.svg`。

必须检查：

- 命令 exit 0，仿真 `SPI_SIMULATION_COMPLETE`，综合 `SPI_SYNTHESIS_COMPLETE` 与 `Normal exit.`。
- 分频 1、3、25，各 258 笔完整交易，共 774 笔；覆盖所有 256 发送值、独立非回环接收、busy-start 拒绝、传输中复位、单周期 done 和协议边界。
- 映射前后 timing intent、check_design、未映射单元与 mapped netlist 内容；报告对应的库、参数与教学 SDC 假设。

接口契约见 [SPI 工程参考](01_spi_master.md)，报告解释见 [综合报告阅读](02_read_first_reports.md)。

## ADC 数字模块

运行顺序为 models→sim→stream→synth；各课与实际源码的对应关系见 [AD 实验指南](adc_digital/09_labs.md)。在本地 PowerShell 执行：

```powershell
./tools/deploy.ps1
ssh -T -o BatchMode=yes IC_Server 'cd /home/userone/AAAIC/test_tb/digital_ic_learning && bash lessons/adc_digital/scripts/run_models.sh'
ssh -T -o BatchMode=yes IC_Server 'cd /home/userone/AAAIC/test_tb/digital_ic_learning && bash lessons/adc_digital/scripts/run_sim.sh'
ssh -T -o BatchMode=yes IC_Server 'cd /home/userone/AAAIC/test_tb/digital_ic_learning && bash lessons/adc_digital/scripts/run_stream.sh'
ssh -T -o BatchMode=yes IC_Server 'cd /home/userone/AAAIC/test_tb/digital_ic_learning && bash lessons/adc_digital/scripts/run_synth.sh'
./tools/collect_adc_results.ps1 -IncludeVcd
```

每条 ssh 后检查 `$LASTEXITCODE` 为 0 再继续。四阶段完成标记分别为 `ADC_MODEL_VERIFICATION_COMPLETE`、`ADC_SIMULATION_COMPLETE`、`ADC_STREAM_VERIFICATION_COMPLETE`、`ADC_SYNTHESIS_VERIFIED_OUTPUTS`。综合还要检查各 top 的 Genus 完成标记、`Normal exit.`、timing intent、check_design、mapped cells 与 `verification.json`。部分用例 PASS 不代替整套通过。

Python 模型仅用标准库，七个 top 串行综合。结果在 `lessons/adc_digital/results/`；收集脚本同样使用 scp 与 SHA-256，`-IncludeVcd` 可选。当前流程只验证教学条件下的 setup，未验证 hold、Gray bus 物理 skew/MTBF、多角或真实 ADC 性能。

## 文档检查与后续实验

仅改文档时，在项目根目录运行：

```powershell
python tools/check_docs.py
git diff --check
```

文档检查覆盖 UTF-8、本地文件链接/标题锚点、课程编号完整性与从 README 的文档可达性。忽略的生成产物链接单独报告，未收集产物不算源码链接损坏。

DF、TD 与控制项目尚无完整可运行实现；不能借 SPI/ADC 的 PASS。AMS 的工具前置与排错见 [环境指南](ams/07_setup.md)，已有官方示例尝试见 [运行记录](mixed_signal/12_ams_tutorial_run.md)。RTL 仿真不等于形式等价，教学库综合不等于接口或流片签核。
