% AMD-based Pitch Detection
% Load the audio file
[x, fs] = audioread('//MATLAB Drive/phonemes/घ :gha: - Aspirated voiced.wav');

% Use only one channel if stereo
if size(x, 2) > 1
    x = x(:, 1);
end

% Parameters
N = length(x);
max_lag = round(fs * 0.02);  % Maximum lag = 20ms (50 Hz minimum pitch)
min_lag = round(fs * 0.002); % Minimum lag = 2ms (500 Hz maximum pitch)

% Compute AMDF
amdf = zeros(max_lag, 1);
for lag = 1:max_lag
    if lag < N
        amdf(lag) = sum(abs(x(lag+1:N) - x(1:N-lag))) / (N - lag);
    end
end

% Find the first minimum after min_lag (this is the pitch period)
[~, pitch_period_samples] = min(amdf(min_lag:max_lag));
pitch_period_samples = pitch_period_samples + min_lag - 1;

% Convert to pitch frequency
pitch_hz = fs / pitch_period_samples;

% Plot the AMDF
figure;
plot(amdf);
hold on;
plot(pitch_period_samples, amdf(pitch_period_samples), 'ro', 'MarkerSize', 10, 'LineWidth', 2);
xlabel('Lag (samples)');
ylabel('AMDF');
title(['AMDF for vowel /gha/ - Estimated Pitch: ', num2str(pitch_hz, '%.2f'), ' Hz']);
grid on;
legend('AMDF', 'First Minimum (Pitch Period)');

% Display result
fprintf('Estimated Pitch: %.2f Hz\n', pitch_hz);
fprintf('Pitch Period: %d samples (%.2f ms)\n', pitch_period_samples, pitch_period_samples/fs*1000);