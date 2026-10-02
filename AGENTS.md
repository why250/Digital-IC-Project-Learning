# Digital IC learning project

This project teaches digital IC design to an experienced analog IC engineer.
Explain concepts in Chinese, connecting RTL to registers, gates, timing, load and PVT.
Start with lesson 01: a single-system-clock SPI master. Keep later topics separate.

## Server and tools
- SSH alias: IC_Server, existing key authentication.
- Remote project: /home/userone/AAAIC/test_tb/digital_ic_learning.
- Genus: /opt/eda/cadence/DDI251/GENUS251/bin/genus (25.10-p002_1).
- Innovus: /opt/eda/cadence/DDI251/INNOVUS251/bin/innovus.
- The bundled Genus tutorial Liberty library is for education, not a tapeout PDK.
- Use isolated batch jobs. Do not change existing GUI sessions or shared services.
- Keep licenses, proprietary PDK files, waveforms, reports and installed tools out of Git.
- Use ordinary scp and verify transferred file hashes. Inspect corruption before using a text-transfer fallback.
- Do not install system packages or change global PATH. Optional Icarus lives under remote .tools/.
- Read docs/progress.md before repeating setup or simulations.

## Lesson 01 contract
SPI Mode 0, 8 bits, MSB first, 50 MHz system clock, 1 MHz SCLK by default.
All internal registers use clk. rst_n is synchronous and active low.
start must be a one-cycle pulse; requests during busy are ignored.
tx_data is latched at acceptance. rx_data updates at the eighth sampling edge.
done is a one-cycle pulse when CS is released; consume rx_data with done.
External MISO timing must meet the documented interface assumptions.
Do not silently turn teaching SDC assumptions into a board or tapeout signoff claim.

## Verification
Run scripts/run_sim.sh: independent slave stimulus and protocol checks, all 256
transmit patterns, non-loopback receive, busy-start rejection, reset during transfer,
one-cycle done, and divider values 1, 3, 25. Then run scripts/run_synth.sh.
Check command exit codes, explicit completion markers, unmapped cells, timing intent
and mapped netlist contents. RTL simulation is not formal equivalence or signoff.
