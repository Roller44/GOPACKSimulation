function accuracies = ACKDetectionBLE(settings)

    function powerValues = energyDetection(samples)
        % Calcualte signal power
        energyValues = abs(samples.^2);
        powerValues = sum(energyValues, 2) ./ size(samples, 2);
    end

    function phaseShiftValues = phaseShiftCal(samples, lenType)
        % Calculate phases
        [numMsg, sampleSize] = size(samples);

        if isequal(lenType, 'short')
            phaseShiftValues = zeros(numMsg, sampleSize-1);
        else
            phaseShiftValues = zeros(numMsg, sampleSize/2);
        end

        if isequal(lenType, 'short')
            for msg_ith = 1: 1: numMsg
                for phase_ith = 2: 1: sampleSize
                    phaseShiftValues(msg_ith, phase_ith-1) = angle(samples(msg_ith, phase_ith)...
                        * conj(samples(msg_ith, phase_ith-1)));
                end
            end
        else
            for msg_ith = 1: 1: numMsg
                for phase_ith = 1: 1: sampleSize/2
                    phaseShiftValues(msg_ith, phase_ith) = angle(samples(msg_ith, 2.*phase_ith)...
                        * conj(samples(msg_ith, 2.*phase_ith-1)));
                end
            end
        end
    end

    function numDetectedORS = ORSDection(phaseShiftValues, ORSThreshold)
        % ORS detection
        numDetectedORS = zeros(size(phaseShiftValues, 1), 1);
        for ORS_ith = 1: 1: size(phaseShiftValues, 1)
            numDetectedORS(ORS_ith, 1) = length(find(abs(phaseShiftValues(ORS_ith, :)) < ORSThreshold));
        end
    end

    function [decodedMsg, decodedORS] = ACKDecoding(samples, lenType)
        % Decode ACK signals based on the quadrants of their ORSs
        [numMsg, sampleSize] = size(samples);
        angles = angle(samples);
        decodedMsg = zeros(numMsg, 1);
        if isequal(lenType, 'short')
            quandrants = zeros(numMsg, sampleSize-1);
        else
            quandrants = zeros(numMsg, sampleSize/2);
        end

        if isequal(lenType, 'short')
            for msg_ith = 1: 1: numMsg
                for sam_ith = 2: 1: sampleSize
                    if (angles(msg_ith, sam_ith-1) > 0) && (angles(msg_ith ,sam_ith-1) <= (pi/2))
                        quandrants(msg_ith, sam_ith-1) = 1;
                    elseif (angles(msg_ith, sam_ith-1) > (pi/2)) && (angles(msg_ith, sam_ith-1) <= pi)
                        quandrants(msg_ith, sam_ith-1) = 2;
                    elseif (angles(msg_ith, sam_ith-1) <= 0) && (angles(msg_ith, sam_ith-1) >= -pi/2)
                        quandrants(msg_ith, sam_ith-1) = 4;
                    else
                        quandrants(msg_ith, sam_ith-1) = 3;
                    end
                end
                decodedMsg(msg_ith, 1) = mode(quandrants(msg_ith, :));
            end
        else
            for msg_ith = 1: 1: numMsg
                for sam_ith = 2: 2: sampleSize
                    tmp = samples(msg_ith, sam_ith/2);
                    if (atan2(imag(tmp), real(tmp)) > 0) && (atan2(imag(tmp), real(tmp)) <= (pi/2))
                        quandrants(msg_ith, sam_ith/2) = 1;
                    elseif (atan2(imag(tmp), real(tmp)) > (pi/2)) && (atan2(imag(tmp), real(tmp)) <= pi)
                        quandrants(msg_ith, sam_ith/2) = 2;
                    elseif (atan2(imag(tmp), real(tmp)) <= 0) && (atan2(imag(tmp), real(tmp)) >= -pi/2)
                        quandrants(msg_ith, sam_ith/2) = 4;
                    else
                        quandrants(msg_ith, sam_ith/2) = 3;
                    end
                end
                decodedMsg(msg_ith, 1) = mode(quandrants(msg_ith, :));
            end
        end
        decodedORS = quandrants;
        decodedMsg = mode(quandrants, 2);
    end

