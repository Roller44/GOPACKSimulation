clear all;
%% Assume the ZigBee TX power is 10dBm.
global signalPower_dBm;
signalPower_dBm = 10;
clc
maxTimes = 2000;
detectAccur = zeros();
decodeAccur = zeros();

% ACK_Threshold = 10;
% ORS_Threshold = 0.5;
% ith = 1;
% for SNR = 0: 5: 20
%    disp(['Runing GOP-ACK for the case where SNR=', num2str(SNR)]);
%    messages = randi([1, 2], 1, maxTimes);
%    txWaveform = PHYOQPSK_ACKfeedback(messages);
%    rxWaveform = awgn(txWaveform, SNR, 'measured');
%    offset = randi([-49, 49], 1, 1);
%    [detectAccur(ith, 1), decodeAccur(ith, 1)] = AckDetection(rxWaveform, ACK_Threshold, ORS_Threshold, messages, offset);
%    ith = ith + 1;
% end
% 
% sineThreshold = 10;
% ith = 1;
% for SNR = 0: 5: 20
%    disp(['Runing Symbol-level ACK for the case where SNR=', num2str(SNR)]);
%    ACKmessage = randi([0, 1], 1, maxTimes);
%    txWaveform = SymBeeTX(ACKmessage);
%    rxWaveform = awgn(txWaveform, SNR, 'measured');
%    offset = randi([-49, 49], 1, 1);
%    [detectAccur(ith, 2), decodeAccur(ith, 2)] = SymBeeWiFiRX(rxWaveform, sineThreshold, ACKmessage, offset);
%    ith = ith + 1;
% end
% 
% sineThreshold = 85;
% ith = 1;
% sumNumDetected = 0;
% sumNumDecoded = 0;
% for SNR = 0: 5: 20
%    disp(['Runing Bit-level ACK for the case where SNR=', num2str(SNR)]);
%    for jth = 1: 1: maxTimes
%        ACKmessage = randi([0, 1], 1, 1);
%        txWaveform = PHYACKTX(ACKmessage);
%        rxWaveform = awgn(txWaveform, SNR, 'measured');
%        offset = randi([-49, 49], 1, 1);
%        [numDetected, numDecoded] = PHYACKWiFiRX(rxWaveform, sineThreshold, ACKmessage, offset);
%        sumNumDetected = sumNumDetected + numDetected;
%        sumNumDecoded = sumNumDecoded + numDecoded;
%    end
%    detectAccur(ith, 3) = sumNumDetected / maxTimes;
%    decodeAccur(ith, 3) = sumNumDecoded / maxTimes;
%    sumNumDetected = 0;
%    sumNumDecoded = 0;
%    ith = ith + 1;
% end
% 
% SNR = 0: 5: 20;
% bar(detectAccur);
% xticklabels({'0dB', '5dB', '10dB', '15dB', '20dB'});
% xlabel('SNR');
% ylabel('Successful detection ratio.');
% legend('GOP-ACK for ZigBee-to-WiFi feedback', 'Symbol-level ACK for ZigBee-to-WiFi feedback', 'Bit-level ACK for ZigBee-to-WiFi feedback', 'location', 'west');
% axis([1-0.5, length(SNR)+0.5, 0, 1]);
% figure;
% bar(decodeAccur);
% xticklabels({'0dB', '5dB', '10dB', '15dB', '20dB'});
% xlabel('SNR');
% ylabel('Successful decoding ratio.');
% legend('GOP-ACK for ZigBee-to-WiFi feedback', 'Symbol-level ACK for ZigBee-to-WiFi feedback', 'Bit-level ACK for ZigBee-to-WiFi feedback', 'location', 'northeast');
% axis([1-0.5, length(SNR)+0.5, 0, 1]);

detectAccur = zeros();
decodeAccur = zeros();
offset = [-45 -35 -25 -15 15 25 35 45];
offset = -45: 5: 45;
SNR = 5;

