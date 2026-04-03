
%Image Pre-Processing
function [binary_data, image_dimensions, scaled_DCT_dimensions, DCT_Image_min, DCT_Image_max] = preprocess_image(image_path, N)
   %image into readable data format - rn is 1280 x 720  to 8 * 8 1280 * (720 / 64)
   image = imread(image_path);
   image = rgb2gray(image);
   image_normalized = im2double(image);
   [row, col] = size(image_normalized);
   image_dimensions = [row, col];

   % linear scaling/clamping to ceiling of 1 and floor of 0
   % Apply DCT in 8x8 blocks
   DCT_Image = blockproc(image_normalized, [8 8], @(block_struct) dct2(block_struct.data));

   DCT_Image_min = min(min(DCT_Image)); % takes the minimum of each col and then takes the minimum of all those minimums
   DCT_Image_max = max(max(DCT_Image)); % takes the maximum of each col and then takes the maximum of all those maximum
   Scaled_DCT_Image = (DCT_Image - DCT_Image_min) / (DCT_Image_max - DCT_Image_min); % normalization formula (array with min at 0 and max at 1)
   % image into readable data format - rn is 1280 x 720  to 8 * 8 1280 * (720 / 64)

   [m, n] = size(Scaled_DCT_Image);
   scaled_DCT_dimensions = [m, n];
   DCT_Image_4D = reshape(Scaled_DCT_Image, [8, m/8, 8, n/8]); %
   DCT_Image_Ordered = permute(DCT_Image_4D, [1, 3, 2, 4]);
   total_blocks = (m * n) / 64; % 14400 in our case
   DCT_3D_array = reshape(DCT_Image_Ordered, [8, 8, total_blocks]);

   %Conversion to a bit stream

   DCT_3d_column = reshape(DCT_3D_array, [64, 1, N]); % creates a 3D row vector of depth N

   % Scale 0-1 to 0-255 and convert to 8-bit integers
   DCT_int = uint8(DCT_3d_column * 255);
   DCT_vector = DCT_int(:); % Flattens into a vector

   % Convert to double for the function, but keep it in the 0-255 range
   % 'msb' ensures the most significant bit (128) is at index 1
   binary_data = int2bit(double(DCT_vector), 8);

   % Reshape to separate the bits from the coefficients
   % This creates a [8 bits x 64 coeffs x N blocks] array
   reshaped_array = reshape(binary_data, 8, 64, []);
   % Permute to swap the first two dimensions
   % This moves the 64 coeffs to rows and 8 bits to columns
   % Resulting size: [64 x 8 x N]
   binary_3D = permute(reshaped_array, [2, 1, 3]);
end

%Modulation Simulation: Half Sine
function [y] = half_sine_pulse(sps, T)
   t_half_sine = linspace(0, T, sps + 1); 
   t_half_sine = t_half_sine(1:end-1); % Drop the last sample to prevent overlap
   % Modulating sine wave sin(pi*t) for half-sine
   y = sin(pi * t_half_sine); 
   y = y / norm(y); % Normalize energy to 1
      % Time vector for plotting half-sine
   t = t_half_sine; 

   %Plotting the half-sine pulse
   figure;
   plot(t, y)
   title('Half-sine Pulse (Time Domain)');
   xlabel('Time (s)');
   ylabel('Amplitude');
   grid on

   % Verifiying Energy should be 1
   energy_y = sum(y.^2);
   fprintf('Total Half Sine Energy: %.4f\n', energy_y);

   %Frequency of half sine pulse
   N = length(y);
   Y = fft(y);
   % 1. Computin Magnitude
   % divide by N to scale it back to the original signal's amplitude
   mag = abs(Y) / N;

   % 2. Compute Phase
   % 'angle' returns the phase in radians (from -pi to pi)
   phase = angle(Y);

   % 3. Create the frequency axis
   f = (0:N-1) * (sps/N);

   % Plotting half sine spectrum
   figure;
   subplot(2,1,1)
   plot(f(1 : floor(N/2)), 20*log10(abs(Y(1 : floor(N/2))) / N))
   %plot(f(1 : floor(N/2)), mag(1 : floor(N/2))) % Plotting only the positive frequencies
   title('Half Sine Pulse Magnitude Spectrum (dB)', 'FontSize', 12, 'FontWeight', 'bold');
   ylabel('Magnitude', 'FontSize', 11);
   grid on

   subplot(2,1,2)
   plot(f(1 : floor(N/2)), phase(1 : floor(N/2))) 
   title('Half Sine Pulse Phase Spectrum', 'FontSize', 12, 'FontWeight', 'bold');
   ylabel('Phase (rad)', 'FontSize', 11);
   xlabel('Frequency (Hz)', 'FontSize', 11); 
   grid on;
