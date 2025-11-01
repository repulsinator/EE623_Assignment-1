% =========================================================================
% EE623 Assignment-1: Objective-2
% Cepstral Analysis for Formant and Pitch Estimation
% =========================================================================

clear; clc; close all;

%% ============ CONFIGURATION ============
vowel_name = 'a';  % Change to your vowel
audio_file = '/MATLAB Drive/phonemes/अ :a: - Unrounded low central.wav';  % Your audio file
num_frames = 6;  % Number of consecutive frames to analyze

%% ============ LOAD AUDIO ============
[x, fs] = audioread(audio_file);

% Convert to mono if stereo
if size(x, 2) > 1
    x = x(:, 1);
end

% Normalize
x = x / max(abs(x));

fprintf('Audio loaded: %s\n', audio_file);
fprintf('Sampling rate: %d Hz\n', fs);
fprintf('Duration: %.2f seconds\n\n', length(x)/fs);

%% ============ FRAME PARAMETERS ============
frame_duration = 0.025;  % 25 ms frame length
frame_shift = 0.010;     % 10 ms shift (60% overlap)

frame_samples = round(frame_duration * fs);
shift_samples = round(frame_shift * fs);

% Make frame length power of 2 for efficient FFT
nfft = 2^nextpow2(frame_samples);

fprintf('Frame length: %d samples (%.1f ms)\n', frame_samples, frame_duration*1000);
fprintf('Frame shift: %d samples (%.1f ms)\n', shift_samples, frame_shift*1000);
fprintf('FFT size: %d\n\n', nfft);

%% ============ SELECT FRAMES FROM STABLE REGION ============
% Choose frames from middle 60% of the signal (stable portion)
signal_length = length(x);
start_sample = round(0.2 * signal_length);  % Skip first 20%
end_sample = round(0.8 * signal_length);    % Skip last 20%

% Calculate frame positions
frame_starts = start_sample:shift_samples:(start_sample + (num_frames-1)*shift_samples);

% Ensure we don't exceed signal length
if frame_starts(end) + frame_samples > signal_length
    error('Not enough signal for %d frames. Try shorter frames or longer audio.', num_frames);
end

%% ============ CEPSTRAL LIFTER DESIGN ============
% Lifter length: Keep low quefrency components (vocal tract info)
% For fs=44.1kHz, liftering at ~5ms captures formants well
lifter_ms = 5;  % milliseconds
lifter_samples = round(lifter_ms * fs / 1000);

% Create rectangular lifter window
lifter = zeros(nfft, 1);
lifter(1:lifter_samples) = 1;
lifter(end-lifter_samples+2:end) = 1;  % Symmetric for real signal

fprintf('Lifter cutoff: %d samples (%.2f ms)\n\n', lifter_samples, lifter_ms);

%% ============ INITIALIZE STORAGE ============
formant_freqs = zeros(num_frames, 3);  % F1, F2, F3 for each frame
pitch_freqs = zeros(num_frames, 1);    % F0 for each frame

% For plotting
all_spectra = cell(num_frames, 1);
all_smoothed_spectra = cell(num_frames, 1);
all_cepstra = cell(num_frames, 1);
all_frames = cell(num_frames, 1);

%% ============ PROCESS EACH FRAME ============
fprintf('Processing %d frames...\n', num_frames);

