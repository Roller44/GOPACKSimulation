function results = DecodeProbCal(settings)
global signalPower_dBm;

SNR_dB = settings.SNR;
numORS = settings.numORS;
offset = settings.offset;
lenType = settings.ACKSignalLenType;
RXType = settings.RXType;
ORSNumThreshold = settings.ORSNumThreshold;

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

    function quaProb = QuaProbCal(message, offsetValue, numORS, lenType, SNR_dB, RXType)
        txWaveform = PHYOQPSK_ACKfeedback(message, numORS, lenType, RXType);
        % Scale signal.
        % dBm = dBW + 30
        scaleCoeff = sqrt(db2pow(signalPower_dBm - 30) ./ 1);
        txWaveform = txWaveform .* scaleCoeff;
        
        noisePower_mW = (db2pow(signalPower_dBm - SNR_dB)) ./ 2 ./ 1000;

        [~, offsetSize] = size(offsetValue);

        
        % The lower bound and uper bound of each quandrant
        % The ith element of list corresponds to the quandrant i.
        lowBoundList = [0, pi/2, pi, pi*(3/2)];
        upBoundList = [pi/2, pi, pi*(3/2), 2.*pi];
        for offset_ith = 1: 1: offsetSize
            samples = Sampling(txWaveform, offsetValue(1, offset_ith), RXType);
            numSampPerORS = size(samples, 2) / (numORS + 1);
            samples = samples(1, 1:1:numSampPerORS);
            sampleReal = real(samples);
            sampleImag = imag(samples);
            
            quaProb = zeros(offsetSize, 4, size(samples, 2));

            for samp_ith = 1: 1: size(samples, 2)
                for qua_ith = 1: 1: 4
                    fun = @(x, y) (x./(2*pi*noisePower_mW)) .*...
                        exp(-((x.*cos(y) - sampleReal(samp_ith)).^2 + (x.*sin(y) - sampleImag(samp_ith)).^2) ./ (2.*noisePower_mW));
                    quaProb(offset_ith, qua_ith, samp_ith) = integral2(fun, 0, Inf, lowBoundList(1, qua_ith), upBoundList(1, qua_ith));
                end
                % Compensate deviations.
                quaProb(offset_ith, 2, samp_ith) = 1 - quaProb(offset_ith, 1, samp_ith) - quaProb(offset_ith, 3, samp_ith) - quaProb(offset_ith, 4, samp_ith);
            end
        end

%         quaProb = roundn(quaProb, -4);
    end

ACKCorrectCases = settings.ACKCorrectCases;

message = 1;
quaProb = QuaProbCal(message, offset.offsetValue, numORS, lenType, SNR_dB, RXType);
probTmp = quaProb(:, message, :);
probTmp = squeeze(probTmp);
% probTmp = poissonBinomialPMF(probTmp);
if isequal(RXType, 'BLE')
    numCorrSamp = 1;
else
    % Each ORS has 16 samples.
    % In a successful ORS detection, we only need 4 of them to be correct.
    numCorrSamp = 4; 
end
% poissonBinomialPMF includes case where none of sample is correct.
% results.corrORSDecodeProb = sum(probTmp(1, numCorrSamp+1:1:end), 2); 
results.corrORSDecodeProb = poissonBinomialAtLeastM_fast(probTmp, numCorrSamp);

results.corrACKDecodeProb = binocdf(1, numORS, results.corrORSDecodeProb, 'upper');

% numACKCorrectCases = size(ACKCorrectCases, 1);
% % offsetValue = offset.min: 1: offset.max;
% offsetValue = offset.offsetValue;
% message = 1;
% quaProb = QuaProbCal(message, offsetValue, numORS, lenType, SNR_dB, RXType);
% probTmp = 0;
% for case_ith = 1: 1: numACKCorrectCases
% %     if isnan(sum(mnpdf(ACKCorrectCases(case_ith, :), quaProb)))
% %         a = sum(quaProb, 2)
% %         b = mnpdf(ACKCorrectCases(case_ith, :), quaProb)
% %         disp('!')
% %     end
%     probTmp = probTmp + sum(mnpdf(ACKCorrectCases(case_ith, :), quaProb));
% end
% % corrACKDecodeProb = probTmp ./ (offset.max - offset.min);
% corrACKDecodeProb = probTmp;
% results.corrACKDecodeProb = corrACKDecodeProb;

results.quaProb = quaProb;
end