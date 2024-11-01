function [detect_accur, decode_accur] = SymBeeWiFiRX(rxWaveform, sineThreshold, ACKMessage, offset)

% function detectMsg = WiFiRX(rxWaveform)

[row, ~] = size(rxWaveform);
% % For debugging.
% subplot(2, 1, 1);
% plot(real(rxWaveform));
% subplot(2, 1, 2);
% plot(imag(rxWaveform));

rxWaveform = reshape(rxWaveform, 1, row);
sampleInterval = 5;
samples = rxWaveform(1, 101+offset: sampleInterval: end-100+offset); % sample the waveform
sampleSize = length(samples);

phaseShift = zeros(1, sampleSize-1);
for ith = 17: 1: sampleSize
   phaseShift(1, ith-16) = angle(samples(1,ith) * conj(samples(1,ith-16))); 
end

numDetectedMsg = 0;
slideWinSize = 84;
detectInterval = 640;
detectStart = 271;

jth = 1;
detectMsg = zeros(1, length(ACKMessage));
for ith = detectStart: detectInterval: (length(phaseShift)-slideWinSize)
    if length(find(phaseShift(1, ith:ith+slideWinSize)<0)) > slideWinSize-sineThreshold
        numDetectedMsg = numDetectedMsg + 1;
        detectMsg(1, jth) = 0;
    elseif length(find(phaseShift(1, ith:ith+slideWinSize)>=0)) > slideWinSize-sineThreshold
        numDetectedMsg = numDetectedMsg + 1;
        detectMsg(1, jth) = 1;
    end
    jth = jth + 1;
end

decode_accur = length(find(detectMsg==ACKMessage))/length(ACKMessage);
detect_accur = numDetectedMsg / length(ACKMessage);
end