end

function [s] = srrc_pulse(alpha, k, sps)
   s = rcosdesign(alpha, 2*k, sps); 
   s = s / norm(s); % Normalize to unit energy

   energy_s = sum(s.^2);
   fprintf('Total SRRC Energy: %.4f\n', energy_s);

   %SRRC in time domain
   figure;
   plot((0:length(s)-1)/sps, s, 'LineWidth', 1.5)
   title(sprintf('SRRC Pulse (Time Domain) (\\alpha = %.1f), K = %d', alpha, k));
   xlabel('Time (s)');
   ylabel('Amplitude');
   grid on

   %SRRC in frequency domain
   % FFT Calculation
   N_s = length(s);
   S = fft(s);
   mags = 20*log10(abs(S)); % For filters, we often look at the raw magnitude or dB
   phases = angle(S);

   % Frequency axis for the filter
   % The sampling frequency of the filter is technically 'sps' relative to the symbol rate.
   fs_filter = sps; 
   freqs = (0:N_s-1) * (fs_filter/N_s);

   figure; % 
   subplot(2,1,1)
   plot(freqs(1:floor(N_s/2)), mags(1:floor(N_s/2)), 'LineWidth', 1.5)
   title(sprintf('SRRC Magnitude Spectrum (dB) (\\alpha = %.1f)', alpha), 'FontSize', 12, 'FontWeight', 'bold');
   ylabel('Magnitude', 'FontSize', 11);
   grid on

   subplot(2,1,2)

   % Clean up phase noise
   phases(mags < max(mags)*1e-6) = 0; 
   plot(freqs(1:floor(N_s/2)), unwrap(phases(1:floor(N_s/2))))
   title('SRRC Phase Spectrum (Unwrapped)', 'FontSize', 12, 'FontWeight', 'bold');
   ylabel('Phase (rad)', 'FontSize', 11);
   xlabel('Normalized Frequency', 'FontSize', 11);
   grid on;

end

