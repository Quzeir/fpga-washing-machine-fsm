# FPGA Automatic Washing Machine Controller (FSM)

## 📌 Overview

This project implements an FPGA-based automatic washing machine controller using a Finite State Machine (FSM) in Verilog HDL. The system manages the full washing cycle including filling, washing, rinsing, spinning, and fault handling.

---

## ⚙️ System Architecture

The system follows this structure:

Inputs → FSM Controller → Outputs

### Inputs:

* clk
* reset
* door_closed
* water_level
* motor_fault

### Outputs:

* LED indicators
* 7-segment display

---

## 🧠 FSM Operation

The controller transitions through the following states:

READY → FILL → WASH → RINSE → SPIN → READY

If a fault is detected:
→ The system transitions to FAULT state and halts operation
→ Returns to READY after the fault is cleared

State transitions are controlled using counters and input signals.

---

## 🧠 FSM Diagram

![FSM](docs/fsm_diagram.png)

---

## 📊 Simulation Results

The system was verified using waveform simulation to validate:

* Correct state transitions
* Timing accuracy
* Fault handling behavior

![Waveform](simulation/waveform.png)

---

## 🛠️ Technologies Used

* Verilog HDL
* Quartus II 9.1
* Altera DE2 FPGA Board

---

## 🚀 Features

* FSM-based digital control system
* Time-controlled washing cycles
* Fault detection and recovery
* Real-time FPGA implementation

---

## 📁 Project Structure

* `src/` → Verilog source code
* `docs/` → FSM diagram
* `simulation/` → waveform results

---

## 📌 Key Learning Outcomes

* FSM design and implementation
* Verilog HDL development and debugging
* FPGA-based system deployment
* Digital system timing control

---

## 🔧 Future Improvements

* Add sensor-based automation
* Integrate LCD or user interface
* Optimize power consumption

---

## 👨‍💻 Author

Muhammad Quzeir Al-Azim
