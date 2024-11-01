function symbols = OQPSKdemodulation3(rxWaveform, offset)
%% Receive-side oversampling
samp = 100;
samples = rxWaveform(1, samp+1+offset: samp/2: end-samp+offset);
sample_size = length(samples);

%% Samples to chips.
phase_shift = zeros(1, sample_size-1);
for ith = 2: 1: sample_size
   phase_shift(1, ith-1) = angle(samples(1,ith) * conj(samples(1,ith-1))); 
end
chips = phase_shift(1, :) > 0;
chips = [chips, randi([0, 1], 1, 1)];
chips = reshape(chips, [32, length(chips)/32])';
[num_sym, ~] = size(chips);

%% Chips to symbols.
chipMap = ...
     [0 1 1 0 0 0 0 0 0 1 1 1 0 1 1 1 1 0 1 0 1 1 1 0 0 1 1 0 1 1 0 0;
      0 1 0 0 1 1 1 0 0 0 0 0 0 1 1 1 0 1 1 1 1 0 1 0 1 1 1 0 0 1 1 0;
      0 1 1 0 1 1 0 0 1 1 1 0 0 0 0 0 0 1 1 1 0 1 1 1 1 0 1 0 1 1 1 0;
      0 1 1 0 0 1 1 0 1 1 0 0 1 1 1 0 0 0 0 0 0 1 1 1 0 1 1 1 1 0 1 0;
      0 0 1 0 1 1 1 0 0 1 1 0 1 1 0 0 1 1 1 0 0 0 0 0 0 1 1 1 0 1 1 1;
      0 1 1 1 1 0 1 0 1 1 1 0 0 1 1 0 1 1 0 0 1 1 1 0 0 0 0 0 0 1 1 1;
      0 1 1 1 0 1 1 1 1 0 1 0 1 1 1 0 0 1 1 0 1 1 0 0 1 1 1 0 0 0 0 0;
      0 0 0 0 0 1 1 1 0 1 1 1 1 0 1 0 1 1 1 0 0 1 1 0 1 1 0 0 1 1 1 0;
      0 0 0 1 1 1 1 1 1 0 0 0 1 0 0 0 0 1 0 1 0 0 0 1 1 0 0 1 0 0 1 1;
      0 0 1 1 0 0 0 1 1 1 1 1 1 0 0 0 1 0 0 0 0 1 0 1 0 0 0 1 1 0 0 1;
      0 0 0 1 0 0 1 1 0 0 0 1 1 1 1 1 1 0 0 0 1 0 0 0 0 1 0 1 0 0 0 1;
      0 0 0 1 1 0 0 1 0 0 1 1 0 0 0 1 1 1 1 1 1 0 0 0 1 0 0 0 0 1 0 1;
      0 1 0 1 0 0 0 1 1 0 0 1 0 0 1 1 0 0 0 1 1 1 1 1 1 0 0 0 1 0 0 0;
      0 0 0 0 0 1 0 1 0 0 0 1 1 0 0 1 0 0 1 1 0 0 0 1 1 1 1 1 1 0 0 0;
      0 0 0 0 1 0 0 0 0 1 0 1 0 0 0 1 1 0 0 1 0 0 1 1 0 0 0 1 1 1 1 1;
      0 1 1 1 1 0 0 0 1 0 0 0 0 1 0 1 0 0 0 1 1 0 0 1 0 0 1 1 0 0 0 1];

symbols = zeros(1, num_sym);
for ith = 1: 1: num_sym
    matchResults = sum(xor(chips(ith, :), chipMap), 2);
    [~, index] = min(matchResults); 
    symbols(1, ith) = index;
end

end

