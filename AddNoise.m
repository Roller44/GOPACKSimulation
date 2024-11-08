function txWaveformNoisy = AddNoise(SNR, txWaveform)
    % Assume signal power is 10dBm.
    global signalPower_dBm;
    [numSym, signalLength] = size(txWaveform);
    % Add noise.
    % SNR = signalPower_dBm - noisePower_dBm
    noisePower_dBm = signalPower_dBm - SNR;
    txWaveformNoisy = txWaveform + wgn(numSym, signalLength, noisePower_dBm, 'dBm', 'complex');

    % signalPower_dBW = signalPower_dBm - 30;
    % txWaveformNoisy = awgn(txWaveform, SNR, 'measured');
end