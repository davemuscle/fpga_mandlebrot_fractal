maxiter = 210;
poi = -1.42;

width_px = 1920-1;
height_px = 1080-1;

% compl_width = 3.5;
% compl_height = 2;
%compl_width = 0.000003;
%compl_height = 0.000015;
compl_width = 0.12;
compl_height = 0.06;

bl = (real(poi)-compl_width/2) + 1i*(imag(poi)-compl_height/2);
tl = (real(poi)-compl_width/2) + 1i*(imag(poi)+compl_height/2);
br = (real(poi)+compl_width/2) + 1i*(imag(poi)-compl_height/2);
tr = (real(poi)+compl_width/2) + 1i*(imag(poi)+compl_height/2);

%step = (imag(tl)-imag(bl))/99;
step_w = (real(br)-real(bl))/width_px;
step_h = (imag(tl)-imag(bl))/height_px;


[x, y] = meshgrid(real(bl):step_w:real(br), imag(tl):-step_h:imag(bl));
dim_x = length(x(1,:));
dim_y = length(x(:,1));

compl = x + 1i*y;

mandel = zeros(dim_y,dim_x);
for j = 1:dim_x
    for i = 1:dim_y
        mandel(i,j) = mandelbrot_calc(compl(i,j),maxiter);
    end
end

%normalized color scaling
numcolors = maxiter;
%palette = [jet(numcolors/2); flip(jet(numcolors/2))];
%palette = parula(numcolors);
palette = jet(numcolors);
colors = zeros(dim_y,dim_x, 3);

for j = 1:dim_x
    for i = 1:dim_y
        numiter = mandel(i,j);
        if(numiter == 0)
            colors(i,j, :) = 0;
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
            
            colors(i, j, 1) = red_interp;
            colors(i, j, 2) = grn_interp;
            colors(i, j, 3) = blu_interp;
      
        end
       
    end
end

imshow(colors)
%imagesc(colors)
%imagesc(mandel);

%moving average AA
% num_avg = 4;
% filt = ones(num_avg,num_avg);
% filt = filt/sum(sum(filt));
% for k = 1:3
%     colors(:, :, k) = filter2(filt, colors(:,:,k),'same');
% end

%imshow(colors)

%kernel = (1/16)*[1,2,1;2,4,2;1,2,1]; %gaussian blur3
%kernel = [-1,-1,-1;-1,8,-1;-1,-1,-1]; %edge detect
%kernel = [0, -1, 0; -1, 5, -1; 0, -1, 0]; %sharpen
%kernel = (1/9)*ones(3,3); %box blur
%kernel = (1/256)*[1,4,6,4,1; 4,16,24,16,4; 6,24,36,24,6; 4,16,24,16,4; 1,4,6,4,1]; %gblur5
%kernel = (-1/256)*[1,4,6,4,1; 4,16,24,16,4; 6,24,-476,24,6; 4,16,24,16,4; 1,4,6,4,1]; %unsharp mask

%kernel = 1*sinc(-3:0.3:3)'*sinc(-3:0.3:3);
% 
% colors_out = zeros(dim_y+length(kernel)-1, dim_x+length(kernel)-1, 3);
% 
% colors_out(:,:,1) = conv2(colors(:,:,1), kernel);
% colors_out(:,:,2) = conv2(colors(:,:,2), kernel);
% colors_out(:,:,3) = conv2(colors(:,:,3), kernel);

%colors = colors_out;
%anti alias attempt
% max = 3;
% step = 0.5;
% n = -max : step : max;
% kernel = (1)*sinc(n)'*sinc(n);
% kernel = kernel / (sum(sum(kernel)));
% 
% factor = 1;
% imag_up = imresize(colors, factor);
% [m,n, z] = size(imag_up);
% imag_filt = zeros((m)+length(kernel)-1, n+length(kernel)-1, 3);
% 
% imag_filt(:,:,1) = conv2(imag_up(:,:,1), kernel);
% imag_filt(:,:,2) = conv2(imag_up(:,:,2), kernel);
% imag_filt(:,:,3) = conv2(imag_up(:,:,3), kernel);
% 
% imag_down = imresize(imag_filt, 1/factor);
% colors_out = imresize(imag_filt, 1/factor);
% figure
% imshow(colors_out);


