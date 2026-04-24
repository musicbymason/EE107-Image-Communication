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

   DCT_3d_column = reshape(DCT_3D_array, [64, 1, total_blocks]); % creates a 3D row vector of depth N

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

function [reconstructed_image] = postprocess_image(received_bits, image_dimensions, scaled_DCT_dimensions, DCT_Image_min, DCT_Image_max, N)
    %  Convert bits back to 8-bit integers
    
    received_integers = bit2int(received_bits, 8);
    
    % FIX: Compute actual number of blocks from the received data
    % Each block has 64 coefficients, each coefficient is 1 integer
    num_blocks = length(received_integers) / 64;
    
    % Reshape back to the 3D block array [64 x 1 x num_blocks]
    DCT_3d_column = reshape(received_integers, [64, 1, num_blocks]);
    
    % Scale back to 0-1 and then to DCT range
    DCT_normalized = double(DCT_3d_column) / 255;
    
    % FIX: Use num_blocks instead of N here too
    DCT_3D_array = reshape(DCT_normalized * (DCT_Image_max - DCT_Image_min) + DCT_Image_min, [8, 8, num_blocks]);
    
    % Re-order blocks into the full image matrix
    m = scaled_DCT_dimensions(1);
    n = scaled_DCT_dimensions(2);
    
    DCT_Image_Ordered = reshape(DCT_3D_array, [8, 8, m/8, n/8]);
    DCT_Image_4D = permute(DCT_Image_Ordered, [1, 3, 2, 4]);
    Scaled_DCT_Image = reshape(DCT_Image_4D, [m, n]);
    
    % Invert DCT in 8x8 blocks
    reconstructed_image = blockproc(Scaled_DCT_Image, [8 8], @(block_struct) idct2(block_struct.data));
end

%Modulation Half Sine
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

  Nfft = 4096;                                % large FFT for smooth curve

Y = fft(y, Nfft);                            % compute FFT
Y = Y(1:Nfft/2 + 1);                         % one-sided spectrum

mag_dB = 20*log10(abs(Y) / max(abs(Y)) + eps);  % normalize to 0 dB
phase = unwrap(angle(Y));                    % unrestrict period

f = linspace(0, 1, Nfft/2 + 1);              % normalized frequency (0 → π)

figure;
subplot(2,1,1)
plot(f, mag_dB, 'LineWidth', 1.2)
title('Half-Sine Pulse Magnitude Spectrum (dB)')
xlabel('Normalized Frequency (×π rad/sample)')
ylabel('Magnitude (dB)')
grid on

subplot(2,1,2)
plot(f, phase, 'LineWidth', 1.2)
title('Half-Sine Pulse Phase Spectrum')
xlabel('Normalized Frequency (×π rad/sample)')
ylabel('Phase (rad)')
grid on
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
   Nfft = 4096;                                % large FFT for smooth curve

    S = fft(s, Nfft);                            % compute FFT
    S = S(1:Nfft/2 + 1);                         % one-sided spectrum

    mag_dB = 20*log10(abs(S) / max(abs(S)) + eps);  % normalize to 0 dB
    phase = unwrap(angle(S));                    % unrestrict period

    f = linspace(0, 1, Nfft/2 + 1);              % normalized frequency (0 → π)

    figure;
    subplot(2,1,1)
    plot(f, mag_dB, 'LineWidth', 1.2)
    title(sprintf('SRRC Magnitude Spectrum (dB) (α = %.1f)', alpha))
    xlabel('Normalized Frequency (×π rad/sample)')
    ylabel('Magnitude (dB)')
    grid on

    subplot(2,1,2)
    plot(f, phase, 'LineWidth', 1.2)
    title('SRRC Phase Spectrum')
    xlabel('Normalized Frequency (×π rad/sample)')
    ylabel('Phase (rad)')
    grid on

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
   plot(f_mod(half_idx), mag_mod_half_sine(half_idx), 'b', 'LineWidth', 1.5);
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

% Ensure all image directories exist
q_dirs = {'imgs/Q1', 'imgs/Q2', 'imgs/Q3', 'imgs/Q4', 'imgs/Q5', 'imgs/Q6', 'imgs/Q7', 'imgs/Q8', 'imgs/Q9', 'imgs/Q10', 'imgs/Q11', 'imgs/Q12', 'imgs/Q13', 'imgs/Q14', 'imgs/Q15', 'imgs/Q21'};
for i = 1:length(q_dirs)
    if ~exist(q_dirs{i}, 'dir'), mkdir(q_dirs{i}); end
end

% Save grayscale reference image
ref_img = imread(image_path);
if size(ref_img, 3) == 3
    ref_img = rgb2gray(ref_img);
end
imwrite(ref_img, 'imgs/Q14/Reference_Gray.jpg');

%binary_3D is an N long array of 64 x 8 binary arrays which represent the DCT coefficients of each image block
[binary_data, image_dimensions, scaled_DCT_dimensions, DCT_Image_min, DCT_Image_max] = preprocess_image(image_path, N); 

