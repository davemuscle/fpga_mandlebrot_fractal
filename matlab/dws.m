exciter = 0;
fs = 48000;
fulltime = 0.1 * fs;

delay_length_ms = 5;
feedback = 0.7;

delayline_len = delay_length_ms*fs/1000;
delayline = zeros(1,delayline_len);

idx = 1;

output_sound = zeros(1,fulltime);

pluck_len = 100;
start_tick = 500;
for tick = 1:fulltime
   
    %exciter logic
    if(tick > start_tick && tick < start_tick + pluck_len/2 + 1)
        exciter = (tick - start_tick) / (pluck_len/2);
    elseif(tick > start_tick+pluck_len/2 && tick < start_tick + pluck_len)
        exciter = (pluck_len + start_tick - tick) / (pluck_len/2);
    else
        exciter = 0;
    end 
    
    exciter_arr(tick) = exciter;
    
    read = delayline(idx);
    x = Hlp.numerator;
    mac = 0;
    %filter in loop
    for i = 0:(length(x)-1)
        
        filterread = x(i+1);
        
        if(idx - i < 1)
            mac = mac + x(i+1)*delayline(length(delayline)+idx-i);
        else
            mac = mac + x(i+1)*delayline(idx-i);
        end
    end
    
    write = exciter + feedback * mac;
    delayline(idx) = write;
    
    output_sound(tick) = mac;
    
    if(idx == delayline_len)
        idx = 1;
    else
        idx = idx + 1;
    end

end

player = audioplayer(output_sound, fs);