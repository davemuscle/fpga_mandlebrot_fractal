%pick the maximum number of iterations, escape radius, and quanitization
%factor
maxiter = 80;
escape = 20;
q_f = 2^-24;
smooth = 0;
%good poi for mandle
%-1.42 + 0j, w: 0.24, h: 0.14
poi = -1.42 + 0*1i;

%good poi for julia:
%c = -0.78 + 1i*0.136;
%poi = 0;

screen_w = 1920;
screen_h = 540;

%compl_w = 0.24;
%compl_h = 0.14;
compl_w = 1;
compl_h = compl_w*540/1920;

bl = (real(poi)-compl_w/2) + 1i*(imag(poi)-compl_h/2);
tl = (real(poi)-compl_w/2) + 1i*(imag(poi)+compl_h/2);
br = (real(poi)+compl_w/2) + 1i*(imag(poi)-compl_h/2);
tr = (real(poi)+compl_w/2) + 1i*(imag(poi)+compl_h/2);

%step_w = (real(br)-real(bl))/(screen_w-1);
%step_h = (imag(tl)-imag(bl))/(screen_h-1);
step_w = compl_w/(screen_w-1);
step_h = step_w;
%step_h = compl_h/(screen_h-1);

[x, y] = meshgrid(real(bl):step_w:real(br), imag(tl):-step_h:imag(bl));
dim_x = length(x(1,:));
dim_y = length(x(:,1));

compl = x + 1i*y;

fractal = zeros(dim_y,dim_x);
radi = zeros(dim_y, dim_x);

for jj = 1:dim_x
    for ii = 1:dim_y
        
        [fractal(ii,jj), radi(ii,jj)] = fractal_core(compl(ii,jj),compl(ii,jj),maxiter,escape,q_f, smooth);
        %[fractal(ii,jj), radi(ii,jj)] = fractal_core(compl(ii,jj),c,maxiter,escape,q_f, smooth,logs_b);

        %fractal(ii,jj) = fractal_core(compl(ii,jj),c,maxiter,escape,q_f);

    end
end

[m,n] = size(fractal);

fractal_deint = zeros(2*m,n);
radi_deint = zeros(2*m,n);
m = 1;

%bob deinterlace
for ii = 1:dim_y
    fractal_deint(m,:) = fractal(ii,:);
    fractal_deint(m+1,:) = fractal(ii,:);
    
    radi_deint(m,:) = floor(radi(ii,:));
    radi_deint(m+1,:) = floor(radi(ii,:));
    
    m = m + 2;
end

fractal = fractal_deint;
[dim_y, dim_x] = size(fractal_deint);

%normalized color scaling
scale = 32;
numcolors = scale*maxiter;
palette = [jet(numcolors/2); flip(jet(numcolors/2))];
%palette = [parula(numcolors/2); flip(parula(numcolors/2))];
%palette = parula(numcolors);
%palette = hsv(numcolors);
%palette = jet(numcolors);
%palette = white(numcolors);
%palette = gray(numcolors);

palette = (2^-8).*floor(palette/(2^-8));
colors = zeros(dim_y,dim_x, 3);

for jj = 1:dim_x
    for ii = 1:dim_y
        numiter = fractal(ii,jj);
        
        %quantize it
        numiter = (2^-8)*floor((numiter / (2^-8)));
        
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


%figure
%imshow(colors)
%title('fractal interlaced')

avg = (1/4)*ones(2,2);
gblur3 = (1/16)*[1,2,1;2,4,2;1,2,1]; %gaussian blur3
edged = [-1,-1,-1;-1,8,-1;-1,-1,-1]; %edge detect
sharpen = [0, -1, 0; -1, 5, -1; 0, -1, 0]; %sharpen
lapl = [0, 1, 0; 1, -4, 1; 0, 1, 0]; %sharpen
bblur = (1/9)*ones(3,3); %box blur
gblur5 = (1/256)*[1,4,6,4,1; 4,16,24,16,4; 6,24,36,24,6; 4,16,24,16,4; 1,4,6,4,1]; %gblur5
unshrp = (-1/256)*[1,4,6,4,1; 4,16,24,16,4; 6,24,-476,24,6; 4,16,24,16,4; 1,4,6,4,1]; %unsharp mask


% max = 3;
% step = (2*max)/15;
% n = -max : step : max;
% sinc_kernel = (1)*sinc(n)'*sinc(n);
% sinc_kernel = sinc_kernel / (sum(sum(sinc_kernel)));
%figure
%surf(sinc_kernel)
img_aa = colors;
img_aa = apply_aa(img_aa, gblur5);
img_aa = apply_aa(img_aa, sharpen);
%img_aa = apply_aa(img_aa, gblur3);

%ones_size = 3;
%img_aa = apply_aa(img_aa, ones(ones_size)/(sum(sum(ones(ones_size)))));

%img_aa = apply_aa(img_aa, edged);
%img_aa = apply_aa(img_aa, unshrp);
%img_aa = apply_aa(img_aa, sinc_kernel);

figure
imshow(img_aa)
title('fractal interlaced with post processing');

%figure
%imshow(colors - img_aa(1:dim_y, 1:dim_x, :))
%title('leftovers')