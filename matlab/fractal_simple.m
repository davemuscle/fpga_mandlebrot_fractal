%pick the maximum number of iterations, escape radius, and quanitization
%factor
maxiter = 80;
escape = 20;
q_f = 2^-24;
smooth = 1;
%good poi for mandle
%-1.42 + 0j, w: 0.12, h: 0.06
poi = -1.42 + 0*1i;

%good poi for julia:
%c = -0.78 + 1i*0.136;
%poi = 0;

screen_w = 1920;
screen_h = 1080;

compl_w = 0.24;
compl_h = 0.14;

bl = (real(poi)-compl_w/2) + 1i*(imag(poi)-compl_h/2);
tl = (real(poi)-compl_w/2) + 1i*(imag(poi)+compl_h/2);
br = (real(poi)+compl_w/2) + 1i*(imag(poi)-compl_h/2);
tr = (real(poi)+compl_w/2) + 1i*(imag(poi)+compl_h/2);

step_w = (real(br)-real(bl))/(screen_w-1);
step_h = (imag(tl)-imag(bl))/(screen_h-1);

[x, y] = meshgrid(real(bl):step_w:real(br), imag(tl):-step_h:imag(bl));
dim_x = length(x(1,:));
dim_y = length(x(:,1));

compl = x + 1i*y;

fractal = zeros(dim_y,dim_x);
for jj = 1:dim_x
    for ii = 1:dim_y
        fractal(ii,jj) = fractal_core(compl(ii,jj),compl(ii,jj),maxiter,escape,q_f, smooth);
        %fractal(ii,jj) = fractal_core(compl(ii,jj),c,maxiter,escape,q_f);

    end
end

%normalized color scaling
scale = 3;
numcolors = scale*maxiter;
%palette = [jet(numcolors/2); flip(jet(numcolors/2))];
%palette = parula(numcolors);
%palette = hsv(numcolors);
palette = jet(numcolors);
%palette = white(numcolors);
%palette = gray(numcolors);
colors = zeros(dim_y,dim_x, 3);

for jj = 1:dim_x
    for ii = 1:dim_y
        numiter = fractal(ii,jj);
        
        %quantize the count value
        numiter = (2^-8)*floor((numiter / (2^-8)));
        %scale it
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
            numiter2 = numiter+1;
            numiter2 = mod(numiter2, numcolors);
            numiter2 = numiter2 + 1;
            
            red1 = palette(numiter, 1);
            red2 = palette(numiter2, 1);
            
            grn1 = palette(numiter, 2);
            grn2 = palette(numiter2, 2);
            
            blu1 = palette(numiter, 3);
            blu2 = palette(numiter2, 3);
            
            red_interp = 0.5*(red1+red2);
            grn_interp = 0.5*(grn1+grn2);
            blu_interp = 0.5*(blu1+blu2);
            
            %colors(ii, jj, 1) = red_interp;
            %colors(ii, jj, 2) = grn_interp;
            %colors(ii, jj, 3) = blu_interp;
            
            colors(ii, jj, 1) = red1;
            colors(ii, jj, 2) = grn1;
            colors(ii, jj, 3) = blu1;
      
        end
       
    end
end

figure
imshow(colors)
title('fractal_simple')

img_aa = apply_aa(colors);
figure
imshow(img_aa)
title('fractal simple with aa');


