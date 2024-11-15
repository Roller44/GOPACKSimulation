function results = DecodeProbCal(settings)

SNR_dB = settings.SNR;
numORS = settings.numORS;
offset = settings.offset;
lenType = settings.ACKSignalLenType;
RXType = settings.RXType;
global signalPower_dBm;
    

    function quaProb = QuaProbCal(message, offsetValue, numORS, lenType, SNR_dB, RXType)
        % This function calculate the probability of a sample falls into
        % each quandrant.
        
        txWaveform = PHYOQPSK_ACKfeedback(message, numORS, lenType, RXType);
        samples = Sampling(txWaveform, offsetValue, RXType); 
        if isequal(lenType, 'short')
            numSampPerWave = size(samples, 2) / (numORS + 1);
        else
            numSampPerWave = size(samples, 2) / (2 * numORS);
        end
        samples = samples(1, numSampPerWave+1:1:2*numSampPerWave);
        sampleReal = real(samples);
        sampleImag = imag(samples);

        % Calculate noise power
        % dBm = dBW + 30 
        % noisePower_mW = db2pow(signalPower_dBm - SNR_dB - 30) / 2;
        % An alternative approach
        signalPower_mW = samples * samples' / length(samples);
        SNR_linear = 10^(SNR_dB / 10);
        noisePower_mW = signalPower_mW / SNR_linear / 2;
        

        quaProb = zeros(4, numSampPerWave);
        for samp_ith = 1: 1: size(samples, 2)
            fun = @(x, y) (1./(2*pi*noisePower_mW)) .*...
                    exp(-((x - sampleReal(samp_ith)).^2 + (y - sampleImag(samp_ith)).^2) ./ (2*noisePower_mW));

            quaProb(1, samp_ith) = integral2(fun, 0, Inf, 0, Inf);
            quaProb(2, samp_ith) = integral2(fun, -Inf, 0, 0, Inf);
            quaProb(4, samp_ith) = integral2(fun, 0, Inf, -Inf, 0);
            % Compensate integral errors.
            quaProb(3, samp_ith) = 1 - quaProb(1, samp_ith) - quaProb(2, samp_ith) - quaProb(4, samp_ith);
        end

    end

    ACKCorrectCases = settings.ACKCorrectCases;
    numACKCorrectCases = size(ACKCorrectCases, 1);
    message = 1;
    sampQuaProb = QuaProbCal(message, offset, numORS, lenType, SNR_dB, RXType);
    
    if isequal(RXType, 'BLE')
        
        results.corrQuaDecodeProb = sampQuaProb(1, 1);
        results.corrORSDecodeProb = sampQuaProb(1, 1);
        quaProb = sampQuaProb';
    else
        
        results.corrQuaDecodeProb = sampQuaProb(1, 3);
    
        meanProb = sum(sampQuaProb, 2)';
        
        varProb = diag(sampQuaProb * (1 - sampQuaProb)')';
        
        coVarProb = zeros(4, 4);
        meanProbZ = zeros(4, 4);
        varProbZ = zeros(4, 4);
        quaProb = zeros(4, 4);
        for qua_ith_1 = 1: 4
            for qua_ith_2 = 1: 4
                if qua_ith_1 ~= qua_ith_2
                    coVarProb(qua_ith_1, qua_ith_2) = -1 * sampQuaProb(qua_ith_1, :) * sampQuaProb(qua_ith_2, :)';
                    meanProbZ(qua_ith_1, qua_ith_2) = meanProb(1, qua_ith_1) - meanProb(1, qua_ith_2);
                    varProbZ(qua_ith_1, qua_ith_2) = varProb(1, qua_ith_1) + varProb(1, qua_ith_2) - 2 * coVarProb(qua_ith_1, qua_ith_2);
                    if varProbZ(qua_ith_1, qua_ith_2) < 0
                         error('Negative variance encountered. Check sampQuaProb for validity.');
                    end
                    quaProb(qua_ith_1, qua_ith_2) = 1 - normcdf(0, meanProbZ(qua_ith_1, qua_ith_2), sqrt(varProbZ(qua_ith_1, qua_ith_2)));
                else
                    quaProb(qua_ith_1, qua_ith_2) = 0;
                end
            end
        end
        
        probTmp = ones(1, 4);
        for qua_ith_1 = 1: 1: 4
            for qua_ith_2 = 1: 1: 4
                if qua_ith_1 ~= qua_ith_2
                    probTmp(1, qua_ith_1) = probTmp(1, qua_ith_1) * quaProb(qua_ith_1, qua_ith_2);
                end
            end
        end
        
        % Compensate approximation errors.
        tmp = 1 - sum(probTmp);
        quaProb = probTmp + tmp./size(probTmp, 2);
        results.corrORSDecodeProb = quaProb(1, 1);        
        
    end
    
    probTmp = 0;
    for case_ith = 1: 1: numACKCorrectCases
        probTmp = probTmp + mnpdf(ACKCorrectCases(case_ith, :), quaProb);
    end
    results.corrACKDecodeProb = probTmp;

end