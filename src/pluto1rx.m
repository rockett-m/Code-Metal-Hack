%% Clear workspace
clear; close all; clc;

%% Pluto SDR IDs
plutoRX = 'usb:0';

%% RF parameters
% fc = 2441e6;        % Center frequency (2.441 GHz)
% fc = 2341e6;        % Center frequency (2.441 GHz)
fc = 2140e6;        % Center frequency (2.140 GHz) midrange of 3G
% fs = 10e6;          % Sample rate (10 MHz)
fs = 1e6;          % Sample rate (10 MHz)
frameSize = 8192;   % Samples per frame (for smooth visualization)

%% Pluto RX Setup
rxPluto = sdrrx('Pluto', 'RadioID', plutoRX, ...
    'CenterFrequency', fc, 'BasebandSampleRate', fs, ...
    'GainSource', 'Manual', 'Gain', 0, ... % 40 % can have more errors with higher gain
    'SamplesPerFrame', frameSize, 'OutputDataType', 'double');

%% Generate 60-second sine wave (adjusted to last full duration)
duration = 60;                  % Total duration: 60 seconds

figure('Name', 'Pluto SDR 60-sec Live RX Signal Strength', 'NumberTitle', 'off');
hLine = plot(NaN, NaN, '-o');
xlabel('Time (s)');
ylabel('RX Signal Power (dB)');
title('Received Signal Power Over 60 Seconds');
grid on;
xlim([0 duration]);

%% Real-time RX loop (60-sec) with Line-of-Sight Detection (Debounced)
disp('Starting 60-second RX processing...');
rxPower = []; % Store power values dynamically
timeVec = []; % Store actual timestamps
startTime = tic; % Start timing
threshold = -58; % dB threshold for detecting obstruction
% threshold = 0; % dB threshold for detecting obstruction
obstructionDetected = false;
debounceTime = 0.2; % Minimum time (in sec) between detections
lastEventTime = -debounceTime; % Initialize last event time

while toc(startTime) < duration  % Run for 60 full seconds
    rxSamples = rxPluto();  % Receive frame

    % Compute power (dB)
    % powerDb = 10*log10(mean(abs(rxSamples).^2));
    powerDb = 10*log10(mean(abs(rxSamples).^2) + eps); % Avoid log(0) errors
    % powerDb = 10*log10(median(abs(rxSamples).^2) + eps); % Avoid log(0) errors
    % powerDb = powerDb + 60;
    
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
    % set(hLine, 'XData', timeVec, 'YData', rxPower);
    % drawnow limitrate;

    set(hLine, 'XData', timeVec, 'YData', rxPower);
    drawnow;  % Force UI update on every iteration
    % pause(0.005); % Add slight delay to allow real-time plotting
end

toc;

%% Final visualization (Correct full 60-second x-axis)
figure;
plot(timeVec, rxPower, '-b');
xlabel('Time (s)'); ylabel('RX Signal Power (dB)');
title('Final RX Signal Power (60 seconds)');
xlim([0 duration]); % Ensure full 60 seconds
grid on;

%% Cleanup
release(rxPluto);

disp('Demo complete. TX stopped.');