%% Starts here:
rxWaveform = settings.rxWaveform;
% plot(real(rxWaveform));
% hold on;
% plot(imag(rxWaveform));
ACKThreshold = settings.ACKThreshold;
ORSPhaseThreshold = settings.ORSPhaseThreshold;
ORSNumThreshold = settings.ORSNumThreshold;
powerThreshold = settings.powerThreshold;
trueMsg = settings.messages;
offset = settings.offset;
numORS = settings.numORS;
lenType = settings.ACKSignalLenType;

samples = Sampling(rxWaveform, offset, 'BLE');
powerValues = energyDetection(samples);
phaseShiftValues = phaseShiftCal(samples, lenType);
numDetectedORS = ORSDection(phaseShiftValues, ORSPhaseThreshold);
[decodedMsg, decodedORS] = ACKDecoding(samples, lenType);

%% Evaluation of ACK arrival detection
busyIndices = find(powerValues(:, 1) > powerThreshold)';
idleIndices = find(powerValues(:, 1) <= powerThreshold)';
numBusyDetection = size(powerValues, 1);
numCorrectBusyDetection = 0;
numMissBusyDetection = 0;
numFalseAlarmBusyDetection = 0;

accuracies.accurDetectedBusy = 0;
accuracies.falseAlarmDetectedBusy = 0;
accuracies.missDetectedBusy = 0;
if isempty(busyIndices) == 0
    numCorrectBusyDetection = numCorrectBusyDetection + size(find(trueMsg(busyIndices) ~= 5), 1);
    numFalseAlarmBusyDetection = numFalseAlarmBusyDetection + size(find(trueMsg(busyIndices) == 5), 1);
end
if isempty(idleIndices) == 0
    numCorrectBusyDetection = numCorrectBusyDetection + size(find(trueMsg(idleIndices) == 5), 1);
    numMissBusyDetection = numMissBusyDetection + size(find(trueMsg(idleIndices) ~= 5), 1);
end
accuracies.accurDetectedBusy = numCorrectBusyDetection / numBusyDetection;
accuracies.missDetectedBusy = numMissBusyDetection / size(find(trueMsg ~= 5), 1);
accuracies.falseAlarmDetectedBusy = numFalseAlarmBusyDetection / size(find(trueMsg == 5) , 1);

%% Evaluation of ORS detection
numCorrectDetectedORS = 0;
numORSdDtection = size(find(trueMsg ~= 5), 1) * numORS;
numCorrectDetectedORS = numCorrectDetectedORS + sum(numDetectedORS(find((trueMsg ~= 5) & (trueMsg ~= 6)), 1), 1);
numCorrectDetectedORS = numCorrectDetectedORS + sum(numORS - numDetectedORS(find((trueMsg ~= 5) & (trueMsg == 6)), 1), 1);
if numORSdDtection > 0
    accuracies.accurDetectedORS = numCorrectDetectedORS / numORSdDtection;
end

%% Evaluation of ACK detection
numACK = size(find(trueMsg ~= 5), 1);
numDetectedACK = size(find(numDetectedORS(find((trueMsg ~= 5) & (trueMsg ~= 6)), 1) > ACKThreshold), 1)...
    + size(find(numDetectedORS(find((trueMsg ~= 5) & (trueMsg == 6)), 1) <= ACKThreshold), 1);
accuracies.accurDetectedACK = numDetectedACK ./ numACK;

%% Evaluation of ACK decoding
isACKIndices = find(trueMsg ~= 5);
numACKMsg = size(isACKIndices, 1);

trueORS = repmat(trueMsg, 1, numORS);
numCorrDecodedORS = 0;

for jth = isACKIndices'
    numCorrDecodedORS = numCorrDecodedORS + size(find(decodedORS(jth, :) == trueORS(jth, :)), 2);
end

numCorrectACKMsg = size(find(decodedMsg(isACKIndices, :) == trueMsg(isACKIndices, :)), 1);

numQua = zeros(1, 4);
for jth = 1: 1: 4
    numQua(1, jth) = size(find(decodedORS==jth), 1);
end
accuracies.accurQua = numQua ./ (numACKMsg .* numORS);

if numACKMsg > 0
    accuracies.accurDecodedACK = numCorrectACKMsg / numACKMsg;
    accuracies.accurDecodedORS = numCorrDecodedORS ./ (numACKMsg .* numORS);
else
    accuracies.accurDecodedACK = 0;
    accuracies.accurDecodedORS = 0;
end
end