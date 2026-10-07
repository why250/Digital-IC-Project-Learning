# AMSDInADE 教程解压与首次运行记录

日期：2026-10-04。用户授权解压并运行官方教程testbench。已经解压、验证原理图可读并尝试AMS批处理；实际失败在网表阶段，未进入联合仿真、未产生仿真波形。

## 教程和独立目录

原归档位于IC_Server：

```text
/opt/eda/cadence/IC251/tools.lnx86/dfII/samples/tutorials/AMS/AMSDInADE.tar.gz
```

SHA-256：`c1ad17cc49c5671f5aa18da2dad1df5742b7c06748069e10b5c9f324190737fe`。

独立工作根为：

```text
/home/userone/AAAIC/test_tb/digital_ic_learning/.tools/ams_tutorials/amsd_in_ade_20261004_he_3kf81/
```

| 目录 | 内容 |
|---|---|
| `source/AMSDInADE/` | 原始解压快照，2394个文件逐个校验，运行后再次核对未变 |
| `work/AMSDInADE/` | 可操作副本，含OA设计库、教学GPDK090、模型和ADE状态 |
| `attempt_01/` | 实际runams日志、退出码和生成目录 |
| `inspect_oa.*`、`diagnostic.json` | 原理图批量读取和诊断结果 |

解压前检查归档成员：1294个目录、2394个普通文件，无软/硬链接；拒绝绝对路径、越界路径与特殊文件。每个文件按归档内容验证SHA-256。安装目录和既有GUI未改。

官方教程库、GPDK、模型正文和日志保持在Git忽略目录，未复制进仓库源码。10份诊断/日志/清单已用普通scp回收并SHA-256核验，位置为本地 `results/ams_tutorial/amsd_in_ade_20261004_he_3kf81/`。

## 真实testbench

| 项目 | 教程内容 |
|---|---|
| 设计库 | `amsPLL` |
| 顶层 | `PLL_160MHZ_sim` |
| 运行视图 | `config`，顶层绑定`schematic` |
| ADE状态 | `ams_state1` |
| 保存的tran终止时间 | `2u` |
| 保存的参考频率变量 | `fREF=25M` |
| 原保存流程 | OSS-based netlister、irun |
| 原连接规则 | `connectLib/ConnRules_18V_full_fast` |
| 模型依赖 | `$TestDir/models/spectre/gpdk090.scs`，section `NN` |

顶层原理图已用独立`virtuoso -nograph -nocdsinit -restore`只读打开，退出0、出现`AMS_TESTBENCH_INSPECTION_COMPLETE`，确认22个实例，包括PLL、参考/控制脉冲、偏置源、供电及R/C。教学GPDK090加载成功；Virtuoso Framework License (111)签出成功，这不能证明AMS或Xcelium许可证可用。

库内还包含PLL的schematic/verilogams/behavioral视图、PFD、电荷泵、VCO、PDIV/MDIV及答案视图。仅确认结构和可读性，不认为各视图已编译、PLL已锁定或目标160MHz已测得。

## 实际执行与失败

在`work/AMSDInADE`中执行了以下批处理，使用独立run目录：

```bash
/opt/eda/cadence/IC251/bin/runams \
  -nocdsinit \
  -lib amsPLL -cell PLL_160MHZ_sim -view config \
  -state ams_state1 -cdslib ./cds.lib \
  -rundir ../../attempt_01/run -log ../../attempt_01/runams.log \
  -netlist all -simulate batch
```

实际argv中的cdslib/rundir/log使用绝对路径，保存在`attempt_01_command.json`；以上相对路径等价。runams版本IC25.1-64b.38，退出码255。日志先报告：

```text
AMS-1172: The library 'connectLib' has not been defined
but has been referenced by the connect rules.
```

之后出现`strcat ... nil`和`Failed to generate the netlist file`。没有完整网表、编译/展开/仿真完成标记或波形，诊断状态为`AMS_NOT_RUN`。

runams会在工作副本的保存状态中删除两个旧环境选项`noIrunInfoMsg`/`sst2usecolon`；已核对这个变化，source快照保持一致。没有执行归档中的`clean_up`脚本或修改旧会话。

## 当前缺少的依赖

SSH PATH中未找到xrun/irun及对应编译、展开、仿真程序。进一步搜索当前`/opt/eda/cadence`安装树也未找到xrun/irun/xmsim/ncsim，IC251/SPECTRE251未发现connectLib/connect_lib目录。教程的`inca.connectLib`只有旧数据库标记，不是完整连接模块库；`AMSHOME`未设置。

现有Virtuoso/Spectre与AMS集成脚本不足以运行此RTL/模拟组合。其他磁盘位置仍可能有数字工具；不能把“当前安装树未找到”推为整台服务器绝对未安装，也不能把`strcat nil`单独归因为某一个环境变量。

## 继续运行需要完成什么

1. 定位兼容的Xcelium/AMS安装和相应许可证。先确认实际xrun路径/版本与IC/Spectre兼容性，不能用假命令、Icarus或另一个纯模拟例子代替本教程的AMS结果。
2. 在自己的批处理进程里配置数字工具路径与安装根，找到真实connect库；旧规则若继续使用，需正确cds.lib绑定。现代UCM/IE替代则按当前工具文档做完整迁移，不仅删除旧错误提示。
3. 设置本进程`TestDir`为上述`work/AMSDInADE`，或在工作状态中把模型路径改为明确绝对路径并确认NN section可读。原有状态是OSS/irun，需评估迁移AMS UNL/xrun；不要在共享全局初始化文件中修改。
4. 再跑独立网表/编译/展开/短tran，检查端口discipline、插入的接口元件及1.8V/阈值/阻抗/边沿设置。保留每阶段退出码和日志，确认实际波形后再评价PLL频率、锁定、控制电压和模型层次。

现在已有解压和可读的testbench，缺少仿真器/连接库依赖。基础 [AMS入门](11_ams_intro.md) 和现有 [课程](00_course.md) 可继续学习；本记录不登记AMS PASS。
