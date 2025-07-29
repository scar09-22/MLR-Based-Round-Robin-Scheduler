# MLR-RR: Predictive Dynamic Time Quantum Scheduling for Round Robin

This project simulates and compares the performance of two Round Robin (RR) CPU scheduling strategies:

- **Traditional RR** using a fixed time quantum 
- **MLR-RR**: A Machine Learning Regression (MLR)-based dynamic RR, where time quantum is predicted based on system metrics

The goal is to evaluate whether dynamically tuning the time quantum using real system characteristics improves key performance metrics.

---

## Features

- Simulates 1000 processes with randomized burst times, arrival times, and I/O behaviors
- Supports fixed and ML-predicted time quantum values
- Trains a **Lasso-regularized linear regression** model on system metrics
- Predicts optimal time quantum in real-time
- Compares:
  - Average Turnaround Time
  - Average Waiting Time
  - Average Response Time
  - Throughput
  - Context Switches
- Includes rich visualizations (boxplots, bar charts, per-process trends)

---

## Model Inputs

The MLR model is trained on historical system metrics:

- Average CPU usage
- Number of active processes
- I/O throughput (bytes/sec)
- Context switches per second
- Memory usage (%)

These metrics are normalized using z-score normalization.

---

## Requirements

* MATLAB R2020a or higher
* Statistics and Machine Learning Toolbox

---

## Running the Project

1. **Train the MLR Model** (only once unless the dataset changes):

   >> MLRmodel

2. **Run Simulation and Comparison**:

   >> compareRR

   It loads the trained model, runs both scheduling strategies, and outputs a full metric comparison with plots.

---

## Results

<img width="1121" height="467" alt="Image" src="https://github.com/user-attachments/assets/bdb505e5-1d2f-4534-8404-2fae26f7ae02" />

<img width="1100" height="439" alt="Image" src="https://github.com/user-attachments/assets/17ffd377-6333-4e96-b109-74eb88f45e76" />

<img width="1093" height="440" alt="Image" src="https://github.com/user-attachments/assets/331ad1de-1549-4837-b22d-0cf9ca770db9" />

<img width="1087" height="439" alt="Image" src="https://github.com/user-attachments/assets/1ee6a664-011a-45e3-8171-ac63563c222f" />

<img width="1121" height="467" alt="Image" src="https://github.com/user-attachments/assets/ed0039ce-e77c-4565-ba4c-4da870f1b719" />
