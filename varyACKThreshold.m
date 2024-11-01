clear all;
clc;
%% Assume the ZigBee TX power is 10dBm.
global signalPower_dBm;
signalPower_dBm = 10;

%% parameter
settingsSim.ORSThreshold = 1;
settingsSim.powerThreshold = 0.011;
settingsSim.offset.isRandom = 0;
settingsSim.offset.offsetValue = 25;
settingsSim.offset.max = 50;
settingsSim.offset.min = -50;
settingsSim.numORS = 15;

settingsAna = settingsSim;
settingsAna.numORS = settingsSim.numORS;
settingsAna.ORSThreshold = settingsSim.ORSThreshold;
settingsAna.offset = settingsSim.offset;
settingsAna.ACKCorrectCases = ACKCorrectList(settingsSim.numORS);

maxTimes = 1000;
ACK_Threshold_Step = 1: 1: 15;
SNR_Step = -5: 5: 10;

ackDetectAccur = zeros(length(ACK_Threshold_Step), length(SNR_Step));

ackDetectProb = zeros(length(ACK_Threshold_Step), length(SNR_Step));


busyProb = 0.5;
notACKProb = 0.2;
ith = 1;
for ACKThreshold = ACK_Threshold_Step
    jth = 1;
    for SNR = SNR_Step
        disp(['Runing for the case where ACK_threshold = ', num2str(ACKThreshold),' and SNR = ',num2str(SNR),'.']);
        % 50% chance a ACK signal is transmitted. The type of each ACK
        % signal is uniformly distributed.
        messages = unifrnd(0, 1, maxTimes, 1);
        messages(find(messages > busyProb), 1) = 5;
        messages(find(messages < busyProb*notACKProb), 1) = 6;
        messages(find((messages >= busyProb*notACKProb) & (messages < busyProb)), 1) =...
         randi([1, 4], length(find((messages >= busyProb*notACKProb) & (messages < busyProb))), 1);
        settingsSim.messages = messages;
        settingsSim.ACKSignalLenType = 'short';
        txWaveform = PHYOQPSK_ACKfeedback(settingsSim.messages, settingsSim.numORS, settingsSim.ACKSignalLenType);
        settingsSim.rxWaveform = AddNoise(SNR, txWaveform);
        settingsSim.ACKThreshold = ACKThreshold;
        accuracies = AckDetection(settingsSim);
        ackDetectAccur(ith, jth) = accuracies.accurDetectedACK;
        jth = jth + 1;
    end
    ith = ith + 1;
end

settingsAna.busyProb = busyProb;
settingsAna.notACKProb = notACKProb;
ith = 1;
for ACKThreshold = ACK_Threshold_Step
    jth = 1;
    for SNR = SNR_Step
        settingsAna.ACKSignalLenType = 'short';
        settingsAna.ACKThreshold = ACKThreshold;
        settingsAna.SNR = SNR;
        results = ACKDetectProbCal(settingsAna);
        ackDetectProb(ith, jth) = results.succACKProb;
        jth = jth + 1;
    end
    ith = ith + 1;
end


%% Plot ACK successful detection ratio various ACK_threshold.
figure;
plot(ACK_Threshold_Step, ackDetectAccur(:, 1), 'ro');
hold on;
plot(ACK_Threshold_Step, ackDetectAccur(:, 2), 'b*');
hold on;
plot(ACK_Threshold_Step, ackDetectAccur(:, 3), 'kv');
hold on;
plot(ACK_Threshold_Step, ackDetectAccur(:, 4), 'm^');
hold on;

plot(ACK_Threshold_Step, ackDetectProb(:, 1), 'r-');
hold on;
plot(ACK_Threshold_Step, ackDetectProb(:, 2), 'b--');
hold on;
plot(ACK_Threshold_Step, ackDetectProb(:, 3), 'k-.');
hold on;
plot(ACK_Threshold_Step, ackDetectProb(:, 4), 'm:');
axis([min(ACK_Threshold_Step), max(ACK_Threshold_Step), 0, 1]);
xlabel('ACK detection threshold $$\hat{N}_{ORS}^{th}$$', 'Interpreter','Latex');
ylabel('Successful ACK detection probability', 'Interpreter','Latex');
legend({'Sim: SNR=-5dB', 'Sim: SNR=0dB', 'Sim: SNR=5dB', 'Sim: SNR=10dB',...
    'Ana: SNR=-5dB', 'Ana: SNR=0dB', 'Ana: SNR=5dB', 'Ana: SNR=10dB'},...
    'location', 'best', 'Interpreter','Latex', 'FontSize', 5);
