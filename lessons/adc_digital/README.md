# ADC 数字模块实验

[AD01–AD20课程](../../docs/adc_digital/00_course.md)与[逐课实验指南](../../docs/adc_digital/09_labs.md)说明输入假设、运行方法和证据层次。

- `rtl/`：SAR、Flash、Pipeline对齐、DWA、异步FIFO、定点校正、四lane TI后端，七个可综合top。
- `models/`：标准库数值模型、精确整数参考、独立采样台账、连续码流FFT和综合检查。
- `tb/`：架构、定点、FIFO、TI故障/版本、65536样本连续流。
- `scripts/`：models→sim→stream→synth，独立batch，实际结果见进度记录。
- `results/`：生成产物，Git忽略，工艺/许可/安装工具不入库。

100MHz core/4M总采样率、响应1…60周期、sample+80重排、P=4校正；offset signed18/F4、inverse_gain signed18/F16、输出signed18/F4。TI内部同core，FIFO为独立双clock实验，SPI第一课保持原契约。

时钟trim、通用后台校准、SPI寄存器桥、无损回绕、真实hold/物理签核未实现。timing/RC/jitter/校准条件由数值模型演示，不能代替真实ADC电路证据。
