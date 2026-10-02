# 验证记录

日期：2026-10-02。服务器：IC_Server（xunipc）。
本地：D:/Users/Administrator/Documents/GitHub/Digital-IC-Project-Learning。
服务器：/home/userone/AAAIC/test_tb/digital_ic_learning。

## 已完成

- 创建独立学习目录和本地 Git 仓库。
- 中文学习路线、SPI 第一课、RTL、自检查 testbench、SDC 和 Genus Tcl。
- 普通 scp 部署，每个文件进行 SHA-256 校验，未发现包装或内容损坏。
- 从公开 EPEL 下载 Icarus 12.0 RPM，校验 RPM 内容摘要，解包至项目 .tools/iverilog。
  没有系统安装，也没有修改全局 PATH；RPM 签名验证不在本次记录范围内。
- 使用真实 Icarus 仿真，使用真实 Genus 25.10-p002_1 综合，Genus_Synthesis 许可证正常签出。
- 仿真/综合产物收集到本地 results，19 个下载文件均通过 SHA-256 校验。
  results 和 .tools 被 Git 忽略；许可文件、教学库正文和 foundry PDK 没有复制进项目。

## RTL 仿真

| HALF_PERIOD_CYCLES | 对应逻辑 SCLK 频率 | 完整交易 | 结果 |
|---|---:|---:|---|
| 1 | 25 MHz | 258 | PASS |
| 3 | 8.333… MHz | 258 | PASS |
| 25 | 1 MHz | 258 | PASS |

合计 774 笔完整交易；每个参数另有一笔复位中止交易。
每组覆盖 A5/3C 首笔交易、所有 256 个发送值、独立接收、
忙时 start 丢弃、输入在锁存后改变、复位中止及复位后恢复。
协议监视器检查 8 次采样、8 次下降沿、半周期、CS setup/hold 和单周期 done。
最后版本编译日志为空，没有残留时间单位警告。

首笔默认参数交易：
- MOSI 采样：10100101 = A5。
- MISO 采样：00111100 = 3C。
- CS 有效时间：8.5 μs。
- 文件：../lessons/01_spi_master/results/sim/div25/spi_first_frame.svg。
- 原始 VCD：../lessons/01_spi_master/results/sim/div25/spi_master.vcd。

## Genus 综合

- 工具：25.10-p002_1；默认参数 HALF_PERIOD_CYCLES=25。
- 库：服务器 Genus 自带 tutorial.lib，typical_case，5 V，25°C。
- 37 个 fflopd、56 个 inv1、171 个 nand2、13 个 nor2，共 277 个单元。
- 单元面积：440.500（教学库面积单位；不是实际工艺面积结论）。
- 最大延迟报告最差 setup slack：14239 ps = 14.239 ns。
- 最差报告路径：miso → rx_data_reg[0]/D，采用教学 SDC 的 5 ns 输入预算。
- 映射前和映射后的 timing intent 检查均为 Total: 0。
- 映射后 check_design：没有 unresolved、empty、undriven、multidriven 或 unloaded 逻辑。
- 网表实例仅包含上面四种教学库单元，无 latch 或残余通用逻辑实例。
- 报告列出 277 个 logical-only 实例：本次没有读取 LEF，这是逻辑综合阶段的预期状态。

工具给出教学库缺少部分阈值/库级属性的消息，
以及默认参数 elaboration 和综合流程选项的提示；没有阻止综合。
不把教学库消息描述成工艺库验证通过。

## 尚未完成的阶段

未做门级仿真、形式等价、布局布线、提取寄生、多角 setup/hold、
功耗活动分析或真实 SPI 器件接口签核。
当前 SDC 的外部 SPI 时序是教学预算；约束检查为零不代表外部协议已签核。

应用项目侧栏尚未注册。当前可调用工具没有创建项目入口，
computer-use 的 guidance.md 明确禁止自动控制 ChatGPT 桌面界面。
源码和服务器项目已经完整建立；可手动添加此本地目录为独立项目并设为主目录。
官方项目说明：https://learn.chatgpt.com/docs/projects#use-local-projects-for-folders-and-codebases

## 下一课入口

先读 01_spi_master.md，完成最后的六个问题。
先解释波形，再阅读 RTL，然后看综合网表和报告。
学习进度达到这里再进入 SPI Slave + 配置寄存器及 CDC。
