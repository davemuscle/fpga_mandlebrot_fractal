plane = compl;

start_x = 1235;
start_y = 480;

width_x = 128;
width_y = 32;

plane = compl(start_y:start_y+width_y-1, start_x:start_x+width_x-1);
fracs = fractal(2*start_y:2:2*start_y+2*width_y-1, start_x:start_x+width_x-1);
imgs  = colors(2*start_y:2:2*start_y+2*width_y-1, start_x:start_x+width_x-1, :);

%convert the plane and fracs vectors to 1D
[m,n] = size(plane);
plane_1d = zeros(1, m*n);
fracs_1d = zeros(1, m*n);
idx = 1;
for j=1:m 
    for i=1:n
        plane_1d(idx) = (2^24)*plane(j,i);
        fracs_1d(idx) = fracs(j,i);
        idx = idx + 1;
    end
end
xorvec = uint32((2^32)-1);
plane_real_rom = {zeros(m*n,1)};
plane_imag_rom = {zeros(m*n,1)};
fracs_rom = {zeros(m*n,1)};

%send the plane data to a text file
for i = 1:length(plane_1d)
    
    plane_real = real(plane_1d(i));
    plane_imag = imag(plane_1d(i));
    
    if(plane_real < 0)
       temp_real = uint32(abs(plane_real));
       temp_real = bitxor(temp_real, xorvec);
       temp_real = temp_real + 1;
       %plane_rom{i} = dec2bin(temp,32);
    else
       temp_real = int32(plane_real);
       %plane_rom{i} = dec2bin(int32(plane_1d(i)),32);
    end

    if(plane_imag < 0)
       temp_imag = uint32(abs(plane_imag));
       temp_imag = bitxor(temp_imag, xorvec);
       temp_imag = temp_imag + 1;
    else
       temp_imag = int32(plane_imag);
    end
    
    plane_real_rom{i} = dec2bin(temp_real,32);
    plane_imag_rom{i} = dec2bin(temp_imag,32);
    
    
    fracs_rom{i} = dec2bin(uint8(fracs_1d(i)),8);
    
end

fid = fopen(['slice_plane_real.data'], 'wt');
fprintf(fid, '%s\n', plane_real_rom{:});
fclose(fid);

fid = fopen(['slice_plane_imag.data'], 'wt');
fprintf(fid, '%s\n', plane_imag_rom{:});
fclose(fid);

fid = fopen(['slice_count.data'], 'wt');
fprintf(fid, '%s\n', fracs_rom{:});
fclose(fid);