%Random 10 bit modulation (time and frequency)
function [upsampled_symbols, modulated_half_sine, modulated_srrc] = rand_bit_modulation(sps, k, s, y)
   % Generate 10 random bits (1,  -1)
   num_bits = 10;
   bits = randi([0 1], 1, num_bits);
   % Map bits to PAM symbols: '1' becomes +1, '0' becomes -1
   % This makes the zero-threshold detection later much easier
   symbols = 2*bits - 1;
   % Upsample the symbols to match the sampling rate (insert 31 zeros between symbols)
   upsampled_symbols = upsample(symbols, sps);

   modulated_half_sine = conv(upsampled_symbols, y);
   modulated_srrc = conv(upsampled_symbols, s);

   %modulate the unsampled symbols by doing a convolution "conv" between the unsampled symbols and the pulses (half sine, SRRC) in the time domain. 
   % Time axes for the modulated signals
   % We divide by sps so the x-axis represents bit durations (T=1)
   t_mod_half_sine = (0:length(modulated_half_sine)-1) / sps;
   t_mod_srrc = (0:length(modulated_srrc)-1) / sps;

   %Modulated Half Sine
   figure;
   subplot(2,1,1);
   plot(t_mod_half_sine, modulated_half_sine, 'b', 'LineWidth', 1.5);
   title(['Half-Sine Modulated Signal | Bits: ' num2str(bits)], 'FontSize', 12, 'FontWeight', 'bold');
   ylabel('Amplitude', 'FontSize', 11);
   xlabel('Time (Bit Durations)', 'FontSize', 11);
   grid on;
   xlim([0 num_bits]); % Limit view to exactly the 10 sent bits

   %Modulated SRRC
   subplot(2,1,2);
   plot(t_mod_srrc, modulated_srrc, 'r', 'LineWidth', 1.5);
   title(['SRRC Modulated Signal | Bits: ' num2str(bits)], 'FontSize', 12, 'FontWeight', 'bold');
   ylabel('Amplitude', 'FontSize', 11);
   xlabel('Time (Bit Durations)', 'FontSize', 11);
   grid on;
   % SRRC extends past the 10 bits due to its long duration (2*K bit times)
   xlim([0 num_bits + 2*k]); 

   % Use zero-padded FFT size as before for smooth plots
   Nfft = 1024; 

   % 1. FFT of the Modulated Half-sine Signal
   Mod_Half_Sine = fft(modulated_half_sine, Nfft);
   mag_mod_half_sine = 20*log10(abs(Mod_Half_Sine));
   mag_mod_half_sine = mag_mod_half_sine - max(mag_mod_half_sine); % Normalize peak to 0 dB

   % 2. FFT of the Modulated SRRC Signal
   Mod_SRRC = fft(modulated_srrc, Nfft);
   mag_mod_srrc = 20*log10(abs(Mod_SRRC));
   mag_mod_srrc = mag_mod_srrc - max(mag_mod_srrc); % Normalize peak to 0 dB

   % Create frequency axis up to the Nyquist frequency
   f_mod = (0:Nfft-1) * (sps/Nfft);
   half_idx = 1:Nfft/2;

   figure('Name', 'Q3: Modulated Signal Spectra', 'Position', [200, 200, 800, 600]);
   % Half-Sine Modulated Signal Spectrum
   subplot(2,1,1);
   plot(f_mod(half_idx), mag_mod_hs(half_idx), 'b', 'LineWidth', 1.5);
   title('Spectrum of Modulated Half-Sine Signal (10 Random Bits)', 'FontSize', 12, 'FontWeight', 'bold');
   ylabel('Magnitude (dB)', 'FontSize', 11);
   grid on;
   xlim([0 16]); % View up to Nyquist (sps/2)
   ylim([-60 5]);

   % SRRC Modulated Signal Spectrum
   subplot(2,1,2);
   plot(f_mod(half_idx), mag_mod_srrc(half_idx), 'r', 'LineWidth', 1.5);
   title('Spectrum of Modulated SRRC Signal (10 Random Bits)', 'FontSize', 12, 'FontWeight', 'bold');
   ylabel('Magnitude (dB)', 'FontSize', 11);
   xlabel('Frequency (Hz)', 'FontSize', 11);
   grid on;
   xlim([0 2]); % Zoom in to see the sharp cutoff
   ylim([-80 5]);
end 

% 2/2.3 - Processing Selected Image, Turning into Binary Bit Stream
image_path = 'imgs/macjones.jpg';
N = 14400; % Determined blocks to send - total number of blocks
%binary_3D is an N long array of 64 x 8 binary arrays which represent the DCT coefficients of each image block
[binary_data, image_dimensions, scaled_DCT_dimensions, DCT_Image_min, DCT_Image_max] = preprocess_image(image_path, N); 

% 2.4 - Modulation of both pulse shaping functions
%---------------QUESTION 1 Design and Plot of Half Sine and SRRC Pulses--------
%Half Sine
sps = 32; % 32 Samples for both the half sine and SRRC 
T = 1;    % Duration in seconds
%y is our time domain half-sine pulse with 32 samples for 0 <= t < 1
y =half_sine_pulse(sps, T); %designs and then plots the half sine pulse in time and frequency domain

