function txWaveformNoisy = AddNoise(SNR, txWaveform)
    % Assume signal power is 10dBm, while current power is 1W.
    global signalPower_dBm;
    % dBm = dBW + 30

    [numSym, signalLength] = size(txWaveform);

    % Scale signal.
    scaleCoeff = sqrt(db2pow(signalPower_dBm - 30) ./ 1);
    txWaveform = txWaveform .* scaleCoeff;

    % Add noise.
    % SNR = signalPower_dBm - noisePower_dBm
    noisePower_dBm = signalPower_dBm - SNR;
    txWaveformNoisy = txWaveform + wgn(numSym, signalLength, noisePower_dBm, 'dBm', 'complex');
end