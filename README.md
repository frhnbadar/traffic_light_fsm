# Traffic Light FSM

A parameterized Traffic Light Controller implemented in SystemVerilog using a finite state machine (FSM).

The design controls traffic at a two-road intersection:

- North/South (NS)
- East/West (EW)

The controller cycles through green and yellow phases while ensuring that both directions can never have a green light simultaneously.

The project also includes a self-checking SystemVerilog testbench with assertions, functional coverage, timing checks, and waveform generation.

---

## Project Overview

The controller is implemented as a four-state FSM:

```
NS_GREEN → NS_YELLOW → EW_GREEN → EW_YELLOW → NS_GREEN → ...
```

The sequence repeats continuously.

---

## Features

### RTL
- 4-state finite state machine
- SystemVerilog enumerated states
- Parameterized green-light timing
- Parameterized yellow-light timing
- Synchronous state transitions
- Synchronous reset
- Clock-driven counter
- Safe default output state
- Separate NS and EW traffic signals

### Verification
- Self-checking testbench
- Automated output checking
- Timing verification
- Safety assertions
- FSM state validation
- Functional state coverage
- Multiple complete FSM cycles
- Waveform generation
- Siemens Questa simulation support
- Makefile-based simulation flow

---

## Traffic Light Behavior

**North/South signals:** `ns_red`, `ns_yellow`, `ns_green`
**East/West signals:** `ew_red`, `ew_yellow`, `ew_green`

Only one direction is allowed to have a green light at a time.

| FSM State  | North/South | East/West |
|------------|-------------|-----------|
| NS_GREEN   | GREEN       | RED       |
| NS_YELLOW  | YELLOW      | RED       |
| EW_GREEN   | RED         | GREEN     |
| EW_YELLOW  | RED         | YELLOW    |

The FSM then returns to `NS_GREEN` and repeats the cycle.

---

## FSM States

The states are defined using a SystemVerilog enumerated type:

```systemverilog
typedef enum logic [1:0] {
    NS_GREEN,
    NS_YELLOW,
    EW_GREEN,
    EW_YELLOW
} state_t;
```

**NS_GREEN** — North/South traffic is allowed to move.
`NS = GREEN`, `EW = RED`

**NS_YELLOW** — North/South traffic is transitioning to red.
`NS = YELLOW`, `EW = RED`

**EW_GREEN** — East/West traffic is allowed to move.
`NS = RED`, `EW = GREEN`

**EW_YELLOW** — East/West traffic is transitioning to red.
`NS = RED`, `EW = YELLOW`

---

## Timing

The duration of the green and yellow states is controlled using parameters:

```systemverilog
parameter int GREEN_TIME  = 10;
parameter int YELLOW_TIME = 3;
```

For example:

```
GREEN_TIME  = 5
YELLOW_TIME = 2
```

results in:

```
NS_GREEN   → 5 clock cycles
NS_YELLOW  → 2 clock cycles
EW_GREEN   → 5 clock cycles
EW_YELLOW  → 2 clock cycles
```

The controller then returns to `NS_GREEN`.

---

## Reset Behavior

The FSM uses a synchronous reset.

When reset is asserted:

```
State   → NS_GREEN
Counter → 0
```

Therefore, after reset:

```
North/South = GREEN
East/West   = RED
```

---

## RTL Architecture

The design consists of three main parts:

```
Next-State Logic → State + Counter Registers → Output Logic
                          ▲                          │
                          └──────── Feedback ─────────┘
```

**State Register** — Stores the current FSM state.

**Counter** — Tracks how long the FSM has remained in the current state.

**Next-State Logic** — Determines when the FSM should transition to the next state.

**Output Logic** — Generates the traffic light outputs based on the current FSM state.

---

## Repository Structure

```
traffic-light-fsm/
│
├── rtl/
│   └── traffic_light_fsm.sv
│
├── tb/
│   └── traffic_light_fsm_tb.sv
│
├── docs/
│   └── waveform.png
│
├── Makefile
├── README.md
├── .gitignore
└── LICENSE
```

- **`rtl/`** — Contains the synthesizable SystemVerilog RTL.
- **`tb/`** — Contains the SystemVerilog verification environment. The testbench performs reset testing, output checking, timing verification, safety assertions, FSM state coverage, multiple FSM cycles, and final PASS/FAIL reporting.
- **`docs/`** — Contains documentation assets such as waveform screenshots.
- **`Makefile`** — Provides command-line compilation and simulation commands.
- **`.gitignore`** — Prevents generated simulator files from being committed.

---

## Verification

The testbench is designed to automatically detect incorrect behavior instead of relying only on manual waveform inspection.

**Verification flow:**

```
DUT → Testbench → [Output Checks, Assertions, Coverage] → PASS / FAIL
```