%SRRC
alpha = 0.5;
k = 6;
%s is our time domain SRRC pulse with 32 samples per bit, and a total duration of 2*K bit times
s = srrc_pulse(alpha, k, sps); %designs and then plots the SRRC pulse in time and frequency domain

%------------QUESTION 2 & 3 MODULATED SIGNALS PLOT 10 RANDOM BITS----------------

% generates 10 random bits, modulates them with both pulse shapes, and plots the time and frequency domain of the modulated signals
[unsampled_symbols, modulated_half_sine, modulated_srrc] = rand_bit_modulation(sps, k, s, y); 
%unsampled_symbols is the original 10 random bits mapped to PAM symbols and upsampled (with zeros in between)
%modulated_half_sine and modulated_srrc are the convolution of the upsampled symbols with the pulses

%-------------------------------------QUESTION 4 EYE DIAGRAM---------------------------------------

% For the eye diagram, we need to generate a much longer sequence of bits
% to get a statistically significant representation of the eye.
num_eye_bits = 1000;
eye_bits = randi([0 1], 1, num_eye_bits);
eye_symbols = 2*eye_bits - 1;
upsampled_eye_symbols = upsample(eye_symbols, sps);

% Modulate the long sequence
mod_eye_half_sine = conv(upsampled_eye_symbols, y);
mod_eye_srrc = conv(upsampled_eye_symbols, s);

% Create Eye Diagrams using MATLAB's built-in eyediagram function
% Parameters:
% 1. The modulated signal
% 2. Number of samples per trace. The prompt asks to plot over 1 bit duration.
%    Since sps=32 (32 samples per bit), we use 32.
% 3. The period of the signal (T=1).
% 4. Offset (delay) to center the eye properly.

