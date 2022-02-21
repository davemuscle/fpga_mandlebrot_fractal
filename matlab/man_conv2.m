%
x = magic(3);
test = [0.1, 0.25, 0.2; 0.5, 0.75, 0.6; 0.25, 0.4, 0.3];

%manual 2d convolution
[m1,n1] = size(x);
[m2,n2] = size(test);

%
%expand input to match the output size
osize = m2 + m1 - 1;

input_ext = zeros(osize);
low_idx = (osize-m2)/2 + 1;

input_ext(low_idx:m1+1, low_idx:n1+1) = x;

start_idx_x = 2;
start_idx_y = 2;

out = zeros(m1,n1);

for jj = 0:n1-1
    start_idx_y = 2; 
    for ii = 0:m1-1
        chunk_out = input_ext(start_idx_x-1:start_idx_x+1, start_idx_y-1:start_idx_y+1);
        buba = chunk_out.*test;
        buba_sum = sum(sum(buba));
        
        out(jj+1, ii+1) = buba_sum;
        
        start_idx_y = start_idx_y + 1;
        
    end
    start_idx_x = start_idx_x + 1;
end