### Self-Checking Testbench

The testbench checks the expected outputs for every FSM state.

For example, in `NS_GREEN`:

```
NS: RED = 0, YELLOW = 0, GREEN = 1
EW: RED = 1, YELLOW = 0, GREEN = 0
```

If the DUT produces an incorrect combination, the testbench reports an error, e.g.:

```
ERROR: NS_GREEN OUTPUT ERROR
```

The same checking is performed for all four states.

### Safety Assertions

The testbench contains assertions for critical safety requirements.

**Both directions must never be GREEN:**

```systemverilog
assert (!(ns_green && ew_green))
else
    $error("Both directions are GREEN!");
```

This ensures `NS_GREEN = 1` and `EW_GREEN = 1` can never occur simultaneously.

**NS GREEN requires EW RED:**

```systemverilog
assert (!ns_green || ew_red)
else
    $error("NS GREEN while EW is not RED!");
```

Equivalent to: IF NS is GREEN, THEN EW must be RED.

**EW GREEN requires NS RED:**

```systemverilog
assert (!ew_green || ns_red)
else
    $error("EW GREEN while NS is not RED!");
```

Equivalent to: IF EW is GREEN, THEN NS must be RED.

**One light per direction:**

```systemverilog
// North/South
assert ($onehot0({ns_red, ns_yellow, ns_green}))
else
    $error("Multiple NS lights are ON!");

// East/West
assert ($onehot0({ew_red, ew_yellow, ew_green}))
else
    $error("Multiple EW lights are ON!");
```

### Functional Coverage

The testbench tracks whether every FSM state has been visited:

```
NS_GREEN  : HIT
NS_YELLOW : HIT
EW_GREEN  : HIT
EW_YELLOW : HIT
```

This confirms that all states of the FSM have been exercised during simulation.

---

## Running the Project

The project can be run in two ways:

1. EDA Playground
2. Local Siemens Questa installation

### Running on EDA Playground