% --- Half-sine Eye Diagram ---
% Note: The half-sine pulse starts at t=0. To perfectly center the eye 
% across a full bit duration, we cut off the first half of the first bit.
offset_half_sine = floor(sps / 2);
eyediagram(mod_eye_hs(offset_half_sine:end), sps, 1, 0);
title('Transmit Eye Diagram: Half-sine Pulse', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Amplitude', 'FontSize', 11);
xlabel('Time (s)', 'FontSize', 11);

% --- SRRC Eye Diagram ---
% Note: The SRRC pulse spans multiple bit durations and is symmetric around
% its peak (which occurs exactly at t = K bit durations).
% To center the eye, we need to offset by K * sps samples.
offset_srrc = k * sps;
eyediagram(mod_eye_srrc(offset_srrc:end), sps, 1, 0);
title(sprintf('Transmit Eye Diagram: SRRC Pulse (\\alpha = %.1f, K = %d)', alpha, k), 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Amplitude', 'FontSize', 11);
xlabel('Time (s)', 'FontSize', 11);

%------------------------QUESTION 5 Channel Simulation and Visualization --------------------------

h_taps = [1, 1/2, 3/4, -2/7];

% upsample(x, n) inserts n-1 zeros between each element.
% Using 32 will insert exactly 31 zeros between each tap.
h_upsampled = upsample(h_taps, sps);

%  Pad to the next power of 2 for FFT efficiency
% Current length is (4 taps - 1) * 32 + 1 = 97 samples.
% The next power of 2 after 97 is 128 (2^7).
current_length = length(h_upsampled);
next_power_of_2 = 2^ceil(log2(current_length));

% Append zeros to reach a length of 128
h_vector = [h_upsampled, zeros(1, next_power_of_2 - current_length)];

% we convolute this vector with the modulated signals we made in Question 2 to simulate effect of channel on transmitted message

channel_output_half_sine = conv(modulated_half_sine, h_vector);
channel_output_srrc = conv(modulated_srrc, h_vector);

%% Channel Impulse and Frequency Responses plotted

figure('Name', 'Q5: Channel Responses', 'Position', [200, 200, 800, 600]);

%  Impulse Response
subplot(2, 1, 1);
% Plot the original taps against their index (0 to 3)
stem(0:length(h_taps)-1, h_taps, 'filled', 'LineWidth', 1.5);
title('Channel Impulse Response', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Tap Index (spaced by bit duration T)', 'FontSize', 11);
ylabel('Amplitude', 'FontSize', 11);
grid on;

%  Magnitude and Phase Response
% We use the original h_taps (NOT upsampled) as per the implementation note
[H, w] = freqz(h_taps, 1, 1024); % 1024 points for a smooth curve

% Magnitude Plot
subplot(2, 2, 3);
plot(w/pi, 20*log10(abs(H)), 'LineWidth', 1.5);
title('Channel Magnitude Response', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Normalized Frequency (\times\pi rad/sample)', 'FontSize', 11);
ylabel('Magnitude (dB)', 'FontSize', 11);
grid on;

% Phase Plot
subplot(2, 2, 4);
plot(w/pi, unwrap(angle(H)), 'LineWidth', 1.5);
title('Channel Phase Response', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Normalized Frequency (\times\pi rad/sample)', 'FontSize', 11);
ylabel('Phase (rad)', 'FontSize', 11);
grid on;

%------------------------QUESTION 6 Channel Modulation Eye Diagrams --------------------------
% We convolute channel impulse vector with the modulated signals we made in Question 2 to plot the eye diagram of the channel output for each pulse shape.
channel_output_eye_half_sine = conv(mod_eye_half_sine, h_vector);
channel_output_eye_srrc = conv(mod_eye_srrc, h_vector);

% Half-sine Eye Diagram after channel
eyediagram(channel_output_eye_hs(offset_half_sine:end), sps, 1, 0);
title('Eye Diagram: Half-sine (After Channel)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Amplitude', 'FontSize', 11);
xlabel('Time (s)', 'FontSize', 11);

% SRRC Eye Diagram after channel
eyediagram(channel_output_eye_srrc(offset_srrc:end), sps, 1, 0);
title(sprintf('Eye Diagram: SRRC (After Channel) (\alpha = %.1f, K = %d)', alpha, k), 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Amplitude', 'FontSize', 11);
xlabel('Time (s)', 'FontSize', 11);

%------------------------QUESTION 7 Channel Modulation + Noise Eye Diagrams --------------------------

% Experiment with noise power values (sigma^2) for finishing Q7

noise_power_variance = 0.1; %Configuarable noise power values (variance)

standard_deviation = sqrt(noise_power_variance); %standard deviation

% Generate Gaussian noise matching the size of the received signals
noise_half_sine = standard_deviation * randn(size(channel_output_eye_half_sine));
noise_srrc = standard_deviation * randn(size(channel_output_eye_srrc));

% Add noise to the channel output
rx_noisy_half_sine = channel_output_eye_half_sine + noise_half_sine;
rx_noisy_srrc = channel_output_eye_srrc + noise_srrc;

% Noisy Half-sine Eye Diagram
% eyediagram() returns a figure handle which we use to set the window name
h1 = eyediagram(rx_noisy_hs(offset_hs:end), sps, 1, 0);
set(h1, 'Name', sprintf('Q7: Half-sine with Noise Power = %.3f', noise_power));
title(sprintf('Half-sine Eye Diagram (sigma^2 = %.3f)', noise_power), 'FontSize', 12, 'FontWeight', 'bold');

% Noisy SRRC Eye Diagram
h2 = eyediagram(rx_noisy_srrc(offset_srrc:end), sps, 1, 0);
set(h2, 'Name', sprintf('Q7: SRRC with Noise Power = %.3f', noise_power));
title(sprintf('SRRC Eye Diagram (sigma^2 = %.3f)', noise_power, 'FontSize', 12, 'FontWeight', 'bold'));