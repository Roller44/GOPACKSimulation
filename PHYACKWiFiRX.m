function [numDetected, numDecoded] = PHYACKWiFiRX(rxWaveform, sineThreshold, ACKMessage, offset)

% function detectMsg = WiFiRX(rxWaveform)

[row, ~] = size(rxWaveform);
% For debugging.
% subplot(2, 1, 1);
% plot(real(rxWaveform));
% subplot(2, 1, 2);
% plot(imag(rxWaveform));

rxWaveform = reshape(rxWaveform, 1, row);
sampleInterval = 5;
samples = rxWaveform(1, 101+offset: sampleInterval: end-100+offset); % sample the waveform
sampleSize = length(samples);

phaseShift = zeros(1, sampleSize-16);
for ith = 1: 1: (sampleSize-16)
   phaseShift(1, ith) = angle(samples(1,ith) * conj(samples(1,ith+16))); 
end

numDetected = 0;
detectMsg = zeros(1, length(ACKMessage));
jth = 1;
for ith = 1: 634: length(phaseShift)-633
    if length(find(phaseShift(1, ith:ith+633) >= 0)) > 634-sineThreshold
        numDetected = numDetected + 1;
        detectMsg(1, jth) = 1;
%     else
    elseif length(find(phaseShift(1, ith:ith+633) < 0)) > 634-sineThreshold
        numDetected = numDetected + 1;
        detectMsg(1, jth) = 0;
    end
    jth = jth + 1;
end

% figure;
% stem(phaseShift(1: end));

% decode_accur = length(find(detectMsg==ACKMessage))/length(ACKMessage);
% detect_accur = numDetected / length(ACKMessage);
numDecoded = length(find(detectMsg==ACKMessage));