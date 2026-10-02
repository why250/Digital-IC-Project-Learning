# 数字 IC 设计学习

面向熟练模拟 IC 工程师的实践项目。先从电路结构理解 RTL，再通过仿真、综合报告和门级网表建立数字设计直觉。

## 第一个练习：SPI Master

规格：50 MHz 系统时钟、1 MHz SPI、Mode 0、8 bit、MSB first、单个从设备。
内部只使用系统时钟，通过使能控制 SCLK 输出和移位；不把 SCLK 用作内部寄存器时钟。

- [第一课讲义](docs/01_spi_master.md)：接口、结构、波形、RTL 阅读与综合。
- [学习路线](docs/roadmap.md)：SPI Master → 综合/时序 → SPI Slave/CDC → 实现。
- [第一份综合报告解读](docs/02_read_first_reports.md)：37 个触发器与时序裕量的来由。
- [验证记录](docs/progress.md)：真实运行结果及尚未完成的工作。
- RTL：`lessons/01_spi_master/rtl/spi_master.sv`
- 自检查测试：`lessons/01_spi_master/tb/tb_spi_master.sv`
- 综合：`lessons/01_spi_master/synth/run_genus.tcl`
- 时序约束：`lessons/01_spi_master/constraints/spi_master.sdc`

## 运行方式

本地保存源码，SSH 到 IC_Server 运行工具。独立服务器目录：
`/home/userone/AAAIC/test_tb/digital_ic_learning`。

PowerShell，在本项目根目录：

```powershell
./tools/deploy.ps1
./tools/remote.ps1 -Action sim
./tools/remote.ps1 -Action synth
./tools/collect_results.ps1 -IncludeVcd
```

服务器上也可直接执行：

```bash
cd /home/userone/AAAIC/test_tb/digital_ic_learning
bash tools/bootstrap_iverilog.sh  # 第一次需要；项目内安装，不修改系统
bash lessons/01_spi_master/scripts/run_sim.sh
bash lessons/01_spi_master/scripts/run_synth.sh
```

运行产物位于 `lessons/01_spi_master/results/`，不纳入 Git。
波形为 VCD，可用 GTKWave 查看；仿真脚本也生成第一笔交易的 SVG。
Genus 自带教学库仅适用于学习，不代表实际工艺的面积、功耗或时序。

## 先做什么

打开第一课讲义，先读“接口约定”和“从电路看 RTL”，再看第一笔 `A5` 交易的波形。
先解释首位数据为什么在第一个 SCLK 上升沿之前有效，再修改分频参数观察波形变化。
