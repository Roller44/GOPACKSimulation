function samples = Sampling(waveform, offset, RXType)
    % Sampling with offset
    OSR = 100; % = 1us
    
    if isequal(RXType, 'BLE')
        sampInterval = 1; % us
        beta = 1; % Down-sampling factor
        sampInterval = OSR * sampInterval * beta;
        [numMsg, signalLen] = size(waveform);
        sampStart = OSR * 2 + 1;
        sampEnd = signalLen - OSR * 1;
        sampleSize = length(sampStart:sampInterval:sampEnd);
        samples = zeros(numMsg, sampleSize);
        for ith = 1: 1: numMsg
            samples(ith, :) = waveform(ith, (2*sampInterval+1+offset): sampInterval :(sampEnd+offset));
        end
    elseif isequal(RXType, 'WiFi')
        sampInterval = 0.05; % us
        beta = 5; % Down-sampling factor
        sampInterval = OSR * sampInterval * beta;
        [numMsg, signalLen] = size(waveform);
        sampStart = OSR * 1.5;
        sampEnd = signalLen - OSR * 1 - 1;
        sampleSize = length(sampStart:sampInterval:sampEnd);
        samples = zeros(numMsg, sampleSize);
        for ith = 1: 1: numMsg
            samples(ith, :) = waveform(ith, (sampStart+offset): sampInterval :(sampEnd+offset));
        end
    else
        error('RXType must be either BLE or WiFi.');
    end
end