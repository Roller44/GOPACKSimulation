function accuracies = ACKDetectionWiFi(settings)

    function powerValues = energyDetection(samples)
        % Calcualte signal power
        energyValues = abs(samples.^2);
        powerValues = sum(energyValues, 2) ./ size(samples, 2);
    end

    function phaseShiftValues = phaseShiftCal(samples, lenType)

        % Calculate phases
        [numMsg, sampleSize] = size(samples);
        phaseShiftInterval = 16;
        if isequal(lenType, 'short')
            phaseShiftValues = zeros(numMsg, sampleSize-phaseShiftInterval);
        else
            phaseShiftValues = zeros(numMsg, sampleSize/2);
        end

        if isequal(lenType, 'short')
            for msg_ith = 1: 1: numMsg
                for phase_ith = (phaseShiftInterval+1): 1: sampleSize
                    phaseShiftValues(msg_ith, phase_ith-phaseShiftInterval) = angle(samples(msg_ith, phase_ith)...
                        * conj(samples(msg_ith, phase_ith-phaseShiftInterval)));
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

    function numDetectedORS = ORSDection(phaseShiftValues, ORSPhaseThreshold, ORSNumThreshold, numORS)
        % ORS detection
        numPhaseShiftPerORS = size(phaseShiftValues, 2) ./ numORS;
        numDetectedORS = zeros(size(phaseShiftValues, 1), 1);
        phaseShiftValues = reshape(phaseShiftValues, size(phaseShiftValues, 1), [], numPhaseShiftPerORS);
        for ACK_ith = 1: 1: size(phaseShiftValues, 1)
            for ORS_ith = 1: 1: size(phaseShiftValues, 2)
                if length(find(abs(phaseShiftValues(ACK_ith, ORS_ith, :)) < ORSPhaseThreshold)) >= ORSNumThreshold
                    numDetectedORS(ACK_ith, 1) = numDetectedORS(ACK_ith, 1) + 1;
                end
            end
        end
    end

    function [decodedMsg, decodedORS, quandrants] = ACKDecoding(samples, lenType, numORS)
        % Decode ACK signals based on the quadrants of their ORSs

        sampInterval = 0.05; % us
        phaseCalInterval = 16; % # of samples
        beta = 5; % Down-sampling factor
        sampInterval = sampInterval * phaseCalInterval * beta;
        [numMsg, sampleSize] = size(samples);
        angles = angle(samples);
        decodedORS = zeros(numMsg, numORS);
        decodedMsg = zeros(numMsg, 1);
%         if isequal(lenType, 'short')
%             quandrants = zeros(numMsg, sampleSize-1);
%         else
%             quandrants = zeros(numMsg, sampleSize-1);
%         end
        quandrants = zeros(numMsg, sampleSize);

        for msg_ith = 1: 1: numMsg
            for sam_ith = 1: 1: sampleSize
                if (angles(msg_ith, sam_ith) > 0) && (angles(msg_ith ,sam_ith) <= (pi/2))
                    quandrants(msg_ith, sam_ith) = 1;
                elseif (angles(msg_ith, sam_ith) > (pi/2)) && (angles(msg_ith, sam_ith) < pi)
                    quandrants(msg_ith, sam_ith) = 2;
                elseif (angles(msg_ith, sam_ith) <= 0) && (angles(msg_ith, sam_ith) > -pi/2)
                    quandrants(msg_ith, sam_ith) = 4;
                else
                    quandrants(msg_ith, sam_ith) = 3;
                end
            end
        end
        
        if isequal(lenType, 'short')
            
            % quandrants = [quandrants, quandrants(:, end)];
            numSampPerWave = size(quandrants, 2) ./ (numORS + 1);
            for msg_ith = 1: 1: numMsg
                for ORS_ith = 1: 1: numORS
                    quaStart = numSampPerWave * (ORS_ith - 1) + 1;
                    quaEnd = quaStart - 1 + numSampPerWave;
                    decodedORS(msg_ith, ORS_ith) = mode(quandrants(msg_ith, quaStart:1:quaEnd));
                end
            end
            
            % A wave lasting for 4us can be sampled 4us/(5*0.05us) = 16 times
            % quandrants = quandrants(:, 1:1:(end-15));
            % quandrants = reshape(quandrants, numMsg, [], size(quandrants, 2)/numORS);
        else
            % for msg_ith = 1: 1: numMsg
            %     for sam_ith = 2: 2: sampleSize
            %         tmp = samples(msg_ith, sam_ith/2);
            %         if (atan2(imag(tmp), real(tmp)) > 0) && (atan2(imag(tmp), real(tmp)) <= (pi/2))
            %             quandrants(msg_ith, sam_ith/2) = 1;
            %         elseif (atan2(imag(tmp), real(tmp)) > (pi/2)) && (atan2(imag(tmp), real(tmp)) <= pi)
            %             quandrants(msg_ith, sam_ith/2) = 2;
            %         elseif (atan2(imag(tmp), real(tmp)) <= 0) && (atan2(imag(tmp), real(tmp)) >= -pi/2)
            %             quandrants(msg_ith, sam_ith/2) = 4;
            %         else
            %             quandrants(msg_ith, sam_ith/2) = 3;
            %         end
            %     end
            %     % decodedMsg(msg_ith, 1) = mode(quandrants(msg_ith, :));
            % 
            % end
            % A wave lasting for 4us can be sampled 4us/(5*0.05us) = 16 times
            
            % quandrants = reshape(quandrants, numMsg, numORS, 2 * 16);
            % quandrants(:, :, 17:end) = [];
            % quandrants = [quandrants, quandrants(:, end)];
            numSampPerWave = size(quandrants, 2) ./ numORS;
            for msg_ith = 1: 1: numMsg
                for ORS_ith = 1: 1: numORS
                    quaStart = numSampPerWave * (ORS_ith - 1) + 1;
                    quaEnd = quaStart - 1 + numSampPerWave/2;
                    decodedORS(msg_ith, ORS_ith) = mode(quandrants(msg_ith, quaStart:1:quaEnd));
                end
            end
        end

        % decodedORS = mode(quandrants, 3);
        decodedMsg = mode(decodedORS, 2);
        
        % decodedORS = repmat(mode(quandrants, 2), 1, 3);
        % decodedMsg = mode(quandrants, 2);
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

%% Simulation part
samples = Sampling(rxWaveform, offset, 'WiFi');
powerValues = energyDetection(samples);
phaseShiftValues = phaseShiftCal(samples, lenType);
numDetectedORS = ORSDection(phaseShiftValues, ORSPhaseThreshold, ORSNumThreshold, numORS);
[decodedMsg, decodedORS, quandrants] = ACKDecoding(samples, lenType, numORS);

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

quandrants = quandrants(:, 35);
numCorrQua = size(find(quandrants == trueMsg), 1);
accuracies.accurQua = numCorrQua ./ numACKMsg;

if numACKMsg > 0
    accuracies.accurDecodedACK = numCorrectACKMsg / numACKMsg;
    accuracies.accurDecodedORS = numCorrDecodedORS ./ (numACKMsg .* numORS);
else
    accuracies.accurDecodedACK = 0;
    accuracies.accurDecodedORS = 0;
end
end