settings.ACKThreshold = 10;
settings.ORSThreshold = 0.7;
settings.ACKThreshold = 8;
settings.ORSThreshold = 1;
settings.powerThreshold = 0.013;
settings.offset.isRandom = 0;
alpha = 4;
settings.numORS = 15;
settings.ACKSignalLenType = 'short';
for ith = 1: 1: length(offset)
   disp(['Runing GOP-ACK for the case where offset=', num2str(offset(1, ith))]);
   settings.messages = randi([1, 2], maxTimes, 1);
   txWaveform = PHYOQPSK_ACKfeedback(settings.messages, settings.numORS*alpha, settings.ACKSignalLenType);
   % settings.rxWaveform = awgn(txWaveform, SNR, 'measured');
   settings.rxWaveform = AddNoise(SNR, txWaveform);
   settings.offset.offsetValue = offset(1, ith);
   accuracies = ACKDetectionWiFi(settings);
   detectAccur(ith, 1) = accuracies.accurDetectedACK;
end

sineThreshold = 10;
for ith = 1: 1: length(offset)
   disp(['Runing Symbol-level ACK for the case where offset=', num2str(offset(1, ith))]);
   ACKmessage = randi([0, 1], 1, maxTimes);
   txWaveform = SymBeeTX(ACKmessage);
   rxWaveform = awgn(txWaveform, SNR, 'measured');
   [detectAccur(ith, 2), decodeAccur(ith, 2)] = SymBeeWiFiRX(rxWaveform, sineThreshold, ACKmessage, offset(1, ith));
end


sineThreshold = 95;
sumNumDetected = 0;
sumNumDecoded = 0;
for ith = 1: 1: length(offset)
   disp(['Runing Bit-level ACK for the case where offset=', num2str(offset(1, ith))]);
   for jth = 1: 1: maxTimes
       ACKmessage = randi([0, 1], 1, 1);
       txWaveform = PHYACKTX(ACKmessage);
       rxWaveform = awgn(txWaveform, SNR, 'measured');
       [numDetected, numDecoded] = PHYACKWiFiRX(rxWaveform, sineThreshold, ACKmessage, offset(1, ith));
       sumNumDetected = sumNumDetected + numDetected;
       sumNumDecoded = sumNumDecoded + numDecoded;
   end
   detectAccur(ith, 3) = sumNumDetected / maxTimes;
   decodeAccur(ith, 3) = sumNumDecoded / maxTimes; 
   sumNumDetected = 0;
   sumNumDecoded = 0;
end

figure;
bar(detectAccur);
xticklabels({'-0.45\mus', '-0.35\mus', '-0.25\mus', '-0.15\mus', '0.15\mus', '0.25\mus', '0.35\mus', '0.45\mus'});
xlabel('Sampling offset \it{\Deltat}','Interpreter','Latex');
ylabel('Successful detection ratio','Interpreter','Latex');
legend('GOP-ACK for ZigBee-to-WiFi feedback', 'Symbol-level ACK for ZigBee-to-WiFi feedback', 'Bit-level ACK for ZigBee-to-WiFi feedback', 'location', 'best', 'Interpreter','Latex');
axis([1-0.5, length(offset)+0.5, 0, 1]);
figure;
bar(decodeAccur);
xticklabels({'-0.45\mus', '-0.35\mus', '-0.25\mus', '-0.15\mus', '0.15\mus', '0.25\mus', '0.35\mus', '0.45\mus'});
xlabel('Sampling offset \it{\Deltat}');
ylabel('Successful decoding ratio');
legend('GOP-ACK for ZigBee-to-WiFi feedback', 'Symbol-level ACK for ZigBee-to-WiFi feedback', 'Bit-level ACK for ZigBee-to-WiFi feedback', 'location', 'best', 'Interpreter','Latex');
axis([1-0.5, length(offset)+0.5, 0, 1]);

detectAccur = detectAccur';
figure;
plot(offset, detectAccur(1, :), 'r-o');
hold on;
plot(offset, detectAccur(2, :), 'b--+');
hold on;
plot(offset, detectAccur(3, :), 'k-.^');
hold on;
% xticklabels({'-0.45\mus', '-0.35\mus', '-0.25\mus', '-0.15\mus', '0.15\mus', '0.25\mus', '0.35\mus', '0.45\mus'});
xlabel('Sampling offset $\Delta t$','Interpreter','Latex');
ylabel('Successful ACK detection ratio','Interpreter','Latex');
legend('GOP-ACK for ZigBee-to-WiFi feedback', 'Symbol-level ACK for ZigBee-to-WiFi feedback', 'Bit-level ACK for ZigBee-to-WiFi feedback', 'location', 'best', 'Interpreter','Latex');
axis([min(offset), max(offset), 0, 1]);
