function [iteration, radius] = mbrot_calc(coord_r, coord_i, max)

x = coord_r;
y = coord_i;

for i = 0:max-1
    %calculate x^2 and y^2
    y2 = y*y;
    x2 = x*x;
    
    %calculate sums
    y = 2*x*y + coord_i;
    x = x2 - y2 + coord_r;

    r2 = x2 + y2;
    
    if(r2 >= 4)
        iteration = i;
        radius = r2;
        return;
    end
    
end

iteration = 0;
radius = r2;
return;

end