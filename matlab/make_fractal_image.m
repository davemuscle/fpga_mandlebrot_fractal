maxiter = 90;
fractal = dlmread('C:/Users/Dave/Desktop/FPGA/Projects/BigusShapus/fractal/vga2txt.txt');

[dim_y, dim_x] = size(fractal);

numcolors = maxiter;
%palette = [jet(numcolors/2); flip(jet(numcolors/2))];
%palette = parula(numcolors);
palette = jet(numcolors);
%palette = white(numcolors);
%palette = gray(numcolors);

colors = zeros(dim_y,dim_x, 3);

for jj = 1:dim_x
    for ii = 1:dim_y
        numiter = fractal(ii,jj);
        if(numiter == 0)
            colors(ii,jj, :) = 0;
        else
            %saturate
            if(numiter > numcolors)
                numiter = numcolors;
            end
          
            colors(ii, jj, 1) = palette(numiter,1);
            colors(ii, jj, 2) = palette(numiter,2);
            colors(ii, jj, 3) = palette(numiter,3);
      
        end
       
    end
end

imshow(colors)