for i = 1:num_frames
    fprintf('Frame %d: ', i);
    
    % Extract frame
    start_idx = frame_starts(i);
    end_idx = start_idx + frame_samples - 1;
    frame = x(start_idx:end_idx);
    all_frames{i} = frame;
    
    % Apply Hamming window
    window = hamming(frame_samples);
    frame_windowed = frame .* window;
    
    %% STEP 1: Compute FFT (Spectrum)
    X = fft(frame_windowed, nfft);
    magnitude_spectrum = abs(X);
    
    %% STEP 2: Log Magnitude Spectrum
    log_magnitude = log(magnitude_spectrum + eps);  % Add eps to avoid log(0)
    
    %% STEP 3: Compute Cepstrum (IFFT of log magnitude)
    cepstrum = real(ifft(log_magnitude));
    
    %% STEP 4: Apply Lifter (Keep low quefrency)
    cepstrum_liftered = cepstrum .* lifter;
    
    %% STEP 5: Compute Smoothed Spectrum (FFT of liftered cepstrum)
    smoothed_log_spectrum = real(fft(cepstrum_liftered));
    smoothed_spectrum = exp(smoothed_log_spectrum);
    
    % Store for plotting
    all_spectra{i} = magnitude_spectrum;
    all_smoothed_spectra{i} = smoothed_spectrum;
    all_cepstra{i} = cepstrum;
    
    %% STEP 6: Estimate Pitch from Cepstrum
    % Search for peak in cepstrum between 2-20 ms (50-500 Hz)
    min_quefrency_samples = round(0.002 * fs);  % 2 ms (500 Hz max)
    max_quefrency_samples = round(0.020 * fs);  % 20 ms (50 Hz min)
    
    [~, pitch_idx] = max(cepstrum(min_quefrency_samples:max_quefrency_samples));
    pitch_idx = pitch_idx + min_quefrency_samples - 1;
    
    pitch_period_sec = pitch_idx / fs;
    pitch_hz = 1 / pitch_period_sec;
    pitch_freqs(i) = pitch_hz;
    
    %% STEP 7: Estimate Formants from Smoothed Spectrum
    % Use only positive frequencies
    freq_axis = (0:nfft/2) * fs / nfft;
    smoothed_half = smoothed_spectrum(1:nfft/2+1);
    
    % Find peaks in smoothed spectrum using findpeaks
    % Search only up to 4000 Hz for formants
    max_formant_freq = 4000;
    search_idx = find(freq_axis <= max_formant_freq);
    search_spectrum = smoothed_half(search_idx);
    search_freq = freq_axis(search_idx);
    
    % Find all peaks with minimum prominence
    [pks, locs] = findpeaks(search_spectrum, 'MinPeakProminence', max(search_spectrum)*0.1, ...
                            'SortStr', 'descend');
    
    % Get frequencies of peaks
    peak_freqs = search_freq(locs);
    
    % Sort peaks by frequency (ascending)
    [peak_freqs_sorted, sort_idx] = sort(peak_freqs);
    pks_sorted = pks(sort_idx);
    
    % Assign formants with better logic
    % F1: First significant peak (300-1200 Hz)
    F1_candidates = find(peak_freqs_sorted >= 300 & peak_freqs_sorted <= 1200);
    if ~isempty(F1_candidates)
        F1 = peak_freqs_sorted(F1_candidates(1));
    else
        F1 = 800;  % Default
    end
    
    % F2: Second peak, must be > F1 + 200 Hz (900-2500 Hz for /aa/)
    F2_candidates = find(peak_freqs_sorted > F1 + 200 & ...
                         peak_freqs_sorted >= 900 & ...
                         peak_freqs_sorted <= 2500);
    if ~isempty(F2_candidates)
        F2 = peak_freqs_sorted(F2_candidates(1));
    else
        F2 = 1300;  % Default
    end
    
    % F3: Third peak, must be > F2 + 300 Hz (1800-4000 Hz)
    F3_candidates = find(peak_freqs_sorted > F2 + 300 & ...
                         peak_freqs_sorted >= 1800 & ...
                         peak_freqs_sorted <= 4000);
    if ~isempty(F3_candidates)
        F3 = peak_freqs_sorted(F3_candidates(1));
    else
        F3 = 2700;  % Default
    end
    
    formant_freqs(i, :) = [F1, F2, F3];
    
    fprintf('F0=%.1f Hz, F1=%.0f Hz, F2=%.0f Hz, F3=%.0f Hz\n', ...
            pitch_hz, F1, F2, F3);
end

%% ============ COMPUTE AVERAGES ============
avg_pitch = mean(pitch_freqs);
avg_F1 = mean(formant_freqs(:, 1));
avg_F2 = mean(formant_freqs(:, 2));
avg_F3 = mean(formant_freqs(:, 3));

fprintf('\n========== AVERAGE VALUES ==========\n');
fprintf('Average Pitch (F0): %.2f Hz\n', avg_pitch);
fprintf('Average F1: %.0f Hz\n', avg_F1);
fprintf('Average F2: %.0f Hz\n', avg_F2);
fprintf('Average F3: %.0f Hz\n', avg_F3);
fprintf('====================================\n\n');

%% ============ PLOTTING ============

% Create frequency axis for plotting
freq_axis_full = (0:nfft-1) * fs / nfft;
freq_axis_half = (0:nfft/2) * fs / nfft;
quefrency_axis = (0:nfft-1) / fs * 1000;  % in milliseconds

%% PLOT 1: Cepstrally Smoothed Spectra (All 6 frames)
figure('Position', [100, 100, 1400, 900]);

for i = 1:num_frames
    subplot(3, 2, i);
    
    % Plot original spectrum
    plot(freq_axis_half/1000, 20*log10(all_spectra{i}(1:nfft/2+1)), ...
         'Color', [0.7 0.7 0.7], 'LineWidth', 1);
    hold on;
    
    % Plot smoothed spectrum
    plot(freq_axis_half/1000, 20*log10(all_smoothed_spectra{i}(1:nfft/2+1)), ...
         'b-', 'LineWidth', 2);
    
    % Mark formants
    plot([formant_freqs(i,1) formant_freqs(i,1)]/1000, ylim, 'r--', 'LineWidth', 1.5);
    plot([formant_freqs(i,2) formant_freqs(i,2)]/1000, ylim, 'r--', 'LineWidth', 1.5);
    plot([formant_freqs(i,3) formant_freqs(i,3)]/1000, ylim, 'r--', 'LineWidth', 1.5);
    
    xlim([0 5]);
    xlabel('Frequency (kHz)', 'FontSize', 10);
    ylabel('Magnitude (dB)', 'FontSize', 10);
    title(sprintf('Frame %d: F1=%.0f, F2=%.0f, F3=%.0f Hz', ...
                  i, formant_freqs(i,1), formant_freqs(i,2), formant_freqs(i,3)), ...
          'FontSize', 11);
    legend('Original Spectrum', 'Cepstrally Smoothed', 'Formants', ...
           'Location', 'northeast', 'FontSize', 8);
    grid on;
