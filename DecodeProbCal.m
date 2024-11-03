function results = DecodeProbCal(settings)
global signalPower_dBm;

SNR_dB = settings.SNR;
numORS = settings.numORS;
offset = settings.offset;
lenType = settings.ACKSignalLenType;
RXType = settings.RXType;
ORSNumThreshold = settings.ORSNumThreshold;

    function quaProb = QuaProbCal(message, offsetValue, numORS, lenType, SNR_dB, RXType)
        % This function calculate the probability of a sample falls into
        % each quandrant.
        % Scale noise.      
        noisePower_mW = (db2pow(signalPower_dBm - SNR_dB)) ./ 2 ./ 1000;
        
        txWaveform = PHYOQPSK_ACKfeedback(message, numORS, lenType, RXType);
        % The lower bound and uper bound of each quandrant
        % The ith element of list corresponds to the quandrant i.
        lowBoundList = [0, pi/2, -pi, -pi/2];
        upBoundList = [pi/2, pi, -pi/2, 0];
        samples = Sampling(txWaveform, offsetValue, RXType);

        if isequal(lenType, 'short')
            numSampPerORS = size(samples, 2) / (numORS + 1);
        else
            numSampPerORS = size(samples, 2) / (2 * numORS);
        end
        samples = samples(1, 1:1:numSampPerORS);
        sampleReal = real(samples);
        sampleImag = imag(samples);
        quaProb = zeros(1, size(samples, 2));
        for samp_ith = 1: 1: size(samples, 2)
            fun = @(x, y) (x./(2*pi*noisePower_mW)) .*...
                    exp(-((x.*cos(y) - sampleReal(samp_ith)).^2 + (x.*sin(y) - sampleImag(samp_ith)).^2) ./ (2.*noisePower_mW));

            quaProb(1, samp_ith) = integral2(fun, 0, Inf, lowBoundList(1, message), upBoundList(1, message));
        end

    end

% ACKCorrectCases = settings.ACKCorrectCases;
message = 4;
probTmp = QuaProbCal(message, offset, numORS, lenType, SNR_dB, RXType);

if isequal(RXType, 'BLE')
    results.corrORSDecodeProb = probTmp;
    results.corrACKDecodeProb = binocdf(round(numORS/2), numORS, results.corrORSDecodeProb, 'upper');
%     results.corrACKDecodeProb = 0;
%     for ithORS = floor(numORS/4):1:numORS
%         results.corrACKDecodeProb = results.corrACKDecodeProb + binopdf(ithORS, numORS, results.corrORSDecodeProb);
%     end
%     numACKCorrectCases = size(ACKCorrectCases, 1);
%     tmp = zeros(1, numACKCorrectCases);
%     for jth = 1:numACKCorrectCases
%         tmp(1, jth) = mnpdf(ACKCorrectCases(jth, :), probTmp);
%     end
%     results.corrACKDecodeProb = sum(tmp);
else
    % Each ORS has 16 samples.
    % In a successful ORS detection, we only need 4 of them to be correct.
    numCorrSamp = round(16/4) + 1; 
    % poissonBinomialPMF includes case where none of sample is correct.
%     probTmp = poissonBinomialPMF(probTmp);
%     results.corrORSDecodeProb = sum(probTmp(1, numCorrSamp+1:1:end), 2); 
    results.corrQuaDecodeProb = probTmp(1, 10);
    results.corrORSDecodeProb = poissonBinomialAtLeastM_fast(probTmp, numCorrSamp);
    results.corrACKDecodeProb = binocdf(ceil(numORS/3), numORS, results.corrORSDecodeProb, 'upper');
end


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

end