# Changelog ? TinyNPU200 IP Core

All notable changes to the TinyNPU200 IP core are documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [v1.0.0] ? 2026

### Initial Release

**RTL Implementation**
- 20?8 weight-stationary systolic array (160 processing elements)
- 3-stage pipelined DSP48E1 MAC processing element
- AXI4-Lite control/status register bank (32 registers)
- AXI4-Full DMA master for weight loading and result store
- AXI4-Stream input sink with spatial crop preprocessor
- AXI4-Stream output source
- Dual-banked ping-pong weight buffer (software-managed)
- 20? ping-pong activation buffers (one per array row)
- Requantization unit (INT32 ? INT8, per-channel scale + shift + bias)
- Activation unit: ReLU, ReLU6, Leaky ReLU, HardSwish, Identity (3-bit select)
- 2?2 pooling unit: MaxPool, AvgPool, Bypass (2-bit mode select)
- YOLOv8 anchor-free bounding box decoder
- Piecewise sigmoid approximation unit
- Threshold/confidence filter
- Output FIFO buffer
- 3?3 depthwise convolution line buffer engine
- Technology-independent clock gating (3 domains)

**Dual Operating Modes**
- Standard convolution inference mode
- Cosine similarity / embedding comparison mode

**Verification**
- SystemVerilog testbench (tb_tinynpu_top.sv)
- 5 test cases: Reset, CSR R/W, CSR address decode, Inference pipeline, End-to-end inference
- All 5 tests passing in Vivado XSim behavioral simulation

**IP Packaging**
- Vivado IP packager project (component.xml)
- Supports IP repository import in Vivado 2025.1
- Target: Xilinx xc7z020clg400-1 (PYNQ-Z2 compatible)

**Documentation**
- Professional README with architecture overview
- Technical project report
- User manual and IP integration guide
- Verification documentation
- IP access policy and terms of use

---

## Planned for Future Releases

- [ ] NPU300PM variant (26?8 array, 208 PEs) documentation
- [ ] RISC-V + NPU integrated system documentation
- [ ] Hardware demonstration results (PYNQ-Z2)
- [ ] Synthesis resource utilization report
- [ ] Timing closure results
- [ ] Power analysis
- [ ] Python/PYNQ driver interface

---

*Copyright ? 2026 Hariharan Ganesh. All rights reserved.*