end

sgtitle(sprintf('Cepstrally Smoothed Spectra - Vowel /%s/', vowel_name), ...
        'FontSize', 14, 'FontWeight', 'bold');

% Save figure
saveas(gcf, sprintf('cepstral_smoothed_spectra_%s.png', vowel_name));

%% PLOT 2: Cepstral Sequences (All 6 frames)
figure('Position', [100, 100, 1400, 900]);

for i = 1:num_frames
    subplot(3, 2, i);
    
    % Plot first 50ms of cepstrum (relevant range)
    max_quefrency_plot = 50;  % ms
    plot_range = 1:min(round(max_quefrency_plot * fs / 1000), nfft);
    
    plot(quefrency_axis(plot_range), all_cepstra{i}(plot_range), ...
         'b-', 'LineWidth', 1.5);
    hold on;
    
    % Mark pitch quefrency
    pitch_quefrency = 1000 / pitch_freqs(i);  % in ms
    plot([pitch_quefrency pitch_quefrency], ylim, 'r--', 'LineWidth', 2);
    
    % Mark lifter cutoff
    plot([lifter_ms lifter_ms], ylim, 'g--', 'LineWidth', 1.5);
    
    xlabel('Quefrency (ms)', 'FontSize', 10);
    ylabel('Amplitude', 'FontSize', 10);
    title(sprintf('Frame %d: Pitch = %.1f Hz (%.2f ms)', ...
                  i, pitch_freqs(i), pitch_quefrency), 'FontSize', 11);
    legend('Cepstrum', 'Pitch Period', 'Lifter Cutoff', ...
           'Location', 'northeast', 'FontSize', 8);
    grid on;
    xlim([0 max_quefrency_plot]);
end

sgtitle(sprintf('Cepstral Sequences - Vowel /%s/', vowel_name), ...
        'FontSize', 14, 'FontWeight', 'bold');

% Save figure
saveas(gcf, sprintf('cepstral_sequences_%s.png', vowel_name));

%% PLOT 3: Summary - Average Values with Error Bars
figure('Position', [100, 100, 1200, 500]);

% Formants
subplot(1, 2, 1);
bar_data = [avg_F1, avg_F2, avg_F3];
std_data = [std(formant_freqs(:,1)), std(formant_freqs(:,2)), std(formant_freqs(:,3))];
bar(bar_data);
hold on;
errorbar(1:3, bar_data, std_data, 'k.', 'LineWidth', 2, 'CapSize', 10);
set(gca, 'XTickLabel', {'F1', 'F2', 'F3'});
ylabel('Frequency (Hz)', 'FontSize', 12);
title(sprintf('Average Formants - Vowel /%s/', vowel_name), 'FontSize', 13);
grid on;
text(1:3, bar_data + std_data + 100, ...
     arrayfun(@(x) sprintf('%.0f Hz', x), bar_data, 'UniformOutput', false), ...
     'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold');

% Pitch
subplot(1, 2, 2);
bar(avg_pitch);
hold on;
errorbar(1, avg_pitch, std(pitch_freqs), 'k.', 'LineWidth', 2, 'CapSize', 10);
set(gca, 'XTickLabel', {'F0'});
ylabel('Frequency (Hz)', 'FontSize', 12);
title(sprintf('Average Pitch - Vowel /%s/', vowel_name), 'FontSize', 13);
ylim([0 max(pitch_freqs)*1.2]);
grid on;
text(1, avg_pitch + std(pitch_freqs) + 5, sprintf('%.1f Hz', avg_pitch), ...
     'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold');

sgtitle('Average Formant and Pitch Values', 'FontSize', 14, 'FontWeight', 'bold');

% Save figure
saveas(gcf, sprintf('average_values_%s.png', vowel_name));

%% ============ SAVE RESULTS TO FILE ============
results_table = table(formant_freqs(:,1), formant_freqs(:,2), formant_freqs(:,3), pitch_freqs, ...
                      'VariableNames', {'F1_Hz', 'F2_Hz', 'F3_Hz', 'F0_Hz'}, ...
                      'RowNames', arrayfun(@(x) sprintf('Frame_%d', x), 1:num_frames, 'UniformOutput', false));

fprintf('\n========== FRAME-WISE RESULTS ==========\n');
disp(results_table);

% Save to CSV
writetable(results_table, sprintf('cepstral_results_%s.csv', vowel_name), ...
           'WriteRowNames', true);

fprintf('\nResults saved to: cepstral_results_%s.csv\n', vowel_name);
fprintf('All plots saved successfully!\n');
fprintf('\n========== ANALYSIS COMPLETE ==========\n');