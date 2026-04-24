sps = 32;
T = 1;
t_half_sine = linspace(0, T, sps + 1);
t_half_sine = t_half_sine(1:end-1);
y = sin(pi * t_half_sine);
y = y / norm(y);

alpha = 0.5;
k = 6;
s = rcosdesign(alpha, 2*k, sps);
s = s / norm(s);

h_taps = [1, 1/2, 3/4, -2/7];
h_upsampled = upsample(h_taps, sps);
current_length = length(h_upsampled);
next_power_of_2 = 2^ceil(log2(current_length));
h_vector = [h_upsampled, zeros(1, next_power_of_2 - current_length)];

% Test for Half Sine
test_bits = [1, zeros(1, 100)];
tx_symbols = 2*test_bits - 1;
upsampled_tx = upsample(tx_symbols, sps);

% HS
tx_hs = conv(upsampled_tx, y, 'same');
chan_out_hs = conv(tx_hs, h_vector, 'same');
mf_out_hs = conv(chan_out_hs, flip(y), 'same');
% ZF for HS
zf_out_hs = filter(1, h_upsampled, mf_out_hs);
[~, best_offset_hs_zf] = max(abs(zf_out_hs(1:sps*2)));

% MMSE for HS (using sig_pwr = 0 for simplicity of finding peak)
N_fft = 1024;
H_f = fft(h_vector, N_fft);
Q_f = conj(H_f) ./ (abs(H_f).^2 + 0.005);
q_t = fftshift(real(ifft(Q_f)));
mmse_out_hs = conv(mf_out_hs, q_t, 'same');
[~, best_offset_hs_mmse] = max(abs(mmse_out_hs(1:sps*2)));

% SRRC
tx_srrc = conv(upsampled_tx, s, 'same');
chan_out_srrc = conv(tx_srrc, h_vector, 'same');
mf_out_srrc = conv(chan_out_srrc, flip(s), 'same');
% ZF for SRRC
zf_out_srrc = filter(1, h_upsampled, mf_out_srrc);
[~, best_offset_srrc_zf] = max(abs(zf_out_srrc(1:sps*k*2)));

% MMSE for SRRC
mmse_out_srrc = conv(mf_out_srrc, q_t, 'same');
[~, best_offset_srrc_mmse] = max(abs(mmse_out_srrc(1:sps*k*2)));

fprintf('HS ZF Best Offset: %d\n', best_offset_hs_zf);
fprintf('HS MMSE Best Offset: %d\n', best_offset_hs_mmse);
fprintf('SRRC ZF Best Offset: %d\n', best_offset_srrc_zf);
fprintf('SRRC MMSE Best Offset: %d\n', best_offset_srrc_mmse);
