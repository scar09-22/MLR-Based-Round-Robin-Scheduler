%% Clean Environment
clc; clear; close all;
rng(3333);
disp(pwd)

%% 1. Generate Workload
num_processes = 1000;
burst_times = 5 + 15 * rand(num_processes, 1);
io_prob = 0.1 * rand(num_processes, 1);
arrival_times = cumsum(0.2 * rand(num_processes, 1));

% Simulated System State
cpu_usage = 40 + 30 * rand();
memory_usage = 50 + 20 * rand();
io_bytes = 1e6 + 9e6 * rand();
ctx_switches = 1000 + 2000 * rand();

%% 2. Traditional RR
fprintf('Running Traditional RR...\n');
tq_fixed = 10;
[~, turnaround_fixed, waiting_fixed, throughput_fixed, ctx_fixed, response_fixed] = ...
    rr_simulator(burst_times, io_prob, arrival_times, tq_fixed);

%% 3. MLR-Predicted TQ
fprintf('Running MLR-Optimized RR...\n');
load('models/full_model.mat', 'mdl_kept', 'X_mean', 'X_std');

% Normalize new input
X_new = [cpu_usage, num_processes, io_bytes, ctx_switches, memory_usage];
X_norm = (X_new - X_mean) ./ X_std;

% Predict and clamp TQ
tq_mlr = predict(mdl_kept, X_norm);
tq_mlr = max(5, min(50, tq_mlr));

[~, turnaround_mlr, waiting_mlr, throughput_mlr, ctx_mlr, response_mlr] = ...
    rr_simulator(burst_times, io_prob, arrival_times, tq_mlr);

%% 4. Metric Comparison
metrics = struct();
metrics.Turnaround = [mean(turnaround_fixed), mean(turnaround_mlr)];
metrics.Waiting = [mean(waiting_fixed), mean(waiting_mlr)];
metrics.Response = [mean(response_fixed), mean(response_mlr)];
metrics.ContextSwitches = [ctx_fixed, ctx_mlr];
metrics.Throughput = [num_processes / max(arrival_times + turnaround_fixed), ...
                      num_processes / max(arrival_times + turnaround_mlr)];

improve = @(x, y) (x - y) / x * 100;
fprintf('\n=========== Performance Comparison ===========\n');
fprintf('                   Fixed TQ    MLR TQ    Improvement\n');
fprintf('                   ---------   -------   -----------\n');
fprintf('Avg Turnaround:    %7.1f ms  %6.1f ms     %+5.1f%%\n', ...
        metrics.Turnaround(1), metrics.Turnaround(2), ...
        improve(metrics.Turnaround(1), metrics.Turnaround(2)));
fprintf('Avg Waiting:       %7.1f ms  %6.1f ms     %+5.1f%%\n', ...
        metrics.Waiting(1), metrics.Waiting(2), ...
        improve(metrics.Waiting(1), metrics.Waiting(2)));
fprintf('Avg Response:      %7.1f ms  %6.1f ms     %+5.1f%%\n', ...
        metrics.Response(1), metrics.Response(2), ...
        improve(metrics.Response(1), metrics.Response(2)));
fprintf('Throughput:        %7.2f p/s %6.2f p/s   %+5.1f%%\n', ...
        metrics.Throughput(1), metrics.Throughput(2), ...
        improve(metrics.Throughput(1), metrics.Throughput(2)));
fprintf('Context Switches:  %7d    %6d       %+5.1f%%\n', ...
        metrics.ContextSwitches(1), metrics.ContextSwitches(2), ...
        improve(metrics.ContextSwitches(1), metrics.ContextSwitches(2)));

%% 5. Visualization
figure('Position', [100 100 1400 900]);

subplot(3, 2, 1);
plot(turnaround_fixed, 'b'); hold on;
plot(turnaround_mlr, 'r');
title('Turnaround Time per Process');
xlabel('PID'); ylabel('ms'); grid on;

subplot(3, 2, 2);
boxplot([waiting_fixed, waiting_mlr], 'Labels', {'Fixed', 'MLR'});
title('Waiting Time'); ylabel('ms'); grid on;

subplot(3, 2, 3);
bar(categorical({'Fixed', 'MLR'}), metrics.ContextSwitches);
title('Context Switches'); ylabel('Count'); grid on;

subplot(3, 2, 4);
bar(categorical({'Fixed', 'MLR'}), metrics.Throughput);
title('Throughput'); ylabel('Processes/sec'); grid on;

subplot(3, 2, 5);
plot(response_fixed, 'b'); hold on;
plot(response_mlr, 'r');
title('Response Time'); xlabel('PID'); ylabel('ms'); grid on;

%% 6. RR Simulator Function
function [tq_used, turnaround, waiting, throughput, ctx_switches, response] = ...
         rr_simulator(burst_times, io_prob, arrival_times, tq)
    
    n = length(burst_times);
    remaining = burst_times;
    waiting = zeros(n, 1);
    turnaround = zeros(n, 1);
    response = -ones(n, 1);
    completed = false(n, 1);
    current_time = 0;
    ctx_switches = 0;
    queue = [];
    
    while ~all(completed)
        new_arrivals = find(arrival_times <= current_time & ~completed);
        new_arrivals = setdiff(new_arrivals, queue);
        queue = [queue; new_arrivals(:)];

        if isempty(queue)
            current_time = min(arrival_times(~completed));
            continue;
        end

        pid = queue(1); queue(1) = [];
        ctx_switches = ctx_switches + 1;

        if response(pid) == -1
            response(pid) = current_time - arrival_times(pid);
        end

        if rand() < io_prob(pid)
            io_time = 0.5 * tq;
            remaining(pid) = max(0, remaining(pid) - io_time);
            current_time = current_time + io_time;
            queue(end+1) = pid;
            continue;
        end

        exec_time = min(tq, remaining(pid));
        remaining(pid) = remaining(pid) - exec_time;
        current_time = current_time + exec_time;

        waiting(setdiff(find(arrival_times <= current_time & ~completed), pid)) = ...
            waiting(setdiff(find(arrival_times <= current_time & ~completed), pid)) + exec_time;

        if remaining(pid) <= 0
            completed(pid) = true;
            turnaround(pid) = current_time - arrival_times(pid);
        else
            queue(end+1) = pid;
        end
    end

    tq_used = tq;
    throughput = sum(completed);
end