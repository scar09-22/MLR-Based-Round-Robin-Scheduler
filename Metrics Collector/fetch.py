import psutil
import time
import numpy as np
import pandas as pd
from datetime import datetime

def get_enhanced_metrics(sample_duration=1):
    """Fetch system metrics with context switches and memory usage."""
    # Initialize metrics
    metrics = {
        "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "avg_cpu_percent": 0,
        "num_processes": 0,
        "io_bytes_sec": 0,
        "context_switches_sec": 0,
        "memory_percent": 0,
        "suggested_TQ_ms": 10  # Default fallback
    }

    # --- CPU and Processes ---
    metrics["avg_cpu_percent"] = psutil.cpu_percent(interval=0.1)
    metrics["num_processes"] = len(psutil.pids())

    # --- Disk I/O ---
    io_before = psutil.disk_io_counters()
    time.sleep(0.1)
    io_after = psutil.disk_io_counters()
    metrics["io_bytes_sec"] = (io_after.read_bytes + io_after.write_bytes - io_before.read_bytes - io_before.write_bytes) * 10

    # --- Context Switches (Linux/MacOS) ---
    ctx_before = psutil.cpu_stats().ctx_switches
    time.sleep(0.1)
    ctx_after = psutil.cpu_stats().ctx_switches
    metrics["context_switches_sec"] = max(0, (ctx_after - ctx_before) * 10)

    # --- Memory Usage ---
    metrics["memory_percent"] = psutil.virtual_memory().percent

    # --- Heuristic TQ Estimation ---
    metrics["suggested_TQ_ms"] = max(5, min(50, metrics["avg_cpu_percent"] * 0.5))

    return metrics


def log_enhanced_metrics(sample_interval=1, output_file="enhanced_metrics.csv"):
    """Continuously log metrics with new features."""
    print(f"Logging enhanced metrics every {sample_interval}s. Press Ctrl+C to stop.")
    while True:
        start_time = time.time()
        metrics = get_enhanced_metrics()

        # Print to console
        print(
            f"\rCPU: {metrics['avg_cpu_percent']:.1f}% | "
            f"Procs: {metrics['num_processes']} | "
            f"IO: {metrics['io_bytes_sec'] / 1024:.1f} KB/s | "
            f"CTX: {metrics['context_switches_sec']} | "
            f"MEM: {metrics['memory_percent']}% | "
            f"TQ: {metrics['suggested_TQ_ms']} ms",
            end="", flush=True
        )

        # Append to CSV
        df = pd.DataFrame([metrics])
        df.to_csv(
            output_file,
            mode='a',
            header=not pd.io.common.file_exists(output_file),
            index=False
        )

        # Precise timing
        time_left = sample_interval - (time.time() - start_time)
        if time_left > 0:
            time.sleep(time_left)


if __name__ == "__main__":
    log_enhanced_metrics(sample_interval=0.5)
