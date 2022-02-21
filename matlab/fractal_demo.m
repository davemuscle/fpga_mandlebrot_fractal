%pick the maximum number of iterations, escape radius, and quanitization
%factor
maxiter = 80;
escape = 40;

smooth = 1;
mandle = 0;
julia  = 0;

%good poi for mandle
%-1.42 + 0j, w: 0.24, h: 0.14
poi = -1.42 + 0*1i;

%good poi for julia:
%c = -0.78 + 1i*0.136;
%poi = 0;

screen_w = 1920;
screen_h = 1080;

compl_w = 1;
compl_h = compl_w*screen_h/screen_w;

bl = (real(poi)-compl_w/2) + 1i*(imag(poi)-compl_h/2);
tl = (real(poi)-compl_w/2) + 1i*(imag(poi)+compl_h/2);
br = (real(poi)+compl_w/2) + 1i*(imag(poi)-compl_h/2);
tr = (real(poi)+compl_w/2) + 1i*(imag(poi)+compl_h/2);

step_w = compl_w/(screen_w-1);
step_h = step_w;

[x, y] = meshgrid(real(bl):step_w:real(br), imag(tl):-step_h:imag(bl));
dim_x = length(x(1,:));
dim_y = length(x(:,1));

compl = x + 1i*y;

fractal = zeros(dim_y,dim_x);

for jj = 1:dim_x
    for ii = 1:dim_y
        
        r2 = 0; x = 0; y = 0; x2 = 0; y2 = 0;
        break_true = 0;
        real_input = real(compl(ii,jj));
        imag_input = imag(compl(ii,jj));
        
        for i = 0:maxiter-1

            if(smooth == 0)
                if(r2 >= escape)
                    output = i;
                    break_true = 1;
                    break;
                end
            else
                if(r2 >= escape)
                    smoothed = log2(log2(floor(r2))*3/20);
                    sn = i - smoothed;
                    output = sn;
                    break_true = 1;
                    break;
                end
            end

            %calculate x^2 and y^2 (first stage)
            y2 = y*y;
            x2 = x*x;

            %calculate sums (second stage)
            y = 2*x*y + imag_input;
            x = x2 - y2 + real_input;

            r2 = x2 + y2;

        end
        
        if(break_true == 0)
           output = 0; 
        end

        fractal(ii,jj) = output;
        
    end
end

%normalized color scaling
scale = floor(escape/4);
numcolors = scale*maxiter;
palette = [jet(numcolors/2); flip(jet(numcolors/2))];

colors = zeros(dim_y,dim_x, 3);

for jj = 1:dim_x
    for ii = 1:dim_y
        numiter = fractal(ii,jj);
        
        numiter = round(numiter*scale);
        if(numiter == 0)
            colors(ii,jj, :) = 0;
        else
            %saturate
            if(numiter > numcolors)
                numiter = numcolors;
            end
            
            numiter = mod(numiter, numcolors);
            numiter = numiter + 1;
            
            red1 = palette(numiter, 1);
            grn1 = palette(numiter, 2);
            blu1 = palette(numiter, 3);
            
            colors(ii, jj, 1) = red1;
            colors(ii, jj, 2) = grn1;
            colors(ii, jj, 3) = blu1;
      
        end
       
    end
end

figure
imshow(colors)
title('fractal without post processing');

gblur3 = (1/16)*[1,2,1;2,4,2;1,2,1]; %gaussian blur3

img_aa = colors;
img_aa = apply_aa(img_aa, gblur3);

figure
imshow(img_aa)
title('fractal with post processing');
%figure
%imshow(img_aa)
%title('fractal interlaced with post processing');
