% Improved MLR model training with proper normalization, metrics, and model saving

% Load data
data = readtable('data/enhanced_metrics.csv');

% Extract features and target
X_raw = [data.avg_cpu_percent, data.num_processes, data.io_bytes_sec, ...
         data.context_switches_sec, data.memory_percent];
y = data.suggested_TQ_ms;

% Normalize features (Z-score)
X_mean = mean(X_raw);
X_std = std(X_raw);
X_normalized = (X_raw - X_mean) ./ X_std;

% 1. Lasso Regression (CV to select optimal lambda)
[B, FitInfo] = lasso(X_normalized, y, 'CV', 10);
best_idx = FitInfo.Index1SE;
coefs = [FitInfo.Intercept(best_idx); B(:,best_idx)];

% 2. Fit Linear Model for interpretability
mdl_kept = fitlm(X_normalized, y, 'linear');
disp(mdl_kept);

% 3. Model Evaluation
y_pred = predict(mdl_kept, X_normalized);
fprintf('R^2 Score: %.3f\n', mdl_kept.Rsquared.Ordinary);
fprintf('RMSE: %.3f ms\n', sqrt(mean((y - y_pred).^2)));

% 4. Plots
figure;
subplot(1,1,1);
lassoPlot(B, FitInfo, 'PlotType', 'Lambda', 'XScale', 'log');
title('Lasso Regularization Path');

subplot(1,1,1);
scatter(y, y_pred, 20, 'filled');
xlabel('Actual TQ (ms)'); ylabel('Predicted TQ (ms)');
title('Actual vs Predicted Time Quantum');
grid on;

% 5. Save model and normalization parameters
save('models/full_model.mat', 'mdl_kept', 'X_mean', 'X_std');