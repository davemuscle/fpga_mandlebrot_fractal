fid_real = fopen('out_act.txt', 'r');
fid_imag = fopen('out_exp.txt', 'r');

actuals=fscanf(fid_real, '%d');
tests=fscanf(fid_imag, '%d');

fclose(fid_real);
fclose(fid_imag);

figure
hold on
plot(actuals);
plot(tests);
legend('actuals', 'expected');

diff_act = diff(actuals);
diff_exp = diff(tests);

diff_act_slope = diff_act(length(diff_act))/length(diff_act)

figure
hold on
plot(diff_act);
plot(diff_exp);
legend('actuals deriv', 'exp deriv');

error = 100*(abs(tests-actuals))./tests;
figure
plot(error); title('error');