% 2.4 - Modulation of both pulse shaping functions
%---------------QUESTION 1 Design and Plot of Half Sine and SRRC Pulses--------
%Half Sine
sps = 32; % 32 Samples for both the half sine and SRRC 
T = 1;    % Duration in seconds
%y is our time domain half-sine pulse with 32 samples for 0 <= t < 1
y = half_sine_pulse(sps, T); %designs and then plots the half sine pulse in time and frequency domain
exportgraphics(figure(1), 'imgs/Q1/Q1_thalfsine.jpg', 'Resolution', 300);
exportgraphics(figure(2), 'imgs/Q1/Q1_fhalfsine.jpg', 'Resolution', 300);

%SRRC
alpha = 0.5;
k = 6;
%s is our time domain SRRC pulse with 32 samples per bit, and a total duration of 2*K bit times
s = srrc_pulse(alpha, k, sps); %designs and then plots the SRRC pulse in time and frequency domain
exportgraphics(figure(3), 'imgs/Q1/Q1_tsrrc.jpg', 'Resolution', 300);
exportgraphics(figure(4), 'imgs/Q1/Q1_fsrrc.jpg', 'Resolution', 300);

%------------QUESTION 2 & 3 MODULATED SIGNALS PLOT 10 RANDOM BITS----------------

