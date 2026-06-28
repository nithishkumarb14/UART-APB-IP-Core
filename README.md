# APB UART IP Core with FIFO & Interrupt Controller

> A reusable, production-style UART peripheral built in SystemVerilog — featuring APB bus integration, dual FIFO buffering, configurable baud rate, and a maskable interrupt controller.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Module Descriptions](#module-descriptions)
- [Register Map](#register-map)
- [Interrupt Architecture](#interrupt-architecture)
- [FIFO Architecture](#fifo-architecture)
- [Baud Rate Configuration](#baud-rate-configuration)
- [SystemVerilog Features](#systemverilog-features)
- [Folder Structure](#folder-structure)
- [Simulation Waveform](#simulation-waveform)
- [How to Simulate](#how-to-simulate)
- [Design Methodology](#design-methodology)
- [Skills Demonstrated](#skills-demonstrated)

---

## Overview

This project implements a fully functional **UART IP Core** interfaced over the **APB (Advanced Peripheral Bus)** protocol. It was designed to mimic the architecture of real-world UART peripherals found in microcontrollers and SoCs.

**Key highlights:**
- APB-compliant register interface (IDLE → SETUP → ACCESS FSM)
- 8-deep TX and RX FIFOs with overflow/underflow detection
- Configurable baud rate via software register (supports 9600, 115200, etc.)
- 8-source maskable interrupt controller with IRQ output
- Self-checking testbench simulating CPU APB writes
- Embedded SVA assertions in every module for protocol verification

---

## Architecture

```
        ┌─────────────────────────────────────────────────────────────┐
        │                        uart_top                              │
        │                                                             │
        │  ┌──────────────┐    ┌──────────┐    ┌──────────────────┐  │
        │  │  APB Wrapper │───▶│  TX FIFO │───▶│    UART TX       │  │
        │  │  (uart_wrap) │    └──────────┘    └──────┬───────────┘  │
  APB ──┤  │              │                           │ tx_data_out  │
  Bus   │  │  IDLE→SETUP  │    ┌──────────┐    ┌──────▼───────────┐  │
        │  │  →ACCESS FSM │◀───│  RX FIFO │◀───│    UART RX       │  │
        │  └──────┬───────┘    └──────────┘    └──────────────────┘  │
        │         │                                                   │
        │  ┌──────▼───────┐    ┌──────────────────────────────────┐  │
        │  │  Status Regs │    │  Baud Generator  │  Interrupt Ctrl│  │
        │  └──────────────┘    └──────────────────────────────────┘  │
        └─────────────────────────────────────────────────────────────┘
                                        │
                                       IRQ ──▶ CPU
```

> **Note:** In this implementation, TX output is looped back to RX input (`tx_data_out → rx`) for self-test and simulation purposes.

---

## Module Descriptions

| Module | File | Description |
|---|---|---|
| `uart_top` | `rtl/uart_top.sv` | Top-level: instantiates and connects all submodules |
| `uart_wrapper` | `rtl/uart_wrapper.sv` | APB register interface — decodes reads/writes, drives control/baud/TX regs |
| `tx` | `rtl/tx.sv` | Serial transmitter FSM: IDLE → LOAD → START → DATA → STOP |
| `rx` | `rtl/rx.sv` | Serial receiver FSM: IDLE → START_CHECKER → RECEIVE → STOP |
| `tx_fifo` | `rtl/tx_fifo.sv` | 8-deep synchronous TX FIFO with 4-bit gray-style pointers |
| `rx_fifo` | `rtl/rx_fifo.sv` | 8-deep synchronous RX FIFO with overflow/underflow flags |
| `baud_rate` | `rtl/baud_rate.sv` | Baud tick generator — divides 50 MHz clock by baud divisor |
| `interrupt` | `rtl/interrupt.sv` | Combinational IRQ from 8 maskable interrupt sources |
| `cpu_tb` | `tb/cpu_tb.sv` | Self-checking testbench simulating APB write sequences |

---

## Register Map

| Address | Register | Access | Description |
|---|---|---|---|
| `0x00` | `CONTROL_REG` | R/W | Interrupt enable mask (bit per source) |
| `0x04` | `STATUS_REG` | R | UART and FIFO status flags |
| `0x08` | `BAUD_REG` | R/W | Baud rate divisor (e.g., 9600) |
| `0x0C` | `TX_DATA_REG` | W | CPU writes byte to TX FIFO |
| `0x10` | `RX_DATA_REG` | R | CPU reads byte from RX FIFO |

### STATUS_REG Bit Map

| Bit | Signal | Description |
|---|---|---|
| [0] | `tx_done` | TX transmission complete |
| [1] | `rx_done` | RX byte received |
| [2] | `tx_fifo_empty` | TX FIFO is empty |
| [3] | `tx_fifo_full` | TX FIFO is full |
| [4] | `rx_fifo_empty` | RX FIFO is empty |
| [5] | `rx_fifo_full` | RX FIFO is full |
| [6] | `tx_fifo_overflow` | Write to full TX FIFO |
| [7] | `rx_fifo_overflow` | Write to full RX FIFO |

---

## Interrupt Architecture

The interrupt controller is a **purely combinational** module. Each of the 8 interrupt sources has a corresponding enable bit in `CONTROL_REG`. The IRQ fires when any enabled event is active:

```
irq = (tx_done_en & tx_done) | (rx_done_en & rx_done) |
      (tx_fifo_emp_en & tx_fifo_emp) | (tx_fifo_full_en & tx_fifo_full) |
      (rx_fifo_emp_en & rx_fifo_emp) | (rx_fifo_full_en & rx_fifo_full) |
      (tx_fifo_overflow_en & tx_fifo_overflow) | (rx_fifo_overflow_en & rx_fifo_overflow)
```

The CPU identifies the exact interrupt cause by reading `STATUS_REG`.

---

## FIFO Architecture

Both TX and RX FIFOs are **8-deep, 8-bit wide** synchronous FIFOs implemented with 4-bit wrap-around pointers (MSB used as wrap bit for full/empty detection).

```
Full  condition: write_ptr[2:0] == read_ptr[2:0] && write_ptr[3] != read_ptr[3]
Empty condition: write_ptr == read_ptr
```

SVA assertions guard against writes to a full FIFO and reads from an empty FIFO.

---

## Baud Rate Configuration

The baud generator divides the system clock (50 MHz) by the value written to `BAUD_REG`:

```
cycle = clk_freq / baud_rate_hex
      = 50,000,000 / 9600 = 5208 clock cycles per bit
```

- `baud_tick` fires once per bit period (at end of cycle)
- `baud_tick_half` fires at mid-bit (used by RX for center sampling)

| Baud Rate | Divisor | Cycle Count |
|---|---|---|
| 9600 | 9600 | 5208 |
| 115200 | 115200 | 434 |

---

## SystemVerilog Features

| Feature | Usage |
|---|---|
| `enum` | FSM state encoding in TX, RX, APB wrapper |
| `package` | Register addresses (`uart_pkg`) shared across modules |
| `SVA assertions` | Protocol checks in every RTL module |
| `always_ff / always_comb` | Separated sequential and combinational logic |
| `typedef` | State type abstraction |
| `logic` | Replacing `wire`/`reg` throughout |

---

## Folder Structure

```
uart-apb-ip-core/
│
├── README.md
│
├── rtl/                          # Synthesizable RTL
│   ├── uart_top.sv
│   ├── uart_wrapper.sv
│   ├── tx.sv
│   ├── rx.sv
│   ├── tx_fifo.sv
│   ├── rx_fifo.sv
│   ├── baud_rate.sv
│   ├── interrupt.sv
│   └── uart_pkg.sv               # Package: register addresses
│
├── tb/                           # Testbench
│   └── cpu_tb.sv                 # APB CPU stimulus + self-check
│
├── docs/                         # Documentation
│   ├── UART_APB_Architecture_Final.pdf
│   └── architecture_block_diagram.png
│
└── sim/                          # Simulation outputs
    └── waveforms/
        └── cpu_tb_behav.wcfg     # Vivado waveform config
```

---

## Simulation Waveform

The waveform below captures the end-state of a full simulation run. The CPU testbench writes 6 bytes (`127, 123, 125, 168, 148, 103`) over APB. All bytes are transmitted serially by the TX module, looped back to RX, and stored in the RX FIFO.

![Simulation Waveform](docs/waveforms/cpu_tb_behav.png)

**Key observations from the waveform:**
- `tx curr_state` returns to `IDLE` after completing all transmissions
- `rx_fifo[0:7]` shows `127, 123, 125, 168, 148, 103` — all 6 bytes received correctly
- `tx_data_in` holds the last byte (`103`) at simulation end
- `irq` asserts high — driven by `tx_fifo_empty` interrupt enable in `CONTROL_REG`
- `PRDATA` reflects `0` (no active APB read at end of simulation window)
- `shift_reg` clears to `0` after final byte is shifted out
- `rx_done` pulses once per received byte (each triggers `rx_fifo_wrt_en`)

---

## How to Simulate

This project was developed and simulated in **Vivado 2020.2** (Behavioral Simulation).

**Steps:**

1. Clone the repository:
   ```bash
   git clone https://github.com/nithishkumarb14/UART-APB-IP-Core.git
   cd UART-APB-IP-Core
   ```

2. Open Vivado, create a new project, and add all files from `rtl/` and `tb/` as sources.

3. Set `cpu_tb.sv` as the simulation top module.

4. Run Behavioral Simulation → the waveform will show APB write transactions and UART loopback.

5. To load the waveform layout: **File → Open Waveform Configuration** → select `sim/waveforms/cpu_tb_behav.wcfg`.

> **Tested on:** Vivado 2020.2 | Target: xc7z020clg400-1 (PYNQ-Z2)

---

## Design Methodology

This project followed an incremental, verification-first development flow:

1. Defined architecture and register map
2. Built APB wrapper with FSM-based protocol handling
3. Implemented TX and RX FIFOs with pointer-based full/empty logic
4. Implemented UART TX and RX FSMs
5. Added baud rate generator (50 MHz ÷ baud_rate)
6. Built combinational interrupt controller
7. Added SVA assertions in every module
8. Wrote self-checking CPU testbench with `apb_write` task
9. Debugged timing — fixed `tx_wrt_en` auto-clear in IDLE, FIFO pointer race conditions

---

## Skills Demonstrated

- **RTL Design** — Multi-module SystemVerilog design with clean interface boundaries
- **Protocol Implementation** — APB FSM: IDLE → SETUP → ACCESS
- **FIFO Design** — Synchronous FIFO with wrap-around pointer arithmetic
- **Formal-style Assertions** — SVA `assert property` for protocol and timing checks
- **UART Protocol** — Start bit detection, mid-bit sampling, stop bit verification
- **Testbench Development** — Reusable `apb_write` task, reset sequencing, multi-byte stimulus
- **Interrupt Design** — Maskable IRQ with status register readback pattern

---

*Built as part of an RTL Design portfolio targeting VLSI/FPGA fresher roles.*  
*GitHub: [@nithishkumarb14](https://github.com/nithishkumarb14)*
