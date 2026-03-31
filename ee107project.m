%Preprocessing:

% image into readable data format
I = imread('macjones.png');
I = rgb2gray(I);
I_post = im2double(I);
[row, col] = size(I)

% linear scaling/clamping to ceiling of 1 and floor of 0
% Apply DCT in 8x8 blocks
DCT_Image = blockproc(I_post, [8 8], @(block_struct) dct2(block_struct.data));

DCT_Image_min = min(min(DCT_Image)); % takes the minimum of each col and then takes the minimum of all those minimums
DCT_Image_max = max(max(DCT_Image)); % takes the maximum of each col and then takes the maximum of all those maximum
Scaled_DCT_Image = (DCT_Image - DCT_Image_min) / (DCT_Image_max - DCT_Image_min); % normalization formula (array with min at 0 and max at 1)
% image into readable data format - rn is 1280 x 720  to 8 * 8 1280 * (720 / 64)

[m, n] = size(Scaled_DCT_Image);

temp_reshaped = reshape(Scaled_DCT_Image, [8, m/8, 8, n/8]);

temp_permuted = permute(temp_reshaped, [1, 3, 2, 4]);

total_blocks = (m * n) / 64; % 14400 in our case
dct_3d_array = reshape(temp_permuted, [8, 8, total_blocks]);

%Conversion to a bit stream

N = 14400; % Determined blocks to send - total number of blocks

dct_3d_column = reshape(dct_3d_array, [64, 1, N]); % creates a 3D row vector of depth N

% Scale 0-1 to 0-255 and convert to 8-bit integers
DCT_int = uint8(dct_3d_column * 255);

dct_vector = DCT_int(:); % Flattens into a vector

% Convert to double for the function, but keep it in the 0-255 range
% 'msb' ensures the most significant bit (128) is at index 1
binary_data = int2bit(double(dct_vector), 8);

% 1. Reshape to separate the bits from the coefficients
% This creates a [8 bits x 64 coeffs x N blocks] array
temp = reshape(binary_data, 8, 64, []);

% 2. Permute to swap the first two dimensions
% This moves the 64 coeffs to rows and 8 bits to columns
% Resulting size: [64 x 8 x N]
binary_3d = permute(temp, [2, 1, 3]);
