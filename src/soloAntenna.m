clear all;
close all;

% Create PlutoSDR receiver object
plutoReceive = sdrrx('Pluto', 'RadioID', 'usb:0');

% Set up receiver parameters
fc = 2441e6; % Bluetooth frequency
fs = 61e6;   % Sample rate
plutoReceive.CenterFrequency = fc;
plutoReceive.BasebandSampleRate = fs;
plutoReceive.GainSource = 'Manual';
plutoReceive.Gain = 40;

% Setup spectrogram parameters
fftSize = 2^12;
window = double(blackman(fftSize));
numRows = 100;
specData = zeros(numRows, fftSize);

% Setup frequency axis
freq = (-fftSize/2:fftSize/2-1)*(fs/fftSize) + fc;

% Setup time axis
time = (1:numRows)*fftSize/fs;

% Setup plot
figure('Position', [100, 100, 800, 600]);

% Capture and display data continuously
while true
    % Receive data from the antenna
    data = double(plutoReceive());

    % Compute FFT
    spectrum = fftshift(fft(data(1:fftSize) .* window));
    powerDb = 10*log10(abs(spectrum).^2);
    specData = [specData(2:end,:); powerDb'];

    % Plot spectrogram
    subplot(2,1,1)
    imagesc(freq/1e6, time*1000, specData)
    title('Spectrogram')
    xlabel('Frequency (MHz)');
    ylabel('Time (ms)');
    colorbar;

    % Plot current spectrum
    subplot(2,1,2)
    plot(freq/1e6, powerDb)
    title('Current Spectrum')
    xlabel('Frequency (MHz)');
    ylabel('Power (dB)');
    grid on;
    ylim([-100, 0]); % Adjust these limits based on your signal strength

    drawnow
end

% Clean up (this part won't be reached in this infinite loop)
release(plutoReceive)
