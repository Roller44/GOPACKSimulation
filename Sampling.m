function samples = Sampling(rxWaveform, offset, RXType)
    % Sampling with offset
    OSR = 100; % = 1us

    if isequal(RXType, 'BLE')
        sampInterval = 1; % us
        beta = 1; % Down-sampling factor
        sampInterval = OSR * sampInterval * beta;
        [numMsg, signalLen] = size(rxWaveform);
        sampStart = OSR * 2 + 1;
        sampEnd = signalLen - OSR * 1;
        sampleSize = length(sampStart:sampInterval:sampEnd);
        samples = zeros(numMsg, sampleSize);
        for ith = 1: 1: numMsg
            samples(ith, :) = rxWaveform(ith, (2*sampInterval+1+offset(ith, 1)): sampInterval :(sampEnd+offset(ith, 1)));
        end
    elseif isequal(RXType, 'WiFi')
        sampInterval = 0.05; % us
        beta = 5; % Down-sampling factor
        sampInterval = OSR * sampInterval * beta;
        [numMsg, signalLen] = size(rxWaveform);
        sampStart = OSR * 1.5 + 1;
        sampEnd = signalLen - OSR * 1.5;
        sampleSize = length(sampStart:sampInterval:sampEnd);
        samples = zeros(numMsg, sampleSize);
        for ith = 1: 1: numMsg
            samples(ith, :) = rxWaveform(ith, (sampStart+offset(ith, 1)): sampInterval :(sampEnd+offset(ith, 1)));
        end
    else
        error('RXType must be either BLE or WiFi.');
    end
end