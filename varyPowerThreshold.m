clear all;
clc;
%% Assume the ZigBee TX power is 10dBm.
global signalPower_dBm;
signalPower_dBm = 10;
%% Parameter setting
settingsSim.ACKThreshold = 10;
settingsSim.ORSThreshold = 1;
settingsSim.offset.isRandom = 0;
settingsSim.offset.offsetValue = 25;
settingsSim.offset.max = 50;
settingsSim.offset.min = -50;
settingsSim.numORS = 15;

settingsAna.numORS = settingsSim.numORS;
settingsAna.offset = settingsSim.offset;
settingsAna.ACKCorrectCases = ACKCorrectList(settingsSim.numORS);

maxTimes = 5000;
powerThresholdStepSim = 0.001: 0.002: 0.04;
powerThresholdStepAna = 0.001: 0.0001: 0.04;
SNR_Step = 0: 5: 15;

busyDetectAccur = zeros(length(powerThresholdStepSim), length(SNR_Step));
busyDetectAccurMiss = zeros(length(powerThresholdStepSim), length(SNR_Step));
busyDetectAccurFalse = zeros(length(powerThresholdStepSim), length(SNR_Step));
% orsDetectAccur = zeros(length(powerThresholdStepSim), length(SNR_Step));
% ackDetectAccur = zeros(length(powerThresholdStepSim), length(SNR_Step));
% decodeAccur = zeros(length(powerThresholdStepSim), length(SNR_Step));

busyDetectProb = zeros(length(powerThresholdStepSim), length(SNR_Step));
busyDetectProbMiss = zeros(length(powerThresholdStepSim), length(SNR_Step));
busyDetectProbFalse = zeros(length(powerThresholdStepSim), length(SNR_Step));

%% Run simulator and model calculator
disp('++++++++++++++++++++++++Simulation++++++++++++++++++++++++')
ith = 1;
busyProb = 1;
notACKProb = 0;
for powerThreshold = powerThresholdStepSim
    jth = 1;
    for SNR = SNR_Step
        disp(['Runing for the case where Power Threshold = ', num2str(powerThreshold),' and SNR = ',num2str(SNR),'.']);
        % 50% chance a ACK signal is transmitted. The type of each ACK
        % signal is uniformly distributed.
        messages = unifrnd(0, 1, maxTimes, 1);
        messages(find(messages > busyProb), 1) = 5;
        messages(find(messages < busyProb*notACKProb), 1) = 6;
        messages(find((messages >= busyProb*notACKProb) & (messages < busyProb)), 1) = randi([1, 4], length(find((messages >= busyProb*notACKProb) & (messages < busyProb))), 1);
        settingsSim.messages = messages;
        settingsSim.ACKSignalLenType = 'short';
        txWaveform = PHYOQPSK_ACKfeedback(settingsSim.messages, settingsSim.numORS, settingsSim.ACKSignalLenType);
        settingsSim.rxWaveform = AddNoise(SNR, txWaveform);
        settingsSim.powerThreshold = powerThreshold;
        accuracies = AckDetection(settingsSim);
        busyDetectAccur(ith, jth) = accuracies.accurDetectedBusy;
        orsDetectAccur(ith, jth) = accuracies.accurDetectedORS;
        ackDetectAccur(ith, jth) = accuracies.accurDetectedACK;
        decodeAccur(ith, jth) = accuracies.accurDecodedACK;

        busyDetectAccur(ith, jth) = accuracies.accurDetectedBusy;
        busyDetectAccurMiss(ith, jth) = accuracies.missDetectedBusy;
        busyDetectAccurFalse(ith, jth) = accuracies.falseAlarmDetectedBusy;

        jth = jth + 1;
    end
    ith = ith + 1;
end

disp('++++++++++++++++++++++++Model++++++++++++++++++++++++')
settingsAna.busyProb = busyProb;
settingsAna.notACKProb = notACKProb;
ith = 1;
for powerThreshold = powerThresholdStepAna
    jth = 1;
    for SNR = SNR_Step
        settingsAna.powerThreshold = powerThreshold;
        settingsAna.SNR = SNR;
        settingsAna.ACKSignalLenType = 'short';
        results = BusyChannelDetectProbCal(settingsAna);
        busyDetectProb(ith, jth) = results.succProb;
        busyDetectProbMiss(ith, jth) = results.missProb;
        busyDetectProbFalse(ith, jth) = results.falseAlarmProb;

        jth = jth + 1;
    end
    ith = ith + 1;
end

