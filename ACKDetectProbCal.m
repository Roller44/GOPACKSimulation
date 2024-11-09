function results = ACKDetectProbCal(settings)
    global signalPower_dBm;
    
    SNR_dB = settings.SNR;
    ORSNumThreshold = settings.ORSNumThreshold;
    ORSPhaseThreshold = settings.ORSPhaseThreshold;
    ORSNumThreshold = settings.ORSNumThreshold;
    numORS = settings.numORS;
    offset = settings.offset;
    lenType = settings.ACKSignalLenType;
    RXType = settings.RXType;
    
    
    noisePower_mW = (db2pow(signalPower_dBm - SNR_dB)) ./ 2 ./ 1000;
    message = 1;
    txWaveform = PHYOQPSK_ACKfeedback(message, numORS, lenType, RXType);
    samples = Sampling(txWaveform, offset, RXType);
    
    if isequal(lenType, 'short')
        power = samples * samples' ./ (numORS+1);
    else
        power = samples * samples' ./ (2*numORS);
    end
    SNR = power ./ (2.*noisePower_mW);
    % SNR = db2pow(SNR_dB);
    
    funACK = @(x) exp(-SNR .* (1 - cos(ORSPhaseThreshold) .* cos(x))) ./ (1 - cos(ORSPhaseThreshold) .* cos(x));
    % funNotACK = @(x) exp(0 .* (1 - cos(ORSPhaseThreshold) .* cos(x))) ./ (1 - cos(ORSPhaseThreshold) .* cos(x));
    
    % succORSProb = (1-notACKProb) .* (1-(sin(ORSPhaseThreshold)./(2.*pi)) * integral(funACK,-pi/2,pi/2))...
    %     + notACKProb.*(sin(ORSThreshold)./(2.*pi)) * integral(funNotACK,-pi/2,pi/2);
    
    succORSProb = 1 - (sin(ORSPhaseThreshold)./(2.*pi)) * integral(funACK, -pi/2, pi/2);
    if isequal(RXType, 'BLE')
        phaseShiftInterval = 1;
    else
        phaseShiftInterval = 16;
    end
    numPhase = size(samples, 2) - phaseShiftInterval; 
    results.succORSProb = binocdf(ORSNumThreshold, numPhase, succORSProb, 'upper');
    
    results.succACKProb = binocdf(ORSNumThreshold, numORS, succORSProb, 'upper');

end