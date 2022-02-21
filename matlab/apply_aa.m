function output = apply_aa(colors, kernel)

colors_out(:,:,1) = conv2(colors(:,:,1), kernel, 'same');
colors_out(:,:,2) = conv2(colors(:,:,2), kernel, 'same');
colors_out(:,:,3) = conv2(colors(:,:,3), kernel, 'same');

output = colors_out;
return