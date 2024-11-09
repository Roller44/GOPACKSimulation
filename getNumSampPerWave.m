function numSampPerWave = getNumSampPerWave(lenType, RXType, numORS)
    txWaveform = PHYOQPSK_ACKfeedback(1, numORS, lenType, RXType);
    samples = Sampling(txWaveform, 0, RXType);
    if isequal(lenType, 'short')
        numSampPerWave = size(samples, 2) / (numORS + 1);
    else
        numSampPerWave = size(samples, 2) / (2 * numORS);
    end
end