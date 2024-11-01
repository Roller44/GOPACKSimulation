function decode_accur = XBeeRX(rxWaveform, offset, mapMtrL, mapMtrR, ACK_sym)
%% Receive-side oversampling
samp = 100;
samples = rxWaveform(1, samp+1+offset: samp: end-samp+offset);
sample_size = length(samples);

%% Samples to bits.
phase_shift = zeros(1, sample_size-1);
for ith = 2: 1: sample_size
    phase_shift(1, ith-1) = angle(samples(1,ith) * conj(samples(1,ith-1)));
end
bits = phase_shift(1, :) > 0;
% bits = [bits, randi([0, 1], 1, 1)];
bits = reshape(bits, [16, length(bits)/16])';
[num_sym, ~] = size(bits);

%% Bits to symbols.
map = [mapMtrL; mapMtrR];

symbols = zeros(1, num_sym);
for ith = 1: 1: num_sym
    matchResults = sum(xor(bits(ith, :), map), 2);
    [~, index] = min(matchResults);
    if index <= 16
        symbols(1, ith) = index;
    else
        symbols(1, ith) = index - 16;
    end
end

if sum(symbols == ACK_sym) == length(ACK_sym)
    decode_accur = 1;
else
    decode_accur = 0;
end