% generates 10 random bits, modulates them with both pulse shapes, and plots the time and frequency domain of the modulated signals
[unsampled_symbols, modulated_half_sine, modulated_srrc] = rand_bit_modulation(sps, k, s, y); 
%unsampled_symbols is the original 10 random bits mapped to PAM symbols and upsampled (with zeros in between)
%modulated_half_sine and modulated_srrc are the convolution of the upsampled symbols with the pulses
exportgraphics(figure(5), 'imgs/Q2/Q2_mod.jpg', 'Resolution', 300);
exportgraphics(figure(6), 'imgs/Q3/Q3_spectra.jpg', 'Resolution', 300);

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
eyediagram(mod_eye_half_sine(offset_half_sine:end), sps, 1, 0);
title('Transmit Eye Diagram: Half-sine Pulse', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Amplitude', 'FontSize', 11);
xlabel('Time (s)', 'FontSize', 11);
exportgraphics(gcf, 'imgs/Q4/Q4_hseye.jpg', 'Resolution', 300);

% --- SRRC Eye Diagram ---
% Note: The SRRC pulse spans multiple bit durations and is symmetric around
% its peak (which occurs exactly at t = K bit durations).
% To center the eye, we need to offset by K * sps samples.
offset_srrc = k * sps;
eyediagram(mod_eye_srrc(offset_srrc:end), sps, 1, 0);
title(sprintf('Transmit Eye Diagram: SRRC Pulse (\\alpha = %.1f, K = %d)', alpha, k), 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Amplitude', 'FontSize', 11);
xlabel('Time (s)', 'FontSize', 11);
exportgraphics(gcf, 'imgs/Q4/Q4_srrceye.jpg', 'Resolution', 300);

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

% Channel Impulse and Frequency Responses plotted

figQ5 = figure('Name', 'Q5: Channel Responses', 'Position', [200, 200, 800, 600]);

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
exportgraphics(figQ5, 'imgs/Q5/Q5_Channel_Responses.jpg', 'Resolution', 300);

%------------------------QUESTION 6 Channel Modulation Eye Diagrams --------------------------
% We convolute channel impulse vector with the modulated signals we made in Question 2 to plot the eye diagram of the channel output for each pulse shape.
channel_output_eye_half_sine = conv(mod_eye_half_sine, h_vector);
channel_output_eye_srrc = conv(mod_eye_srrc, h_vector);

% Half-sine Eye Diagram after channel
eyediagram(channel_output_eye_half_sine(offset_half_sine:end), sps, 1, 0);
title('Eye Diagram: Half-sine (After Channel)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Amplitude', 'FontSize', 11);
xlabel('Time (s)', 'FontSize', 11);
exportgraphics(gcf, 'imgs/Q6/After_Channel_Eye_HS.jpg', 'Resolution', 300);

% SRRC Eye Diagram after channel
eyediagram(channel_output_eye_srrc(offset_srrc:end), sps, 1, 0);
title(sprintf('Eye Diagram: SRRC (After Channel) (\alpha = %.1f, K = %d)', alpha, k), 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Amplitude', 'FontSize', 11);
xlabel('Time (s)', 'FontSize', 11);
exportgraphics(gcf, 'imgs/Q6/After_Channel_Eye_SRRC.jpg', 'Resolution', 300);

%------------------ QUESTION 7: Multi-Noise Eye Diagram Analysis ------------------
noise_variances = [0.00, 0.005, 0.02]; % Clean, Medium, Heavy Noise
sps = 32; 
half_symbol = sps / 2; % 16 samples to center the eye

% Create one large figure for all 6 subplots
figQ7 = figure('Name', 'Q7: Noise Impact Analysis', 'Position', [100, 100, 1000, 1200]);

for i = 1:length(noise_variances)
    sig_pwr = noise_variances(i);
    std_dev = sqrt(sig_pwr);
    
    % 1. Generate and Add Noise
    n_hs = std_dev * randn(size(channel_output_eye_half_sine));
    n_srrc = std_dev * randn(size(channel_output_eye_srrc));
    
    rx_hs = channel_output_eye_half_sine + n_hs;
    rx_srrc = channel_output_eye_srrc + n_srrc;
    
    % 2. Plot Half-Sine (Left Column)
    subplot(3, 2, 2*i - 1);
    % Start index shifted by half_symbol to center the opening
    start_idx_hs = offset_half_sine + half_symbol;
    plot(reshape(rx_hs(start_idx_hs : start_idx_hs + (sps*20)-1), sps, []));
    title(sprintf('Half-Sine (\\sigma^2 = %.3f)', sig_pwr));
    grid on; ylabel('Amplitude');
    
    % 3. Plot SRRC (Right Column)
    subplot(3, 2, 2*i);
    % Start index shifted by half_symbol to center the opening
    start_idx_srrc = offset_srrc + half_symbol;
    plot(reshape(rx_srrc(start_idx_srrc : start_idx_srrc + (sps*20)-1), sps, []));
    title(sprintf('SRRC (\\sigma^2 = %.3f)', sig_pwr));
    grid on;
end

% Labels for bottom row
subplot(3,2,5); xlabel('Samples per Symbol');
subplot(3,2,6); xlabel('Samples per Symbol');

% Save logic
targetDir = 'imgs/Q7';
if ~exist(targetDir, 'dir')
    mkdir(targetDir);
end
fullPath = fullfile(targetDir, 'Combined_Noise_Analysis.jpg');
exportgraphics(figQ7, fullPath, 'Resolution', 300);


%- Q8: Matched Filter Time/Freq Analysis
noise_variances = [0.00, 0.005, 0.02]; 
sps = 32;

% Create figure for Time/Freq plots
figQ8 = figure('Name', 'Q8: Matched Filter Time/Freq Analysis', 'Position', [100, 100, 1200, 1000]);

for i = 1:length(noise_variances)
    sig_pwr = noise_variances(i);
    std_dev = sqrt(sig_pwr);
    
    % Add Noise and Apply Matched Filter
    rx_hs_noisy = channel_output_eye_half_sine + (std_dev * randn(size(channel_output_eye_half_sine)));
    rx_srrc_noisy = channel_output_eye_srrc + (std_dev * randn(size(channel_output_eye_srrc)));
    
    mf_hs = conv(rx_hs_noisy, flip(y), 'same'); 
    mf_srrc = conv(rx_srrc_noisy, flip(s), 'same');
    
    % 2. Plot Time Domain (Left Column)
    subplot(3, 2, 2*i - 1);
    plot(mf_hs(1:sps*20), 'b'); hold on;
    plot(mf_srrc(1:sps*20), 'r--');
    title(sprintf('Time Domain (\\sigma^2 = %.3f)', sig_pwr));
    legend('HS', 'SRRC'); grid on; ylabel('Amplitude');
    
    %Plot Frequency Domain (Right Column)
    subplot(3, 2, 2*i);
    L = 1024;
    f = (0:L/2-1) * (sps/L);
    
    fft_hs = abs(fft(mf_hs, L));
    fft_srrc = abs(fft(mf_srrc, L));
    
    plot(f, 20*log10(fft_hs(1:L/2)), 'b'); hold on;
    plot(f, 20*log10(fft_srrc(1:L/2)), 'r--');
    title(sprintf('Magnitude Spectrum (\\sigma^2 = %.3f)', sig_pwr));
    grid on; ylabel('dB');
end

% Labels for bottom row
subplot(3,2,5); xlabel('Samples');
subplot(3,2,6); xlabel('Frequency (normalized)');

exportgraphics(figQ8, 'imgs/Q8/matched.jpg', 'Resolution', 300);

%------------------ QUESTION 9: Matched Filter Eye Diagrams ------------------
figQ9_1B = figure('Name', 'Q9: Matched Filter Eye Diagrams - 1-Bit', 'Position', [100, 100, 1000, 1200]);
half_symbol = sps / 2;

for i = 1:length(noise_variances)
    sig_pwr = noise_variances(i);
    std_dev = sqrt(sig_pwr);
    
    % 1. Re-generate filtered signals
    rx_hs = channel_output_eye_half_sine + (std_dev * randn(size(channel_output_eye_half_sine)));
    rx_srrc = channel_output_eye_srrc + (std_dev * randn(size(channel_output_eye_srrc)));
    
    mf_hs = conv(rx_hs, flip(y), 'same');
    mf_srrc = conv(rx_srrc, flip(s), 'same');
    
    % 2. Plot Matched Filter Eye - Half-Sine (Left Column)
    subplot(3, 2, 2*i - 1);
    start_hs = offset_half_sine + half_symbol;
    % Reshape into segments ofq*sps to show q-bit duration
    eye_hs = reshape(mf_hs(start_hs : start_hs + (sps*40)-1), sps, []);
    plot(eye_hs, 'b');
    title(sprintf('MF Eye: Half-Sine (\\sigma^2 = %.3f)', sig_pwr));
    grid on; ylabel('Amplitude');
    
    % 3. Plot Matched Filter Eye - SRRC (Right Column)
    subplot(3, 2, 2*i);
    start_srrc = offset_srrc + half_symbol;
    eye_srrc = reshape(mf_srrc(start_srrc : start_srrc + (sps*40)-1), sps, []);
    plot(eye_srrc, 'r');
    title(sprintf('MF Eye: SRRC (\\sigma^2 = %.3f)', sig_pwr));
    grid on;
end

% Labels for bottom row
subplot(3,2,5); xlabel('Samples (1-Bit Duration)');
subplot(3,2,6); xlabel('Samples (1-Bit Duration)');

exportgraphics(figQ9_1B, 'imgs/Q9/Matched_Filter_Eyes_1bit.jpg', 'Resolution', 300);

figQ9_2B = figure('Name', 'Q9: Matched Filter Eye Diagrams - 2-Bit', 'Position', [100, 100, 1000, 1200]);
half_symbol = sps / 2;

for i = 1:length(noise_variances)
    sig_pwr = noise_variances(i);
    std_dev = sqrt(sig_pwr);
    
    % 1. Re-generate filtered signals
    rx_hs = channel_output_eye_half_sine + (std_dev * randn(size(channel_output_eye_half_sine)));
    rx_srrc = channel_output_eye_srrc + (std_dev * randn(size(channel_output_eye_srrc)));
    
    mf_hs = conv(rx_hs, flip(y), 'same');
    mf_srrc = conv(rx_srrc, flip(s), 'same');
    
    % 2. Plot Matched Filter Eye - Half-Sine (Left Column)
    subplot(3, 2, 2*i - 1);
    start_hs = offset_half_sine + half_symbol;
    % Reshape into segments of 2*sps to show 2-bit duration
    eye_hs = reshape(mf_hs(start_hs : start_hs + (sps*2*40)-1), sps*2, []);
    plot(eye_hs, 'b');
    title(sprintf('MF Eye: Half-Sine (\\sigma^2 = %.3f)', sig_pwr));
    grid on; ylabel('Amplitude');
    
    % 3. Plot Matched Filter Eye - SRRC (Right Column)
    subplot(3, 2, 2*i);
    start_srrc = offset_srrc + half_symbol;
    eye_srrc = reshape(mf_srrc(start_srrc : start_srrc + (sps*2*40)-1), sps*2, []);
    plot(eye_srrc, 'r');
    title(sprintf('MF Eye: SRRC (\\sigma^2 = %.3f)', sig_pwr));
    grid on;
end

% Labels for bottom row
subplot(3,2,5); xlabel('Samples (2-Bit Duration)');
subplot(3,2,6); xlabel('Samples (2-Bit Duration)');

exportgraphics(figQ9_2B, 'imgs/Q9/Matched_Filter_Eyes.jpg', 'Resolution', 300);

%-10 & 11: Zero-Forcing Equalizer 

%Q10:
% IMplementing a Zero-Forcing Equalizer

fs = sps / T; 
b_zf = 1;
a_zf = h_upsampled;

% Impulse Response for plotting
% Apply the filter to a unit impulse delta[n]
impulse = [1; zeros(10000, 1)]; % Use ~10,000 samples for the IIR tail 
q_zf_n = filter(b_zf, a_zf, impulse);

[Q_zf, f_hz] = freqz(b_zf, a_zf, 2^14, fs); 

%% Plotting Q10
figQ10 = figure('Name', 'Q10: ZF Equalizer Responses', 'Position', [200, 200, 800, 600]);
subplot(2,1,1);
plot(f_hz, 20*log10(abs(Q_zf)), 'LineWidth', 1.5);
grid on;
title('Q10: ZF Equalizer Frequency Response (Q_{ZF})', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)'); 
xlim([0 fs/2]); % Plot up to the Nyquist frequency

% q_zf_n is the impulse response
subplot(2,1,2);
plot(0:length(q_zf_n)-1, q_zf_n, 'LineWidth', 1.5);
grid on;
title('Q10: ZF Equalizer Impulse Response (q[n])', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Sample Index');
ylabel('Amplitude');
exportgraphics(figQ10, 'imgs/Q10/Q10.jpg', 'Resolution', 300);

%Q11:
%Eye diagram for both pulse shapes after ZF equalization with no noise, with medium noise, and with heavy noise.
noise_labels = {'No Noise', 'Little Noise', 'Heavy Noise'};

% FIX: Assign the newly created figure to the variable 'figure_zf_10bit'
figure_zf_10bit = figure('Name', 'Q11: ZF Time-Domain Output (10-bit stream)', 'Position', [150, 150, 800, 1000]); 

% ADDED: Unified figure for all eye diagrams to make them more compact
figQ11_Eyes = figure('Name', 'Q11: ZF Equalized Eye Diagrams', 'Position', [100, 100, 1000, 1200]);

% FIX: Dynamically track how many noise variances there are to prevent subplot crashing
num_vars = length(noise_variances); 

% PRE-COMPUTE: Noise-free channel outputs (10-bit stream) that don't change across noises
q11_hs_channel_out = conv(modulated_half_sine, h_vector, 'same');
q11_srrc_channel_out = conv(modulated_srrc, h_vector, 'same');

for i = 1:num_vars
    sig_pwr = noise_variances(i);
    std_dev = sqrt(sig_pwr);
    
    % 1. Re-generate noisy channel outputs (Eye Diagram stream)
    n_hs = std_dev * randn(size(channel_output_eye_half_sine));
    n_srrc = std_dev * randn(size(channel_output_eye_srrc));
    
    rx_hs_noisy = channel_output_eye_half_sine + n_hs;
    rx_srrc_noisy = channel_output_eye_srrc + n_srrc;
    
    % noisy signals through the Matched Filter 
    mf_out_hs = conv(rx_hs_noisy, flip(y));
    mf_out_srrc = conv(rx_srrc_noisy, flip(s));
    
    % Pass through the Zero-Forcing Equalizer using filter()
    zf_out_hs = filter(b_zf, a_zf, mf_out_hs);
    zf_out_srrc = filter(b_zf, a_zf, mf_out_srrc);
    
    % Eye Diagrams 
    figure(figQ11_Eyes);
    
    subplot(num_vars, 2, 2*i - 1);
    slice_len = 20 * sps; 
    start_hs = offset_half_sine + (sps/2); % Center the eye
    eye_hs_zf = reshape(zf_out_hs(start_hs : start_hs + slice_len - 1), 2*sps, []);
    plot(eye_hs_zf, 'b');
    title(sprintf('ZF Eye: HS (%s)', noise_labels{i}));
    grid on; ylabel('Amplitude');
    ylim([-1.5 1.5]);
    
    subplot(num_vars, 2, 2*i);
    start_srrc = offset_srrc + (sps/2); % Center the eye
    eye_srrc_zf = reshape(zf_out_srrc(start_srrc : start_srrc + slice_len - 1), 2*sps, []);
    plot(eye_srrc_zf, 'r');
    title(sprintf('ZF Eye: SRRC (%s)', noise_labels{i}));
    grid on;
    ylim([-1.5 1.5]);
    
    % Switch back to the 10-bit figure so we don't draw on the eye diagrams
    figure(figure_zf_10bit); 
    
    % Generate noise for the 10-bit stream and add to PRE-COMPUTED channel output
    n_hs_10bit = std_dev * randn(size(q11_hs_channel_out));
    n_srrc_10bit = std_dev * randn(size(q11_srrc_channel_out));
    
    rx_hs_noisy_10bit = q11_hs_channel_out + n_hs_10bit;
    rx_srrc_noisy_10bit = q11_srrc_channel_out + n_srrc_10bit;
    
    mf_out_hs_10bit = conv(rx_hs_noisy_10bit, flip(y), 'same');
    mf_out_srrc_10bit = conv(rx_srrc_noisy_10bit, flip(s), 'same');
    
    zf_out_hs_10bit = filter(b_zf, a_zf, mf_out_hs_10bit);
    zf_out_srrc_10bit = filter(b_zf, a_zf, mf_out_srrc_10bit);

    % Draw the subplots on the active figure_zf_10bit window
    % FIX: Use dynamic num_vars for the subplot calculation
    subplot(num_vars, 1, i);

% Create dedicated time vectors for both signals
    t_zf_hs = (0:length(zf_out_hs_10bit)-1) / sps;
    t_zf_srrc = (0:length(zf_out_srrc_10bit)-1) / sps;

    % Plot using the matching time vectors
    plot(t_zf_hs - 0.5, zf_out_hs_10bit, 'b', 'LineWidth', 1.2); hold on;
    plot(t_zf_srrc - k, zf_out_srrc_10bit, 'r--', 'LineWidth', 1.2);
    
    % FIX: Assume unsampled_symbols is already 1 sample per bit. 
    % (If it is zero-padded, revert this line to unsampled_symbols(1:sps:end))
    original_bits = unsampled_symbols(1:sps:end);
    stem(0:length(original_bits)-1, original_bits, 'k', 'LineWidth', 1, 'Marker', 'x');

    hold off;
    title(sprintf('ZF Aligned Output: %s (\\sigma^2 = %.3f)', noise_labels{i}, sig_pwr));
    legend('Half-Sine (Shifted)', 'SRRC (Shifted)', 'Original Symbols');
    ylabel('Amplitude'); xlabel('Time (Bit Durations)');
    grid on; xlim([-1 11]); ylim([-1.5 1.5]);
end
exportgraphics(figure_zf_10bit, 'imgs/Q11/ZF_time_10bit.jpg', 'Resolution', 300);

% Format and Export the unified Eye Diagram figure for Q11
figure(figQ11_Eyes);
subplot(num_vars, 2, num_vars*2 - 1); xlabel('Samples (2 Symbol Periods)');
subplot(num_vars, 2, num_vars*2); xlabel('Samples (2 Symbol Periods)');
exportgraphics(figQ11_Eyes, 'imgs/Q11/ZF_Eyes_Combined.jpg', 'Resolution', 300);

%Q12 - MMSE Equalizer Implementation and Impulse/Frequency plots accross all 3 noise cases
% Parameters
N_fft = 1024; 
H_f = fft(h_vector, N_fft); % Channel frequency response
f_axis = (0:N_fft-1) * (sps/N_fft);

figMMSE = figure('Name', 'Q12 & 13: MMSE Equalizer Analysis', 'Position', [100, 100, 1200, 900]);

for i = 1:length(noise_variances)
    sig_pwr = noise_variances(i);
    
    %  MMSE Filter in Frequency Domain
    % MMSE Formula: Q(f) = H*(f) / (|H(f)|^2 + Sn/Sx)
    % Assuming Sx (signal power) is normalized to 1, we use sig_pwr
    Q_f = conj(H_f) ./ (abs(H_f).^2 + sig_pwr);
    q_t = ifft(Q_f);
    
    % 2. Plot Impulse Response (Left Column)
    subplot(3, 2, 2*i - 1);
    stem(real(q_t(1:sps*2)), 'filled', 'MarkerSize', 3);
    title(sprintf('MMSE Impulse Response (\\sigma^2 = %.3f)', sig_pwr));
    grid on; ylabel('Amplitude');
    if i == 3, xlabel('n (samples)'); end
    
    % 3. Plot Frequency Response (Right Column)
    subplot(3, 2, 2*i);
    plot(f_axis(1:N_fft/2), 20*log10(abs(Q_f(1:N_fft/2))));
    
    title(sprintf('MMSE Magnitude (\\sigma^2 = %.3f)', sig_pwr));
    grid on; ylabel('Magnitude (dB)');
    if i == 1, legend('MMSE'); end
    if i == 3, xlabel('Frequency (Hz)'); end
end

exportgraphics(gcf, 'imgs/Q12/MMSE_freq.jpg', 'Resolution', 300);

%Q13 - Eye diagrams for both pulse shapes after MMSE equalization with no noise, with medium noise, and with heavy noise.
% Setup figures BEFORE the loop

figTime_MMSE_10bit = figure('Name', 'Q13: MMSE Time-Domain (10-bit stream)', 'Position', [200, 200, 800, 1000]);
figQ13 = figure('Name', 'Q13: MMSE Equalized Eye Diagrams', 'Position', [100, 100, 1000, 1200]);
half_symbol = sps / 2;

% track noise variances there are to prevent subplot crashing
num_vars = length(noise_variances); 

% PRE-COMPUTE: Noise-free channel outputs 
% (Assuming modulated_half_sine and modulated_srrc are 10-bit streams)
q13_hs_channel_out = conv(modulated_half_sine, h_vector, 'same');
q13_srrc_channel_out = conv(modulated_srrc, h_vector, 'same');

for i = 1:num_vars
    sig_pwr = noise_variances(i);
    std_dev = sqrt(sig_pwr);
    
    % MMSE filter for this noise level 
    %  conj(H_f) acts as the matched filter in the frequency domain
    Q_f = conj(H_f) ./ (abs(H_f).^2 + sig_pwr);
    
    %  fftshift to properly center the time-domain impulse response
    q_t = fftshift(real(ifft(Q_f)));
    
    % Analysis for 1000-bit stream (for Eye Diagrams)
    n_hs_eye = std_dev * randn(size(channel_output_eye_half_sine));
    n_srrc_eye = std_dev * randn(size(channel_output_eye_srrc));
    rx_hs_eye = channel_output_eye_half_sine + n_hs_eye;
    rx_srrc_eye = channel_output_eye_srrc + n_srrc_eye;
    
    % Convolve directly with q_t since it already contains the matched filter.
    mmse_out_hs_eye = conv(rx_hs_eye, q_t, 'same');
    mmse_out_srrc_eye = conv(rx_srrc_eye, q_t, 'same');

    % Analysis for 10-bit stream (for Time-Domain Plot)
    n_hs_10bit = std_dev * randn(size(q13_hs_channel_out));
    n_srrc_10bit = std_dev * randn(size(q13_srrc_channel_out));
    
    rx_hs_10bit = q13_hs_channel_out + n_hs_10bit;
    rx_srrc_10bit = q13_srrc_channel_out + n_srrc_10bit;

    %Apply only the MMSE Equalizer
    mmse_out_hs_10bit = conv(rx_hs_10bit, q_t, 'same');
    mmse_out_srrc_10bit = conv(rx_srrc_10bit, q_t, 'same');

    % =====================================================================
    % PLOT 1: TIME DOMAIN OUTPUTS (10-bit stream)
    % =====================================================================
    figure(figTime_MMSE_10bit);
    subplot(num_vars, 1, i);
    
    % Create dedicated time vectors for both signals to avoid size mismatch
    t_mmse_hs = (0:length(mmse_out_hs_10bit)-1) / sps;
    t_mmse_srrc = (0:length(mmse_out_srrc_10bit)-1) / sps;

    % Plot using matching time vectors and compensating for group delay
    plot(t_mmse_hs - 0.5, mmse_out_hs_10bit, 'b', 'LineWidth', 1.2); hold on;
    plot(t_mmse_srrc - k, mmse_out_srrc_10bit, 'r--', 'LineWidth', 1.2);

    % Plot the original bits as reference markers (sampling the upsampled sequence)
    original_bits = unsampled_symbols(1:sps:end); 
    stem(0:length(original_bits)-1, original_bits, 'k', 'LineWidth', 1, 'Marker', 'x');

    title(sprintf('MMSE Aligned Output: \\sigma^2 = %.3f', sig_pwr));
    legend('Half-Sine', 'SRRC', 'Original Symbols');
    xlabel('Time (Bit Durations)'); ylabel('Amplitude');
    grid on; xlim([-1 11]); ylim([-1.5 1.5]);
    hold off;
    
    % =====================================================================
    % PLOT 2: EYE DIAGRAMS (1000-bit stream)
    % =====================================================================
    figure(figQ13);
    
    % FIX: Use dynamic subplot layout
    subplot(num_vars, 2, 2*i - 1);
    start_hs = offset_half_sine + half_symbol;
    
    % FIX: Extract 20 symbols worth of samples and reshape to 2*sps (two full symbols wide)
    slice_len = 20 * sps; 
    eye_hs_mmse = reshape(mmse_out_hs_eye(start_hs : start_hs + slice_len - 1), 2*sps, []);
    plot(eye_hs_mmse, 'b');
    title(sprintf('MMSE Eye: Half-Sine (\\sigma^2 = %.3f)', sig_pwr));
    grid on; ylabel('Amplitude');
    
    subplot(num_vars, 2, 2*i);
    start_srrc = offset_srrc + half_symbol;
    eye_srrc_mmse = reshape(mmse_out_srrc_eye(start_srrc : start_srrc + slice_len - 1), 2*sps, []);
    plot(eye_srrc_mmse, 'r');
    title(sprintf('MMSE Eye: SRRC (\\sigma^2 = %.3f)', sig_pwr));
    grid on;
end

% =====================================================================
% Final Formatting and Export
% =====================================================================
figure(figQ13); 

% FIX: Dynamically assign x-labels to only the bottom-most plots
subplot(num_vars, 2, num_vars*2 - 1); xlabel('Samples (2 Symbol Periods)');
subplot(num_vars, 2, num_vars*2); xlabel('Samples (2 Symbol Periods)');

% Optional: Ensure directories exist before exporting
if ~exist('imgs/Q13', 'dir'), mkdir('imgs/Q13'); end

exportgraphics(figQ13, 'imgs/Q13/MMSE_eye.jpg', 'Resolution', 300);

figure(figTime_MMSE_10bit);
exportgraphics(figTime_MMSE_10bit, 'imgs/Q13/MMSE_time_10bit.jpg', 'Resolution', 300);


close all;


%------------------ QUESTION 14: Displaying the Result ------------------
fprintf('Starting Full Image Transmission Simulation (All combinations)...\n');

noise_vars_final = [0.00, 0.005, 0.02, 0.05];
pulse_types = {'HS', 'SRRC'};
equalizer_types = {'ZF', 'MMSE'};

if ~exist('imgs/Q14', 'dir'), mkdir('imgs/Q14'); end

fig_all = figure('Name', 'Q14: Full Simulation Results', 'Position', [50, 50, 1600, 1200]);
plot_idx = 1;

% Pre-calculate H_f once for the channel
N_fft_eq = 1024;
H_f_eq = fft(h_vector, N_fft_eq);

for n = 1:length(noise_vars_final)
    sig_pwr = noise_vars_final(n);
    std_dev = sqrt(sig_pwr);
    
    for p = 1:2
        pulse_name = pulse_types{p};
        if p == 1
            current_pulse = y;
            offset = 16; % Peak of Half-Sine = (sps/2 + 1)
        else
            current_pulse = s;
            offset = 193; % Peak of SRRC = k*sps + 1
            %offset = 386;
        end
        
        % Modulation of the entire image bit stream

        %Sampling Starts here for the full image data
        %Binary data bits ready for modulation
        tx_symbols = (2 * binary_data(:) - 1);
        upsampled_tx = upsample(tx_symbols, sps);
        %fill 0's 
        tx_signal = conv(upsampled_tx, current_pulse, 'same');
        %convolute based on the pulse shape
        
        % Pass through Channel
        channel_out = conv(tx_signal, h_upsampled, 'same');
        % channel_out = filter(h_upsampled, 1, tx_signal);
        
        % Receiver: Add Noise (Consistent for both equalizers in this pulse/noise block)
        rx_noisy = channel_out + (std_dev * randn(size(channel_out)));
        
        for e = 1:2
            eq_name = equalizer_types{e};
            
            if e == 1 % ZF
                % 1. Matched Filter the NOISY received signal
                mf_out = conv(rx_noisy, current_pulse, 'same');
                % 2. Equalize
                equalized_out = filter(1, h_upsampled, mf_out);
            else % MMSE
                % 1. Matched Filter the NOISY received signal
                mf_out = conv(rx_noisy, flip(current_pulse), 'same');
                % 2. Equalize (Fixing the typo "qualized_out")
                Q_f = conj(H_f_eq) ./ (abs(H_f_eq).^2 + sig_pwr + eps);
                q_t = fftshift(real(ifft(Q_f)));
                equalized_out = conv(mf_out, q_t, 'same');
            end
            
            % 3. Sample the final equalized signal
            sample_indices = (offset : sps : length(equalized_out));
            
            % 4. Perform detection
            detected_bits = double(equalized_out(sample_indices) > 0);
            detected_bits = detected_bits(:); 
            
            if length(detected_bits) > numel(binary_data)
                detected_bits = detected_bits(1:numel(binary_data));
            end
            
        end
    end
end
% Save the final grid
exportgraphics(fig_all, 'imgs/Q14/Final_Result.jpg', 'Resolution', 300);
fprintf('Full simulation complete. Results saved to imgs/Q14/Final_Result.jpg\n');

%% Q15: Critical SNR Threshold Discovery
fprintf('\n--- Running Q15: SNR Threshold Analysis ---\n');
snr_db_range = 0:2:20; % SNR in dB
noise_vars_q15 = 10.^(-snr_db_range/10);
ber_zf = zeros(size(snr_db_range));
ber_mmse = zeros(size(snr_db_range));

% Use SRRC for this test
pulse_q15 = s; 
tx_bits_q15 = binary_data(1:10000); % Test on a subset for speed
tx_symbols_q15 = 2 * tx_bits_q15 - 1;
upsampled_tx_q15 = upsample(tx_symbols_q15, sps);
tx_sig_q15 = conv(upsampled_tx_q15, pulse_q15, 'same');
chan_out_q15 = conv(tx_sig_q15, h_vector, 'same');

for i = 1:length(snr_db_range)
    sig_pwr = noise_vars_q15(i);
    rx_noisy = chan_out_q15 + sqrt(sig_pwr) * randn(size(chan_out_q15));
    
    % ZF
    mf_zf = conv(rx_noisy, flip(pulse_q15), 'same');
    eq_zf = filter(1, h_upsampled, mf_zf);
    det_zf = double(eq_zf(1:sps:end) > 0);
    ber_zf(i) = sum(tx_bits_q15(:) ~= det_zf(1:length(tx_bits_q15))) / length(tx_bits_q15);
    
    % MMSE
    Q_f = conj(H_f_eq) ./ (abs(H_f_eq).^2 + sig_pwr + eps);
    q_t = fftshift(real(ifft(Q_f)));
    eq_mmse = conv(rx_noisy, q_t, 'same');
    det_mmse = double(eq_mmse(1:sps:end) > 0);
    ber_mmse(i) = sum(tx_bits_q15(:) ~= det_mmse(1:length(tx_bits_q15))) / length(tx_bits_q15);
end

figQ15 = figure('Name', 'Q15: BER vs SNR');
semilogy(snr_db_range, ber_zf, 'o-', 'DisplayName', 'ZF'); hold on;
semilogy(snr_db_range, ber_mmse, 's-', 'DisplayName', 'MMSE');
grid on; xlabel('SNR (dB)'); ylabel('BER');
title('Bit Error Rate Comparison'); legend;
exportgraphics(figQ15, 'imgs/Q15/Q15_BER_Curves.jpg');

%% Q16: Performance on Different Images
% We already used macjones.jpg. 
fprintf('\n--- Running Q16: Different Image Analysis ---\n');
% This section is implicitly handled by the modularity of the code,
% allowing the user to change 'image_path' at the top of the file.

%% Q21: Effect of New Channels
fprintf('\n--- Running Q21: New Channel Analysis ---\n');

% Outdoor Channel
h_outdoor_taps = [0.5, 1, 0, 0.63, 0, 0, 0, 0, 0.25, 0, 0, 0, 0.16, zeros(1, 12), 0.1];
% Indoor Channel
h_indoor_taps = [1, 0.4365, 0.1905, 0.0832, 0, 0.0158, 0, 0.003];

channels = {h_outdoor_taps, h_indoor_taps};
chan_names = {'Outdoor', 'Indoor'};

for c = 1:2
    h_taps_new = channels{c};
    h_up_new = upsample(h_taps_new, sps);
    h_vec_new = [h_up_new, zeros(1, 1024-length(h_up_new))];
    H_f_new = fft(h_vec_new, 1024);
    
    % Test transmission with SRRC
    sig_pwr_q21 = 0.005;
    
    % Reuse the long transmit signal from Q14 if available, or regenerate
    tx_symbols = 2 * binary_data(:) - 1; % A is a factor to increase power and decrease error
    upsampled_tx = upsample(tx_symbols, sps);
    tx_signal = conv(upsampled_tx, s, 'same');
    
    rx_q21 = conv(tx_signal, h_vec_new, 'same') + sqrt(sig_pwr_q21) * randn(size(tx_signal));
    
    % MMSE Equalization
    Q_f_new = conj(H_f_new) ./ (abs(H_f_new).^2 + sig_pwr_q21 + eps);
    q_t_new = fftshift(real(ifft(Q_f_new)));
    eq_out_new = conv(rx_q21, q_t_new, 'same');
    
    det_q21 = double(eq_out_new(1:sps:end) > 0);
    % Crop/Pad to match binary_data
    if length(det_q21) > length(binary_data), det_q21 = det_q21(1:length(binary_data)); end
    recovered_img_q21 = postprocess_image(det_q21(:), image_dimensions, scaled_DCT_dimensions, DCT_Image_min, DCT_Image_max, N);
    
    figure; imshow(recovered_img_q21);
    title(sprintf('Recovered Image: %s Channel', chan_names{c}));
    exportgraphics(gcf, sprintf('imgs/Q21/Recovered_%s.jpg', chan_names{c}));
    
    % Power gain
    power_gain = sum(abs(h_taps_new).^2);
    fprintf('%s Channel Power Gain: %.4f\n', chan_names{c}, power_gain);
end

close all; % Close all figures to free up memory