%% Plot successful ACK arraival detection ratio various power threshold.
figure;
plot(powerThresholdStepSim, busyDetectAccur(:, 1), 'ro');
hold on;
plot(powerThresholdStepSim, busyDetectAccur(:, 2), 'b*');
hold on;
plot(powerThresholdStepSim, busyDetectAccur(:, 3), 'kv');
hold on;
plot(powerThresholdStepSim, busyDetectAccur(:, 4), 'm^');
hold on;

plot(powerThresholdStepAna, busyDetectProb(:, 1), 'r-');
hold on;
plot(powerThresholdStepAna, busyDetectProb(:, 2), 'b--');
hold on;
plot(powerThresholdStepAna, busyDetectProb(:, 3), 'k-.');
hold on;
plot(powerThresholdStepAna, busyDetectProb(:, 4), 'm:');
hold on;

axis([min(powerThresholdStepSim), max(powerThresholdStepSim), 0, 1]);
xlabel('Busy channel threshold $$\hat{\lambda}_{th}$$', 'Interpreter', 'latex');
ylabel('Successful ACK arrival detection ratio', 'Interpreter','Latex');
legend({'Sim: SNR=0dB', 'Sim: SNR=5dB', 'Sim: SNR=10dB', 'Sim: SNR=15dB',...
    'Ana: SNR=0dB', 'Ana: SNR=5dB', 'Ana: SNR=10dB', 'Ana: SNR=15dB'},...
    'location', 'best', 'Interpreter','Latex', 'FontSize', 5);

figure;
plot(powerThresholdStepSim, busyDetectAccurMiss(:, 1), 'ro');
hold on;
plot(powerThresholdStepSim, busyDetectAccurMiss(:, 2), 'b*');
hold on;
plot(powerThresholdStepSim, busyDetectAccurMiss(:, 3), 'kv');
hold on;
plot(powerThresholdStepSim, busyDetectAccurMiss(:, 4), 'm^');
hold on;

plot(powerThresholdStepAna, busyDetectProbMiss(:, 1), 'r-');
hold on;
plot(powerThresholdStepAna, busyDetectProbMiss(:, 2), 'b--');
hold on;
plot(powerThresholdStepAna, busyDetectProbMiss(:, 3), 'k-.');
hold on;
plot(powerThresholdStepAna, busyDetectProbMiss(:, 4), 'm:');
hold on;
axis([min(powerThresholdStepSim), max(powerThresholdStepSim), 0, 1]);
xlabel('Busy channel threshold $$\hat{\lambda}_{th}$$', 'Interpreter', 'latex');
ylabel('Miss probability', 'Interpreter','Latex');
legend({'Sim: SNR=0dB', 'Sim: SNR=5dB', 'Sim: SNR=10dB', 'Sim: SNR=15dB',...
    'Ana: SNR=0dB', 'Ana: SNR=5dB', 'Ana: SNR=10dB', 'Ana: SNR=15dB'},...
    'location', 'best', 'Interpreter','Latex', 'FontSize', 5);

figure;
plot(powerThresholdStepSim, busyDetectAccurFalse(:, 1), 'ro');
hold on;
plot(powerThresholdStepSim, busyDetectAccurFalse(:, 2), 'b*');
hold on;
plot(powerThresholdStepSim, busyDetectAccurFalse(:, 3), 'kv');
hold on;
plot(powerThresholdStepSim, busyDetectAccurFalse(:, 4), 'm^');
hold on;

plot(powerThresholdStepAna, busyDetectProbFalse(:, 1), 'r-');
hold on;
plot(powerThresholdStepAna, busyDetectProbFalse(:, 2), 'b--');
hold on;
plot(powerThresholdStepAna, busyDetectProbFalse(:, 3), 'k-.');
hold on;
plot(powerThresholdStepAna, busyDetectProbFalse(:, 4), 'm:');
hold on;
axis([min(powerThresholdStepSim), max(powerThresholdStepSim), 0, 1]);
xlabel('Busy channel threshold $$\hat{\lambda}_{th}$$', 'Interpreter', 'latex');
ylabel('False alarm probability', 'Interpreter','Latex');
legend({'Sim: SNR=0dB', 'Sim: SNR=5dB', 'Sim: SNR=10dB', 'Sim: SNR=15dB',...
    'Ana: SNR=0dB', 'Ana: SNR=5dB', 'Ana: SNR=10dB', 'Ana: SNR=15dB'},...
    'location', 'best', 'Interpreter','Latex', 'FontSize', 5);


