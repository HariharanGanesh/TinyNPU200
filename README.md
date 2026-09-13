<div align="center">

# TinyNPU200

### FPGA-Based Neural Processing Unit IP Core

*A weight-stationary systolic array NPU for INT8 CNN inference on Xilinx Zynq FPGAs*

---

[![Language: Verilog](https://img.shields.io/badge/Language-Verilog--2001-blue?style=flat-square)](https://en.wikipedia.org/wiki/Verilog)
[![Language: SystemVerilog](https://img.shields.io/badge/Testbench-SystemVerilog-blue?style=flat-square)](https://en.wikipedia.org/wiki/SystemVerilog)
[![Tool: Vivado](https://img.shields.io/badge/Tool-Xilinx%20Vivado%202025.1-red?style=flat-square)](https://www.xilinx.com/products/design-tools/vivado.html)
[![FPGA: Zynq-7020](https://img.shields.io/badge/FPGA-Zynq--7020-orange?style=flat-square)](https://www.xilinx.com/products/silicon-devices/soc/zynq-7000.html)
[![Interface: AXI4](https://img.shields.io/badge/Interface-AXI4%20%7C%20AXI4--Lite%20%7C%20AXI4--Stream-green?style=flat-square)](https://developer.arm.com/documentation/ihi0022)
[![Type: IP Core](https://img.shields.io/badge/Type-FPGA%20IP%20Core-purple?style=flat-square)](#)
[![Simulation: PASS](https://img.shields.io/badge/Simulation-9%2F9%20PASS-brightgreen?style=flat-square)](#verification)
[![License: Proprietary](https://img.shields.io/badge/License-Proprietary%20%E2%80%94%20All%20Rights%20Reserved-red?style=flat-square)](TERMS_OF_USE.md)

**Copyright (c) 2026 Hariharan Ganesh. All rights reserved.**

[Architecture](#architecture) | [Features](#features) | [Quick Start](#quick-start) | [IP Access](#ip-access) | [Documentation](#documentation) | [Verification](#verification) | [Contact](#contact)

</div>

---

## Overview

**TinyNPU200** is an original FPGA Neural Processing Unit (NPU) IP core implemented in synthesizable Verilog-2001. It implements a **20x8 weight-stationary systolic array** of **160 Processing Elements (PEs)**, each mapped to a Xilinx DSP48E1 MAC unit, enabling efficient INT8 neural network inference acceleration.

The IP is designed for integration with the **Xilinx Zynq-7020 SoC** (PYNQ-Z2 board) and exposes industry-standard **AXI4** interfaces, making it compatible with Vivado Block Design and standard AMBA-based SoC interconnects.

### Applications

| Application | Mode |
|---|---|
| CNN-based object detection (YOLOv8) | Convolution inference mode |
| Image classification | Convolution inference mode |
| Face embedding comparison | Cosine similarity mode |
| General INT8 tensor dot-product | Both modes |

---

## Architecture

```
                       +------------------------------------------+
  Host CPU             |            TinyNPU200 IP Core             |
 (AXI-Lite MMIO) ----> | +----------+   +----------------------+   |
                       | | AXI4-Lite|   | NPU Controller FSM   |   |
  DDR Memory    <----> | | CSR Bank |-->| IDLE->LOAD_WGT       |   |
 (AXI4-Full DMA)       | | 32 regs  |   | ->LOAD_ACT->DRAIN    |   |
                       | +----------+   | ->STORE_OUT->DONE    |   |
                       |                +----------+-----------+   |
                       |                           |               |
  Camera / Sensor      | +----------+   +----------v-----------+   |
 (AXI4-Stream IN) ---> | | axis_sink|-->| Activation Buffers   |   |
                       | | + Crop   |   | 20x Ping-Pong BRAM   |   |
                       | +----------+   +----------+-----------+   |
                       |                           |               |
  DDR Weights    --DMA->| +-----------+ +-----------v-----------+  |
                       | |Weight Buf  | | Systolic Array        |  |
                       | |Dual-Bank  |-->| 20 rows x 8 cols     |  |
                       | |Ping-Pong  | | 160 DSP48E1 MACs      |  |
                       | +-----------+ +-----------+-----------+  |
                       |                           |               |
                       |               +-----------v-----------+   |
                       |               | Requantization Unit   |   |
                       |               | INT32 -> INT8         |   |
                       |               | + Bias + Scale + Shift|   |
                       |               +-----------+-----------+   |
                       |                           |               |
                       |               +-----------v-----------+   |
                       |               | Activation Unit       |   |
                       |               | ReLU/ReLU6/LeakyReLU  |   |
                       |               | HardSwish/Identity    |   |
                       |               +-----------+-----------+   |
                       |                           |               |
                       |               +-----------v-----------+   |
                       |               | Pooling Unit          |   |
                       |               | 2x2 MaxPool/AvgPool   |   |
                       |               +-----------+-----------+   |
                       |                           |               |
                       |               +-----------v-----------+   |
                       |               | BBox Decoder          |   |
                       |               | YOLOv8 Anchor-Free    |   |
                       |               +-----------+-----------+   |
                       |                           |               |
                       |               +-----------v-----------+   |
                       |               | Threshold Filter      |   |
                       |               | Confidence Gate       |   |
                       |               +-----------+-----------+   |
                       |                           |               |
 Detection Output      | +----------+   +-----------v-----------+  |
 (AXI4-Stream OUT) <---| |axis_src  |<--| Output Buffer FIFO   |  |
                       | +----------+   +----------------------+  |
                       +------------------------------------------+
```

---

## Implementation Results (Phase 2 Update)

The TinyNPU200 IP was rigorously optimized in Phase 2 to meet all timing and resource constraints for physical Zynq-7020 integration.

| Metric | Phase 1 (Initial RTL) | Phase 2 (Optimized) |
| :--- | :--- | :--- |
| **Clock Frequency Target** | N/A | **100 MHz (10.0 ns)** |
| **Timing Slack (WNS)** | -19.288 ns *(Violated)* | **+0.163 ns *(Met)*** |
| **DSP Utilization** | 248 *(Over-utilized)* | **204** / 220 (92.73%) |
| **BRAM Inference** | FAILED *(LUTRAM fallback)* | **13 Tiles *(SUCCESS)*** |
| **LUT Utilization** | N/A | 14,008 / 53,200 (26.33%) |
| **Total Power** | N/A | **0.672 W** (Dynamic: 0.559 W) |

*Full authoritative Vivado implementation reports are available in the [docs/results/](docs/results/) directory.*

## Key Specifications

| Parameter | Value |
|---|---|
| Array Architecture | Weight-Stationary Systolic Array |
| Array Size | 20 rows x 8 columns |
| Processing Elements | 160 DSP48E1 MAC units |
| Data Type (Input/Weights) | INT8 (signed 8-bit) |
| Accumulator | INT32 (signed 32-bit) |
| PE Pipeline Depth | 3 stages |
| Target Clock | 125 MHz |
| Target Device | Xilinx xc7z020clg400-1 (Zynq-7020) |
| Target Board | PYNQ-Z2 |
| Control Interface | AXI4-Lite (32 CSR registers) |
| DMA Interface | AXI4-Full Master (weight load + output store) |
| Data Input | AXI4-Stream Slave (32-bit, 4 channels/beat) |
| Data Output | AXI4-Stream Master (32-bit, 4 channels/beat) |
| Weight Buffer | Dual-bank ping-pong (software-managed) |
| Activation Buffer | 20x ping-pong (one per PE row) |
| IP Packaging | Vivado IP Repository (component.xml) |
| Vivado Version | 2025.1 |
| RTL Language | Verilog-2001 (synthesizable, no FPGA primitives) |
| Testbench Language | SystemVerilog (IEEE 1800-2012) |

---

## Features

### Processing Engine

| Feature | Description |
|---|---|
| Systolic Array | 20x8 weight-stationary array; data flows row-by-row |
| Processing Element | 3-stage pipelined: multiply -> truncate -> accumulate |
| DSP Mapping | Both inputs sign-extended to 18 bits for guaranteed DSP48E1 inference |
| Weight Buffer | Dual-bank BRAM with software ping-pong for DMA overlap |

### Post-Processing Pipeline

| Stage | Capability |
|---|---|
| Requantization | Per-channel INT32->INT8: output = clamp((acc + bias) * M0 >> n_shift) |
| Activation | ReLU, ReLU6, Leaky ReLU (alpha=1/8), HardSwish (LUT), Identity |
| Pooling | 2x2 MaxPool, 2x2 AvgPool, Bypass |
| BBox Decoder | YOLOv8 anchor-free: (l,t,r,b) -> absolute (x1,y1,x2,y2) coordinates |
| Confidence Gate | Threshold filter suppresses detections below CSR-configured threshold |

### System Features

| Feature | Description |
|---|---|
| Dual Operating Modes | CNN convolution mode / Cosine similarity (face embedding) mode |
| Spatial Crop | axis_sink supports runtime-configurable crop window |
| Performance Counters | 64-bit cycle count, 64-bit compute count, 32-bit stall counters |
| Interrupt | Asserts on inference completion when IRQ enabled |
| Clock Gating | 3 independent clock domains (compute, postproc, DMA) with ICG cells |
| Depthwise Conv | 3x3 depthwise line buffer engine for depthwise separable convolutions |

---

## Repository Structure

```
TinyNPU200/
|
|-- IP/TinyNPU200/
|   |-- component.xml          <- Vivado IP packager descriptor
|   |-- src/                   <- All 21 synthesizable RTL source files
|   |   |-- tinynpu_top.v      <- Top-level module
|   |   |-- npu_controller.v   <- Main FSM
|   |   |-- dma_controller.v   <- AXI4-Full DMA master
|   |   |-- systolic_array.v   <- 20x8 PE grid
|   |   |-- processing_element.v  <- 3-stage DSP48E1 MAC PE
|   |   |-- weight_buffer.v    <- Dual-bank weight BRAM
|   |   |-- activation_buffer.v   <- Per-row ping-pong BRAM
|   |   |-- axis_sink.v        <- AXI-Stream input + crop
|   |   |-- axis_source.v      <- AXI-Stream output
|   |   |-- requantization_unit.v <- INT32->INT8 requantizer
|   |   |-- activation_unit.v  <- 5-mode activation fn
|   |   |-- pooling_unit.v     <- 2x2 Max/Avg/Bypass pool
|   |   |-- bbox_decoder.v     <- YOLOv8 anchor-free decode
|   |   |-- threshold_filter.v <- Confidence gate
|   |   |-- output_buffer.v    <- Output FIFO
|   |   |-- dw_line_buffer.v   <- 3x3 depthwise conv engine
|   |   |-- axi4_lite_slave.v  <- AXI4-Lite CSR (32 registers)
|   |   |-- tinynpu_icg.v      <- Tech-independent clock gate
|   |   |-- hardswish_lut.v    <- HardSwish LUT
|   |   |-- piecewise_sigmoid.v   <- Sigmoid approximation
|   |   |-- pipelined_mult_8x8.v  <- 8x8 pipelined multiply
|   |   `-- dummy_weights.hex  <- Weight memory init file
|   `-- sim/
|       |-- tb_tinynpu_top.sv  <- SystemVerilog testbench (5 tests, all PASS)
|       `-- dummy_weights.hex  <- Simulation weights
|
|-- tinynpu200_ip_packager/
|   `-- tinynpu200_ip_packager.xpr  <- Vivado project (simulation + IP packaging)
|
|-- docs/
|   |-- PROJECT_REPORT.md      <- Full technical report
|   |-- USER_MANUAL.md         <- Step-by-step integration guide
|   |-- VERIFICATION.md        <- Testbench and test case documentation
|   |-- IP_INTEGRATION.md      <- RTL instantiation and IP import guide
|   `-- images/                <- Architecture diagrams
|
|-- scripts/
|   `-- run_simulation_portable.tcl  <- Path-independent simulation script
|
|-- run_all.tcl                <- Vivado batch simulation script
|-- run_simulation.bat         <- Windows one-click simulation launcher
|-- tinynpu_master.xdc         <- Constraints (PYNQ-Z2: HDMI pins, clocks)
|
|-- README.md                  <- This file
|-- ACCESS.md                  <- IP access policy
|-- TERMS_OF_USE.md            <- Usage terms (proprietary)
|-- CHANGELOG.md               <- Version history
`-- CONTRIBUTING.md            <- Contribution guidelines
```

---

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/HariharanGanesh/TinyNPU200.git
cd TinyNPU200
```

### 2. Run Simulation (Windows)

```
Double-click: run_simulation.bat
```

Or from command line:
```bash
"D:/2025.1/Vivado/bin/vivado.bat" -mode batch -source run_all.tcl
```

Or using the portable script:
```bash
vivado -mode batch -source scripts/run_simulation_portable.tcl
```

### 3. Expected Result

```
TOTAL TESTS : 5
PASSED      : 5
FAILED      : 0
SIMULATION PASSED
```

### 4. Open in Vivado GUI

```bash
vivado tinynpu200_ip_packager/tinynpu200_ip_packager.xpr
```

---

## Verification

The RTL is verified via a comprehensive SystemVerilog testbench (`tb_tinynpu_top.sv`) simulating the full AXI interconnect behavior. The testbench dynamically generates a formatted Tcl Console report covering 9 rigorous testcases.

**Current Test Coverage (Phase 2):**
1. **TC1:** Reset & Initialization (PASS)
2. **TC2:** Basic CSR Read/Write (PASS)
3. **TC3:** Boundary & Stress Checks (PASS)
4. **TC4:** AXI Control & Handshaking (PASS)
5. **TC5:** End-to-End Inference Verification (MATCH / PASS)
6. **TC6:** Dynamic Inference Latency Calculation (PASS - precise `$realtime` extraction)
7. **TC7:** Throughput Tracking (PASS)
8. **TC8:** Multi-Sample Accuracy Framework (PASS)
9. **TC9:** Reference Model Comparison Framework (PASS)


## IP Access

> **The project documentation is publicly available.**
> **The IP itself is not released under an open-source license.**
> **Use of the RTL/IP requires explicit written authorization from the author.**

### How to Request Access

**Option 1: GitHub Issue**

[Submit an IP Access Request](../../issues/new?template=ip-access-request.md)

**Option 2: Email**

hariharanganesh67@gmail.com

Include in your request:
- Your name and organization/university
- Intended use (academic / research / evaluation / commercial)
- Project description
- Whether the IP will be modified or redistributed

### Access Workflow

```
User discovers public repository
             |
    Reads documentation
             |
    Wants to use the IP
             |
 Submits IP Access Request
             |
  Author reviews the request
          /     \
    APPROVED   REJECTED
        |
Author provides authorized
access or distribution method
```

### For Authorized Users

Authorized users must:
- Retain full attribution to the original author
- Not redistribute the IP without separate written permission
- Not claim the IP as their own work
- Stay within the authorized scope of use

See [ACCESS.md](ACCESS.md) and [TERMS_OF_USE.md](TERMS_OF_USE.md) for complete policy.

> **Important:** GitHub repository visibility does not constitute a software license.
> Legal permission requires explicit written authorization from the author.

---

## Interface Summary

| Interface | Type | Direction | Description |
|---|---|---|---|
| S_AXI | AXI4-Lite Slave | Input | Control and status register access |
| M_AXI | AXI4-Full Master | Output | DMA weight load and result store |
| S_AXIS | AXI4-Stream Slave | Input | Activation data input (4 ch/beat) |
| M_AXIS | AXI4-Stream Master | Output | Processed output (4 ch/beat) |
| aclk | Clock | Input | System clock (125 MHz) |
| aresetn | Reset | Input | Active-low synchronous reset |
| interrupt | Signal | Output | Inference-done interrupt |

---

## CSR Quick Reference

| Offset | Register | Description |
|---|---|---|
| 0x00 | CTRL | Start [0], soft_reset [1], wgt_bank_sel [4], cosine_sim [5] |
| 0x04 | STATUS | idle [0], busy [1], done [2], error [3] |
| 0x08 | WEIGHT_BASE | DMA weight source address |
| 0x14 | LAYER_CFG_0 | {H, W, OutC, InC} - Layer geometry |
| 0x18 | LAYER_CFG_1 | {padding, stride, kernel} |
| 0x1C | LAYER_CFG_2 | {tiles_y, tiles_x} |
| 0x20 | SCALE_M0 | Requantization scale factor |
| 0x24 | SHIFT_N | Requantization right-shift |
| 0x28 | IRQ_CTRL | IRQ enable [0] |

---

## Documentation

| Document | Description |
|---|---|
| [PROJECT_REPORT.md](docs/PROJECT_REPORT.md) | Full technical report: architecture, data path, interfaces, verification |
| [USER_MANUAL.md](docs/USER_MANUAL.md) | Step-by-step guide: import, configure, integrate, simulate, implement |
| [VERIFICATION.md](docs/VERIFICATION.md) | Testbench architecture, test cases, expected results, simulation output |
| [IP_INTEGRATION.md](docs/IP_INTEGRATION.md) | RTL instantiation, Vivado IP import, AXI connections, troubleshooting |
| [ACCESS.md](ACCESS.md) | IP access policy and authorization process |
| [TERMS_OF_USE.md](TERMS_OF_USE.md) | Usage terms (proprietary, all rights reserved) |
| [CHANGELOG.md](CHANGELOG.md) | Version history |

---

## Attribution

**Author:** Hariharan Ganesh
**Email:** hariharanganesh67@gmail.com
**GitHub:** https://github.com/HariharanGanesh
**Copyright:** Copyright (c) 2026 Hariharan Ganesh. All rights reserved.

If this IP or authorized derivative work is used in academic projects, research,
publications, presentations, demonstrations, or technical reports, the original
author and project must be appropriately credited:

```
TinyNPU200 IP Core - Original work by Hariharan Ganesh (2026)
GitHub: https://github.com/HariharanGanesh/TinyNPU200
Contact: hariharanganesh67@gmail.com
```

---

## Contact

**Hariharan Ganesh**
For IP access requests, technical questions, or collaboration:

- Email: hariharanganesh67@gmail.com
- GitHub: https://github.com/HariharanGanesh
- IP Access Request: [Submit via GitHub Issues](../../issues/new?template=ip-access-request.md)

---

*Copyright (c) 2026 Hariharan Ganesh. All rights reserved.*
*This IP is proprietary. See TERMS_OF_USE.md and ACCESS.md.*

### AXI-Stream TLAST Semantics
In the TinyNPU200 architecture, the m_axis_tlast signal represents the **End of Tile**. It is asserted precisely on the final byte of the final word of each processed activation tile, allowing downstream DMAs (e.g., AXI DMA) to segment incoming data properly per-tile.
