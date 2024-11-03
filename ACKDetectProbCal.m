function results = ACKDetectProbCal(settings)
    global signalPower_dBm;
    
    SNR_dB = settings.SNR;
    ACKThreshold = settings.ACKThreshold;
    ORSPhaseThreshold = settings.ORSPhaseThreshold;
    ORSNumThreshold = settings.ORSNumThreshold;
    numORS = settings.numORS;
    offset = settings.offset;
    lenType = settings.ACKSignalLenType;
    RXType = settings.RXType;
    
    
        function samples = Sampling(rxWaveform, offset, RXType)
            % Sampling with offset
            if isequal(RXType, 'BLE')
                sampInterval = 100;
                [numMsg, signalLen] = size(rxWaveform);
                sampleSize = length((2*sampInterval+1): sampInterval :(signalLen-sampInterval));
                samples = zeros(numMsg, sampleSize);
                for ith = 1: 1: numMsg
                    samples(ith, :) = rxWaveform(ith, (2*sampInterval+1+offset(ith, 1)): sampInterval :(signalLen-sampInterval+offset(ith, 1)));
                end
            else
                sampInterval = 0.05; % us
                OSR = 100; % = 1us
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
            end
        end
    
    noisePower_mW = (db2pow(signalPower_dBm - SNR_dB)) ./ 2 ./ 1000;
    message = 1;
    txWaveform = PHYOQPSK_ACKfeedback(message, numORS, lenType, RXType);
    % Scale signal.
    % dBm = dBW + 30
%     scaleCoeff = sqrt(db2pow(signalPower_dBm - 30) ./ 1);
%     txWaveform = txWaveform .* scaleCoeff;
    samples = Sampling(txWaveform, offset.offsetValue, RXType);
    
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
    
    results.succACKProb = binocdf(ACKThreshold, numORS, succORSProb, 'upper');

end