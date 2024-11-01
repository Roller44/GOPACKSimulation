function results = BusyChannelDetectProbCal(settings)

global signalPower_dBm;

powerThreshold = settings.powerThreshold;
SNR = settings.SNR;
numORS = settings.numORS;
offset = settings.offset;
lenType = settings.ACKSignalLenType;
RXType = settings.RXType;
% busyProb = settings.busyProb;
busyProb = 1;

    function samples = Sampling(rxWaveform, offset, RXType)
        % Sampling with offset
        if isequal(RXType, 'BLE')
            sampInterval = 100;
            [numMsg, signalLen] = size(rxWaveform);
            sampleSize = length((2*sampInterval+1): sampInterval :(signalLen-sampInterval));
            if offset.isRandom == 1
                offset = randi([-35,35], 1, 1) .* ones(numMsg, 1);
            else
                offset = offset.offsetValue .* ones(numMsg, 1);
            end
    
            samples = zeros(numMsg, sampleSize);
            for ith = 1: 1: numMsg
                samples(ith, :) = rxWaveform(ith, (2*sampInterval+1+offset(ith, 1)): sampInterval :(signalLen-sampInterval+offset(ith, 1)));
            end
        else
            sampInterval = 0.05; % us
            OSR = 100; % = 1us
            beta = 5; % Down-sampling factor
            % Sampling with offset
            sampInterval = OSR * sampInterval * beta;
            [numMsg, signalLen] = size(rxWaveform);
            sampStart = OSR * 1.5 + 1;
            sampEnd = signalLen - OSR * 1.5;
            sampleSize = length(sampStart:sampInterval:sampEnd);
            if offset.isRandom == 1
                offset = randi([offset.min, offset.max], numMsg, 1);
            else
                offset = offset.offsetValue .* ones(numMsg, 1);
            end
    
            samples = zeros(numMsg, sampleSize);
            for ith = 1: 1: numMsg
                samples(ith, :) = rxWaveform(ith, (sampStart+offset(ith, 1)): sampInterval :(sampEnd+offset(ith, 1)));
            end
        end
    end

    function noisePower = noisePowerCalculation(SNR)
        % SNR = signalPower_dBm - noisePower_dBm;
        noisePower = (db2pow(signalPower_dBm - SNR)) ./ 2 ./ 1000;
    end

    function missProb = missProbCalculation(offset, powerThreshold, noisePower, numORS, lenType, RXType)
        message = randi([1, 4], 1, 1);
        txWaveform = PHYOQPSK_ACKfeedback(message, numORS, lenType, RXType);
        % Scale signal.
        % dBm = dBW + 30
        scaleCoeff = sqrt(db2pow(signalPower_dBm - 30) ./ 1);
        txWaveform = txWaveform .* scaleCoeff;

        samples = Sampling(txWaveform, offset, RXType);

%         if isequal(lenType, 'short')
%             a = sqrt(sum((real(samples).^2 + imag(samples).^2), 2)) ./ sqrt(noisePower);
%             % b = sqrt((numORS + 1) .* powerThreshold) ./ sqrt(noisePower);
%             b = sqrt(size(samples, 2) .* powerThreshold) ./ sqrt(noisePower);
%             missProb = 1 - marcumq(a, b, size(samples, 2));
%         else
%             a = sqrt(sum((real(samples).^2 + imag(samples).^2), 2)) ./ sqrt(noisePower);
%             % b = sqrt(2 .* numORS .* powerThreshold) ./ sqrt(noisePower);
%             b = sqrt(size(samples, 2) .* powerThreshold) ./ sqrt(noisePower);
%             missProb = 1 - marcumq(a, b, size(samples, 2));
%         end
        a = sqrt(sum((real(samples).^2 + imag(samples).^2), 2)) ./ sqrt(noisePower);
        b = sqrt(size(samples, 2) .* powerThreshold) ./ sqrt(noisePower);
        missProb = 1 - marcumq(a, b, size(samples, 2));
    end

    function falseAlarmProb = falseAlarmProbCalculation(powerThreshold, noisePower, numORS, lenType)

        % TBD

        if isequal(lenType, 'short')
            x = ((numORS + 1) .* powerThreshold) ./ (2 .* noisePower);
            tmp = zeros(1, (numORS+1));
            k = 0: 1: numORS;
            tmp(1, :) = (1./factorial(k)) .* (x.^k);
            falseAlarmProb = exp(-x) .* sum(tmp, 2);
        else
            x = (2 .* numORS .* powerThreshold) ./ (2 .* noisePower);
            tmp = zeros(1, (2.*numORS));
            k = 0: 1: (2*numORS-1);
            tmp(1, :) = (1./factorial(k)) .* (x.^k);
            falseAlarmProb = exp(-x) .* sum(tmp, 2);
        end
    end

noisePower = noisePowerCalculation(SNR);
missProb = missProbCalculation(offset, powerThreshold, noisePower, numORS, lenType, RXType);
falseAlarmProb = falseAlarmProbCalculation(powerThreshold, noisePower, numORS, lenType);

results.missProb = missProb;
results.falseAlarmProb = falseAlarmProb;
results.succProb = busyProb .* (1 - missProb) + (1 - busyProb) .* (1 - falseAlarmProb);
% results.succProb = (1 - missProb);
end