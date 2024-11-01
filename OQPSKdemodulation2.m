function symbols = OQPSKdemodulation2(rxWaveform)
%% Receive-side oversampling
samp = 100;
samples = rxWaveform(1, 1: samp/2: end);
sample_size = length(samples);

%% Samples to chips.
phase_shift = zeros(1, sample_size-1);
for ith = 2: 1: sample_size
   phase_shift(1, ith-1) = angle(samples(1,ith) * conj(samples(1,ith-1))); 
end
states = zeros(1, sample_size);
for ith = 1: 1: sample_size
    phase_value = angle(samples(1, ith));
   if (phase_value>=0&&phase_value<pi/4) || (phase_value<0&&phase_value>-pi/4)
       states(1,ith) = 1;
   elseif phase_value>pi/4&&phase_value<3*pi/4
       states(1,ith) = 2;
   elseif phase_value<-pi/4&&phase_value>-3*pi/4
       states(1,ith) = 4;
   else
       states(1,ith) = 3;
   end
end

chips = zeros(1, sample_size-1);
for ith = 1: 1: length(phase_shift)
   if states(1,ith) == 1
       if phase_shift(1,ith) >= 0
           chips(1,ith) = 1;
       else
           chips(1,ith) = 0;
       end
   elseif states(1,ith) == 2
       if phase_shift(1,ith) >= 0
           chips(1,ith) = 0;
       else
           chips(1,ith) = 1;
       end
   elseif states(1,ith) == 3
       if phase_shift(1,ith) >= 0
           chips(1,ith) = 0;
       else
           chips(1,ith) = 1;
       end
   elseif states(1, ith) == 4
       if phase_shift(1,ith) >= 0
           chips(1,ith) = 1;
       else
           chips(1,ith) = 0;
       end
   else
       chips(1,ith) = 1;
   end
end

chips = [chips, randi([0, 1], 1, 1)];
chips = reshape(chips, [32,length(chips)/32])';
[num_sym, ~] = size(chips);


%% Chips to symbols.
chipMap = ...
     [1 1 0 1 1 0 0 1 1 1 0 0 0 0 1 1 0 1 0 1 0 0 1 0 0 0 1 0 1 1 1 0;
      1 1 1 0 1 1 0 1 1 0 0 1 1 1 0 0 0 0 1 1 0 1 0 1 0 0 1 0 0 0 1 0;
      0 0 1 0 1 1 1 0 1 1 0 1 1 0 0 1 1 1 0 0 0 0 1 1 0 1 0 1 0 0 1 0;
      0 0 1 0 0 0 1 0 1 1 1 0 1 1 0 1 1 0 0 1 1 1 0 0 0 0 1 1 0 1 0 1;
      0 1 0 1 0 0 1 0 0 0 1 0 1 1 1 0 1 1 0 1 1 0 0 1 1 1 0 0 0 0 1 1;
      0 0 1 1 0 1 0 1 0 0 1 0 0 0 1 0 1 1 1 0 1 1 0 1 1 0 0 1 1 1 0 0;
      1 1 0 0 0 0 1 1 0 1 0 1 0 0 1 0 0 0 1 0 1 1 1 0 1 1 0 1 1 0 0 1;
      1 0 0 1 1 1 0 0 0 0 1 1 0 1 0 1 0 0 1 0 0 0 1 0 1 1 1 0 1 1 0 1;
      1 0 0 0 1 1 0 0 1 0 0 1 0 1 1 0 0 0 0 0 0 1 1 1 0 1 1 1 1 0 1 1;
      1 0 1 1 1 0 0 0 1 1 0 0 1 0 0 1 0 1 1 0 0 0 0 0 0 1 1 1 0 1 1 1;
      0 1 1 1 1 0 1 1 1 0 0 0 1 1 0 0 1 0 0 1 0 1 1 0 0 0 0 0 0 1 1 1;
      0 1 1 1 0 1 1 1 1 0 1 1 1 0 0 0 1 1 0 0 1 0 0 1 0 1 1 0 0 0 0 0;
      0 0 0 0 0 1 1 1 0 1 1 1 1 0 1 1 1 0 0 0 1 1 0 0 1 0 0 1 0 1 1 0;
      0 1 1 0 0 0 0 0 0 1 1 1 0 1 1 1 1 0 1 1 1 0 0 0 1 1 0 0 1 0 0 1;
      1 0 0 1 0 1 1 0 0 0 0 0 0 1 1 1 0 1 1 1 1 0 1 1 1 0 0 0 1 1 0 0;
      1 1 0 0 1 0 0 1 0 1 1 0 0 0 0 0 0 1 1 1 0 1 1 1 1 0 1 1 1 0 0 0];

symbols = zeros(1, num_sym);
for ith = 1: 1: num_sym
    matchResults = sum(xor(chips(ith, :), chipMap), 2);
    [~, index] = min(matchResults); 
    symbols(1, ith) = index;
end

end

