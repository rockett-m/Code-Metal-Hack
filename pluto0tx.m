%% Clear workspace
clear; close all; clc;

%% Pluto SDR IDs
plutoTX = 'usb:0';

%% RF parameters
fc = 2140e6;        % Center frequency (2.14 GHz)
fs = 10e6;          % Sample rate (10 MHz)
frameSize = 8192;   % Samples per frame

%% Pluto TX Setup
txPluto = sdrtx('Pluto', 'RadioID', plutoTX, ...
    'CenterFrequency', fc, 'BasebandSampleRate', fs, 'Gain', -70);

%% Generate sine wave for each transmission period
transmitTime = 2;    % Transmit for 2 seconds
pauseTime = 1;       % Pause for 1 second
duration = 60;       % Total duration: 60 seconds

% Generate a complete sine wave for the transmission period
samplesPerTransmission = fs * transmitTime;
t = (0:samplesPerTransmission-1)' / fs;
f_tone = 1000;      % 1 kHz tone - complete cycles in 2 seconds
sineWave = 0.9 * exp(1j*2*pi*f_tone*t); % Complex sine wave

% Create status display
figure('Name', 'TX Status', 'NumberTitle', 'off', 'Position', [100 100 400 200]);
h_text = text(0.1, 0.7, 'Status: Initializing...', 'FontSize', 14);
text(0.1, 0.5, sprintf('Frequency: %.2f GHz', fc/1e9), 'FontSize', 12);
text(0.1, 0.3, sprintf('Sample Rate: %.2f MHz', fs/1e6), 'FontSize', 12);
text(0.1, 0.1, sprintf('Tone: %.2f kHz', f_tone/1e3), 'FontSize', 12);
axis off;

% Calculate total cycles
totalCycles = floor(duration / (transmitTime + pauseTime));

fprintf('\nStarting transmission cycles:\n');
fprintf('Pattern: %d seconds ON, %d second OFF\n', transmitTime, pauseTime);
fprintf('Tone frequency: %.2f kHz\n', f_tone/1e3);

for cycle = 1:totalCycles
    % Start transmission
    transmitRepeat(txPluto, sineWave);
    set(h_text, 'String', 'Status: TRANSMITTING');
    fprintf('Cycle %d/%d: Transmitting...\n', cycle, totalCycles);
    pause(transmitTime);
    
    % Pause transmission
    release(txPluto);
    set(h_text, 'String', 'Status: PAUSED');
    fprintf('Cycle %d/%d: Paused...\n', cycle, totalCycles);
    pause(pauseTime);
end

%% Cleanup
release(txPluto);
set(h_text, 'String', 'Status: STOPPED');
disp('Transmission cycles complete. TX stopped.');
