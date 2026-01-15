# Agent-Inspired-Fault-Detection-and-Supervisory-Control-for-Industrial-Processes
Real-time Fault Detection &amp; Supervisory Control framework for a biopharmaceutical processes. Integrates Random Forest ML and SHAP analysis for robust diagnostics. Features a Python-Simulink MQTT bridge for autonomous closed-loop control, effectively mitigating sensor noise, actuator drift.
Overview

Welcome to the repository for the **Agent-Inspired Fault Detection and Supervisory Control System. This project implements a real-time, data-driven fault diagnosis framework combined with an autonomous supervisory decision layer.

The system utilizes a Random Forest classifier (and an ensemble of agents) to detect process faults in a continuous biopharmaceutical process. It communicates with the plant simulation (Simulink) via MQTT, enabling closed-loop supervisory control to mitigate faults such as sensor noise, actuator drifts, and metabolic anomalies.

Repository Structure

1. Core Scripts & Notebooks

 RF.ipynb: The central Jupyter Notebook containing the entire Python workflow. It allows you to:
     1st cell-Train the Random Forest models.
     2nd cell-Analyze feature importance using SHAP (Explainable AI).
     3rd cell-Execute the Real-Time MAS Bridge (MQTT Interface) for fault detection.
     4th cell-Also detect and Simulate the control logic.



2. Models & Artifacts

`rf_model.pkl`: The pre-trained main Random Forest classifier used for fault detection.
`rf_scaler.pkl`: The `RobustScaler` objects used to normalize incoming sensor data to match the training distribution.


3. Data & Logs

mas_logs_final.xlsx: The output log file generated after a simulation run. It records Time, Fault Predictions, Actuator states, and Latency.
OM0.xlsx - OM8.xlsx: (Input) Historical process data files representing Normal Operation (OM0) and various Fault Classes (OM1-OM8) used for training.

4. Figures & Output

shap_importance_bar.png: Visual ranking of the most critical sensors (e.g., `Data_9`, `Data_1`).
latency_histogram.png: Graph showing the real-time performance and computational delay of the control loop.


Fault Codes Reference

The system is trained to identify the following operational modes:

OM0: Normal Operation
OM1 - OM3: Biological/sensor Faults (Step, ramp and Pulse)
OM4: Sensor Noise (Lactose)  
OM5 - OM7: Biological/sensor Faults (Step, ramp and Pulse)
OM8: Sensor Noise (Adenine)  



Prerequisites

To run the Python interface, ensure the following libraries are installed:

pip install numpy pandas matplotlib seaborn scikit-learn shap joblib paho-mqtt psutil openpyxl





Instructions

To effectively use this system with the Simulink plant(KTB1_F), follow these steps:

Phase 1: Model Training (If needed)

1. Open `RF.ipynb`.
2. Ensure the training data (`OM0.xlsx` ... `OM8.xlsx`) is in the configured `DATA_DIR`.
3. Run the Training Cell to generate `rf_model.pkl` and `rf_scaler.pkl`.
4. Run the SHAP Analysis Cell to generate interpretability graphs and validate feature selection.

Phase 2: Real-Time Simulation

1. Start your MQTT Broker (e.g., Mosquitto) on `localhost:1883`.
2. Open MATLAB/Simulink: Load matlab model KTB1_F.slx.
   Ensure the MQTT blocks in Simulink are configured to subscribe to `fault_detection/live/control` and publish to `fault_detection/live/features`.


3. Run the Python Bridge:
   In `RF.ipynb`, navigate the third or fourth cell based on the necessity of just watching the detection only or detection and control part.


4. Start the Simulation:
Run the matlab script FaultBridgeDetection.m
Observe the Python console for real-time logs: e.g. `[T=15.0] Live:4 | Locked:0 | LacAct:0.00...`



Phase 3: Post-Simulation Analysis

1. Once the simulation reaches T=120, the Python script will auto-save the logs.
2. Check `mas_logs_final.xlsx` for detailed performance data.
3. Review `latency_histogram.png` to verify the control loop speed.
