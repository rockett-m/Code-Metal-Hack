%% Clear workspace
clear; close all; clc;

%% Pluto SDR IDs
plutoTX = 'usb:0';
plutoRX = 'usb:1';

%% RF parameters
fc = 2441e6;        % Center frequency (2.441 GHz)
fs = 10e6;          % Sample rate (10 MHz)
frameSize = 8192;   % Samples per frame (for smooth visualization)

%% Pluto TX Setup
txPluto = sdrtx('Pluto', 'RadioID', plutoTX, ...
    'CenterFrequency', fc, 'BasebandSampleRate', fs, 'Gain', -5);

%% Pluto RX Setup
rxPluto = sdrrx('Pluto', 'RadioID', plutoRX, ...
    'CenterFrequency', fc, 'BasebandSampleRate', fs, ...
    'GainSource', 'Manual', 'Gain', 40, ...
    'SamplesPerFrame', frameSize, 'OutputDataType', 'double');

%% Generate 60-second sine wave (adjusted to last full duration)
duration = 60;                  % Total duration: 60 seconds
f_tone = 0.5 / 12;               % Frequency adjusted to last the full 60 seconds
numSamples = min(fs * duration, 16777216 - 1);  % Ensure it's just under the max

t = (0:numSamples-1)' / fs;
sineWave = 0.9 * exp(1j*2*pi*f_tone*t); % Explicitly complex baseband sine

% Print out size for verification
fprintf('Number of TX samples: %d (Max: 16777216)\n', numSamples);
fprintf('Unrestricted num of TX samples: %d \n', fs * duration);

%% Transmit sine wave
transmitRepeat(txPluto, sineWave);
disp('Transmitting continuous 60-second sine wave with adjusted frequency.');

figure('Name', 'Pluto SDR 60-sec Live RX Signal Strength', 'NumberTitle', 'off');
hLine = plot(NaN, NaN, '-o');
xlabel('Time (s)');
ylabel('RX Signal Power (dB)');
title('Received Signal Power Over 60 Seconds');
grid on;
xlim([0 duration]);
ylim([-120 0]);

%% Real-time RX loop (60-sec) with Line-of-Sight Detection (Debounced)
disp('Starting 60-second RX processing...');
rxPower = []; % Store power values dynamically
timeVec = []; % Store actual timestamps
startTime = tic; % Start timing
threshold = -50; % dB threshold for detecting obstruction
obstructionDetected = false;
debounceTime = 0.2; % Minimum time (in sec) between detections
lastEventTime = -debounceTime; % Initialize last event time

while toc(startTime) < duration  % Run for 60 full seconds
    rxSamples = rxPluto();  % Receive frame

    % Compute power (dB)
    powerDb = 10*log10(mean(abs(rxSamples).^2));

    % Detect Line-of-Sight Break (Debounced)
    currentTime = toc(startTime);
    if powerDb < threshold && ~obstructionDetected && (currentTime - lastEventTime) > debounceTime
        disp(['[', num2str(currentTime), ' sec] Obstruction detected!']);
        obstructionDetected = true;
        lastEventTime = currentTime;
    elseif powerDb >= threshold && obstructionDetected && (currentTime - lastEventTime) > debounceTime
        disp(['[', num2str(currentTime), ' sec] Line-of-sight restored.']);
        obstructionDetected = false;
        lastEventTime = currentTime;
    end

    % Store values
    rxPower = [rxPower, powerDb]; 
    timeVec = [timeVec, currentTime]; % Keep actual elapsed time

    % Update real-time plot
    set(hLine, 'XData', timeVec, 'YData', rxPower);
    drawnow limitrate;
end

toc;

%% Final visualization (Correct full 60-second x-axis)
figure;
plot(timeVec, rxPower, '-b');
xlabel('Time (s)'); ylabel('RX Signal Power (dB)');
title('Final RX Signal Power (60 seconds)');
xlim([0 60]); % Ensure full 60 seconds
grid on;

%% Cleanup
release(txPluto);
release(rxPluto);

disp('Demo complete. TX stopped.');