The easiest way to simulate this project is directly in your browser using [EDA Playground](https://www.edaplayground.com/) — no local simulator installation required.

**Step 1 — Select the Language**
Select **SystemVerilog** (make sure SystemVerilog is selected rather than Verilog).

**Step 2 — Select the Simulator**
Under **Tools & Simulators**, select **Siemens Questa** (e.g. Siemens Questa 2025.2). The available simulator versions may change over time.

**Step 3 — Add the RTL**
Copy the contents of `rtl/traffic_light_fsm.sv` into the Design window.

**Step 4 — Add the Testbench**
Copy the contents of `tb/traffic_light_fsm_tb.sv` into the Testbench window.

The testbench automatically generates the clock, applies reset, runs the FSM, performs checks, and reports the result. No additional stimulus is required.

**Step 5 — Run**
Click **Run**. EDA Playground will compile and simulate the design using Siemens Questa.

A successful simulation should produce output similar to:

```
==============================================
     TRAFFIC LIGHT FSM VERIFICATION
==============================================

GREEN_TIME  = 5 cycles
YELLOW_TIME = 2 cycles

----------------------------------------------
FUNCTIONAL COVERAGE
----------------------------------------------
NS_GREEN  : HIT
NS_YELLOW : HIT
EW_GREEN  : HIT
EW_YELLOW : HIT

==============================================
        ALL TESTS PASSED
        ERRORS = 0
==============================================
```

The exact simulator output may vary depending on the Questa version and configuration.

#### EDA Playground File Mapping

The GitHub repository uses:

```
traffic-light-fsm/
├── rtl/
│   └── traffic_light_fsm.sv
└── tb/
    └── traffic_light_fsm_tb.sv
```

EDA Playground does not require you to reproduce this folder structure. Simply use:

```
EDA Playground
├── Design
│   └── traffic_light_fsm.sv
└── Testbench
    └── traffic_light_fsm_tb.sv
```

Copy the corresponding file contents into the appropriate editor.

#### About `run.do`

A `run.do` file is not required for the normal EDA Playground Run flow when Siemens Questa is configured to compile and execute the design directly. If EDA Playground specifically requires a `.do` script for a particular configuration, use the simulator's required command flow. The GitHub project does not depend on a `run.do` file.

### Running Locally with Siemens Questa

If Siemens Questa is installed locally, the project can be compiled manually from the repository root:

**1. Compile RTL**
```bash
vlog -sv rtl/traffic_light_fsm.sv
```

**2. Compile Testbench**
```bash
vlog -sv tb/traffic_light_fsm_tb.sv
```

**3. Start Simulation**
```bash
vsim work.traffic_light_fsm_tb
```

**4. Run Simulation**

Inside Questa:
```bash
run -all
```

The testbench automatically performs the checks and reports the final result.

### Running Using Makefile

The repository also provides a Makefile for command-line simulation.

**Compile**
```bash
make compile
```

**Run Simulation**
```bash
make run
```

**Clean Generated Files**
```bash
make clean
```

The Makefile uses Siemens Questa commands such as `vlog` and `vsim`. Make sure Questa is installed and its executables are available in your system `PATH`.

---

## Waveform Analysis

The testbench generates waveform information for debugging. Important signals to inspect include:

- `clk`, `reset`
- `dut.state`, `dut.next_state`, `dut.counter`
- `ns_red`, `ns_yellow`, `ns_green`
- `ew_red`, `ew_yellow`, `ew_green`

The expected sequence is:

```
NS_GREEN → NS_YELLOW → EW_GREEN → EW_YELLOW → NS_GREEN → ...
```

The most important safety behavior to verify visually is:

```
NS_GREEN → EW_RED
EW_GREEN → NS_RED
```

Both directions must never be green simultaneously.

A waveform screenshot can be found in `docs/waveform.png`.

### Example Timing

For `GREEN_TIME = 5` and `YELLOW_TIME = 2`, the FSM operates approximately as:

| Clock | State     |
|-------|-----------|
| 1     | NS_GREEN  |
| 2     | NS_GREEN  |
| 3     | NS_GREEN  |
| 4     | NS_GREEN  |
| 5     | NS_YELLOW |
| 6     | NS_YELLOW |
| 7     | EW_GREEN  |
| 8     | EW_GREEN  |
| 9     | EW_GREEN  |
| 10    | EW_GREEN  |
| 11    | EW_GREEN  |
| 12    | EW_YELLOW |
| 13    | EW_YELLOW |
| 14    | NS_GREEN  |
| ...   | ...       |

The exact state boundary observed in simulation depends on reset release and the sampling point used by the testbench.

---

## Safety Design

The output logic uses a safe default condition:

```systemverilog
ns_red    = 1'b1;
ns_yellow = 1'b0;
ns_green  = 1'b0;

ew_red    = 1'b1;
ew_yellow = 1'b0;
ew_green  = 1'b0;
```

If the FSM reaches the default case, both directions fall back to RED (`NS = RED`, `EW = RED`). This prevents an invalid FSM state from accidentally producing a green signal.

---

## Current Design Limitation

The current counter is declared as:

```systemverilog
logic [$clog2(GREEN_TIME+1)-1:0] counter;
```

Therefore, the current implementation assumes that the selected timing parameters fit within the counter width. For the tested configuration (`GREEN_TIME = 5`, `YELLOW_TIME = 2`), the counter is sufficient.

A future revision can calculate the counter width using the maximum of `GREEN_TIME` and `YELLOW_TIME` to make the parameterization fully robust for arbitrary timing values.

---

## Verification Checklist

- [x] Synchronous reset
- [x] NS Green state
- [x] NS Yellow state
- [x] EW Green state
- [x] EW Yellow state
- [x] Parameterized green timing
- [x] Parameterized yellow timing
- [x] Self-checking testbench
- [x] Output verification
- [x] Safety assertions
- [x] `$onehot0` checks
- [x] FSM state coverage
- [x] Multiple FSM cycles
- [x] Waveform generation
- [x] Siemens Questa simulation
- [x] Makefile-based simulation flow
- [x] EDA Playground support

---

## Tools Used

| Tool           | Purpose                        |
|----------------|---------------------------------|
| SystemVerilog  | RTL Design & Verification       |
| Siemens Questa | Simulation                      |
| GTKWave        | Waveform Analysis               |
| GNU Make       | Simulation Automation           |
| Git            | Version Control                 |
| GitHub         | Project Hosting                 |
| EDA Playground | Browser-Based Simulation        |

---

## Future Improvements

Possible extensions to this project include:

- Fully robust parameterized counter width
- Traffic sensor inputs
- Pedestrian crossing support
- Emergency vehicle priority
- Configurable timing through registers
- Countdown timer output
- More complex intersection control
- Concurrent SystemVerilog Assertions (SVA)
- Dedicated functional coverage using covergroups
- Formal verification
- UVM-based verification environment

---

## Learning Objectives

This project demonstrates practical understanding of:

- Finite State Machines
- SystemVerilog enumerated states
- Sequential logic
- Combinational logic
- Clocked counters
- Parameterized RTL
- Synchronous reset
- Self-checking testbenches
- Assertions
- `$onehot0`
- Functional coverage
- Waveform debugging
- Simulation automation
- Siemens Questa

---

## Author

**MD Farhan Badar**
B.Tech Electronics — VLSI Design and Technology

This project was developed as part of an RTL Design and Verification learning roadmap.