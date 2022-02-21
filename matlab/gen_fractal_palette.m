scale = 32;
numcolors = 140*scale;
numcolors_np2 = nextpow2(numcolors);
numpalettes = 2;

%init matrix
colors = zeros(numpalettes, 2^numcolors_np2, 3);

zero_pad = zeros(2^numcolors_np2 - numcolors-1,3);

%setup color matrix
palette = [jet(numcolors/2); flip(jet(numcolors/2))];
colors(1, :, :) = [[0,0,0]; palette; zero_pad];

palette = [parula(numcolors/2); flip(parula(numcolors/2))];
colors(2, :, :) = [[0,0,0]; palette; zero_pad];


reds = uint8(255*colors(:,:,1));
greens = uint8(255*colors(:,:,2));
blues = uint8(255*colors(:,:,3));

reds_ext = uint8(zeros(numpalettes*2^numcolors_np2,1));
greens_ext = uint8(zeros(numpalettes*2^numcolors_np2,1));
blues_ext = uint8(zeros(numpalettes*2^numcolors_np2,1));

for i = 1:numpalettes
    
    low_bound = ((i-1)*2^numcolors_np2) + 1;
    upp_bound = i*2^numcolors_np2;
    
    reds_ext(low_bound:upp_bound) = reds(i,:);
    greens_ext(low_bound:upp_bound) = greens(i,:);
    blues_ext(low_bound:upp_bound) = blues(i,:);
end

rom = {zeros(numpalettes * 2^numcolors_np2)};

for i = 1:length(reds_ext)
    rom{i} = [dec2bin(reds_ext(i),8), dec2bin(greens_ext(i),8), dec2bin(blues_ext(i),8)];
end

fid = fopen(['fractal_color_lut.data'], 'wt');
fprintf(fid, '%s\n', rom{:});
fclose(fid);