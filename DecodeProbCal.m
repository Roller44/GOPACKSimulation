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
        noisePower_mW = db2pow(signalPower_dBm - SNR_dB - 30) / 2;
        % An alternative approach
        % signalPower_mW = samples * samples' / length(samples);
        % SNR_linear = 10^(SNR_dB / 10);
        % noisePower_mW = signalPower_mW / SNR_linear / 2;
        

        % The lower bound and uper bound of each quandrant
        % The ith element of list corresponds to the quandrant i.
        % lowBoundList = [0, pi/2, pi, (3/2)*pi];
        % upBoundList = [pi/2, pi, (3/2)*pi, 2*pi];
        % quaProb = zeros(4, numSampPerWave);
        % for samp_ith = 1: 1: size(samples, 2)
        %     fun = @(x, y) (x./(2*pi*noisePower_mW)) .*...
        %             exp(-((x.*cos(y) - sampleReal(samp_ith)).^2 + (x.*sin(y) - sampleImag(samp_ith)).^2) ./ (2.*noisePower_mW));
        % 
        %     quaProb(1, samp_ith) = integral2(fun, 0, Inf, lowBoundList(1, message), upBoundList(1, message));
        % end

        quaProb = zeros(4, numSampPerWave);
        for samp_ith = 1: 1: size(samples, 2)
            fun = @(x, y) (1./(2*pi*noisePower_mW)) .*...
                    exp(-((x - sampleReal(samp_ith)).^2 + (y - sampleImag(samp_ith)).^2) ./ (2*noisePower_mW));
            
            quaProb(1, samp_ith) = integral2(fun, 0, Inf, 0, Inf);
            quaProb(2, samp_ith) = integral2(fun, -Inf, 0, 0, Inf);
            quaProb(3, samp_ith) = integral2(fun, -Inf, 0, -Inf, 0);
            quaProb(4, samp_ith) = 1 - quaProb(1, samp_ith) - quaProb(2, samp_ith) - quaProb(3, samp_ith);
        end

    end

ACKCorrectCases = settings.ACKCorrectCases;
message = 1;
sampQuaProb = QuaProbCal(message, offset, numORS, lenType, SNR_dB, RXType);

if isequal(RXType, 'BLE')
    results.corrQuaDecodeProb = sampQuaProb(1, 1);
    results.corrORSDecodeProb = sampQuaProb(1, 1);
    quaProb = sampQuaProb';
else
    % Each ORS has 16 samples.
    % In a successful ORS detection, we only need 4 of them to be correct.
    numCorrSamp = round(16/4); 
    results.corrQuaDecodeProb = sampQuaProb(1, 3);
    % poissonBinomialPMF includes case where none of sample is correct.
    % probTmp = poissonBinomialPMF(sampQuaProb(1, :));
    % results.corrORSDecodeProb = sum(probTmp(1, numCorrSamp+1:1:end), 2); 
    quaProb = zeros(1, 4);
    for qua_ith = 1: 1: 4
        quaProb(1, qua_ith) = poissonBinomialAtLeastM_fast(sampQuaProb(qua_ith, :), numCorrSamp);
    end
    results.corrORSDecodeProb = quaProb(1, message);
end


numACKCorrectCases = size(ACKCorrectCases, 1);
% offsetValue = offset.min: 1: offset.max;
% offsetValue = offset.offsetValue;
% message = 1;
% quaProb = QuaProbCal(message, offsetValue, numORS, lenType, SNR_dB, RXType);
probTmp = 0;
for case_ith = 1: 1: numACKCorrectCases
    probTmp = probTmp + mnpdf(ACKCorrectCases(case_ith, :), quaProb);
end
% corrACKDecodeProb = probTmp ./ (offset.max - offset.min);
corrACKDecodeProb = probTmp;
results.corrACKDecodeProb = corrACKDecodeProb;

end