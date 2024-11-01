clear all;
clc;
%% Assume the ZigBee TX power is 10dBm.
global signalPower_dBm;
signalPower_dBm = 10;

%% parameter
maxTimes = 5000;
offsetSim = [-50, -45, -35, -25, -15, -5, 5, 15, 25, 35, 45, 50];
offsetAna = -50: 1: 50;

settingsSim.ACKThreshold = 4;
settingsSim.ORSThreshold = 1;
settingsSim.powerThreshold = 0.009;
settingsSim.offset.isRandom = 0;
settingsSim.offset.max = 50;
settingsSim.offset.min = -50;
settingsSim.numORS = 15;
SNR = 0;

busyDetectAccur = zeros(2, length(offsetSim));
busyDetectMiss = zeros(2, length(offsetSim));
busyDetectFalseAlarm = zeros(2, length(offsetSim));
ORSDetectAccur = zeros(2, length(offsetSim));
ACKSignalDetectAccur = zeros(2, length(offsetSim));
ORSDecodeAccur = zeros(2, length(offsetSim));
ACKDecodeAccur = zeros(2, length(offsetSim));

for ith = 1: 1: length(offsetSim)
    disp(['Runing simulation for the case where offset = ', num2str(offsetSim(1, ith)/100),'us and SNR = ',num2str(SNR),'.']);
    % 50% chance a ACK signal is transmitted. The type of each ACK
    % signal is uniformly distributed.
    messages = unifrnd(0, 1, maxTimes, 1);
    messages(find(messages>0.5), 1) = randi([1, 4], length(find(messages>0.5)), 1);
    messages(find(messages<=0.5), 1) = 5;
    settingsSim.messages = messages;

    settingsSim.ACKSignalLenType = 'short';
    txWaveform = PHYOQPSK_ACKfeedback(settingsSim.messages, settingsSim.numORS, settingsSim.ACKSignalLenType);
    settingsSim.rxWaveform = AddNoise(SNR, txWaveform);
    settingsSim.offset.offsetValue = offsetSim(1, ith);
    accuracies = ACKDetectionBLE(settingsSim);
    busyDetectAccur(1, ith) = accuracies.accurDetectedBusy;
    busyDetectMiss(1, ith) = accuracies.missDetectedBusy;
    busyDetectFalseAlarm(1, ith) = accuracies.falseAlarmDetectedBusy;
    ORSDetectAccur(1, ith) = accuracies.accurDetectedORS;
    ACKSignalDetectAccur(1, ith) = accuracies.accurDetectedACK;
    ORSDecodeAccur(1, ith) = accuracies.accurDecodedORS;
    ACKDecodeAccur(1, ith) = accuracies.accurDecodedACK;

    settingsSim.ACKSignalLenType = 'long';
    txWaveform = PHYOQPSK_ACKfeedback(settingsSim.messages, settingsSim.numORS, settingsSim.ACKSignalLenType);
    settingsSim.rxWaveform = AddNoise(SNR, txWaveform);
    settingsSim.offset.offsetValue = offsetSim(1, ith);
    accuracies = ACKDetectionBLE(settingsSim);
    busyDetectAccur(2, ith) = accuracies.accurDetectedBusy;
    busyDetectMiss(2, ith) = accuracies.missDetectedBusy;
    busyDetectFalseAlarm(2, ith) = accuracies.falseAlarmDetectedBusy;
    ORSDetectAccur(2, ith) = accuracies.accurDetectedORS;
    ACKSignalDetectAccur(2, ith) = accuracies.accurDetectedACK;
    ORSDecodeAccur(2, ith) = accuracies.accurDecodedORS;
    ACKDecodeAccur(2, ith) = accuracies.accurDecodedACK;
end

settingsAna = settingsSim;
settingsAna.ACKCorrectCases = ACKCorrectList(settingsSim.numORS);

busyDetectProb = zeros(2, length(offsetAna));
busyDetectProbMiss = zeros(2, length(offsetAna));
busyDetectProbFalseAlarm = zeros(2, length(offsetAna));
ORSDetectProb = zeros(2, length(offsetAna));
ORSDecodeProb = zeros(2, length(offsetAna));
ACKSignalDetectProb = zeros(2, length(offsetAna));
ACKDecodeProb = zeros(2, length(offsetAna));

for ith = 1: 1: length(offsetAna)
    disp(['Runing model for the case where offset = ', num2str(offsetAna(1, ith)/100),'us and SNR = ',num2str(SNR),'.']);
    settingsAna.SNR = SNR;

    settingsAna.ACKSignalLenType = 'short';
    settingsAna.offset.offsetValue = offsetAna(1, ith);
    results = BusyChannelDetectProbCal(settingsAna);
    busyDetectProb(1, ith) = results.succProb;
    busyDetectProbMiss(1, ith) = results.missProb;
    busyDetectProbFalseAlarm(1, ith) = results.falseAlarmProb;
    results = ACKDetectProbCal(settingsAna);
    ORSDetectProb(1, ith) = results.succORSProb;
    ACKSignalDetectProb(1, ith) = results.succACKProb;
    results = DecodeProbCal(settingsAna);
    ORSDecodeProb(1, ith) = results.corrORSDecodeProb;
    ACKDecodeProb(1, ith) = results.corrACKDecodeProb;

    settingsAna.ACKSignalLenType = 'long';
    settingsAna.offset.offsetValue = offsetAna(1, ith);
    results = BusyChannelDetectProbCal(settingsAna);
    busyDetectProb(2, ith) = results.succProb;
    busyDetectProbMiss(2, ith) = results.missProb;
    busyDetectProbFalseAlarm(2, ith) = results.falseAlarmProb;
    results = ACKDetectProbCal(settingsAna);
    ORSDetectProb(2, ith) = results.succORSProb;
    ACKSignalDetectProb(2, ith) = results.succACKProb;
    results = DecodeProbCal(settingsAna);
    ORSDecodeProb(2, ith) = results.corrORSDecodeProb;
    ACKDecodeProb(2, ith) = results.corrACKDecodeProb;
end

offsetSim = offsetSim / 100;
offsetAna = offsetAna / 100;
%% Plot successful busy channel detection probability verious offset
figure;
plot(offsetSim, busyDetectAccur(1, :), 'ro');
hold on;
plot(offsetAna, busyDetectProb(1, :), 'r-');
hold on;

plot(offsetSim, busyDetectAccur(2, :), 'bs');
hold on;
plot(offsetAna, busyDetectProb(2, :), 'b-.');
hold on;
axis([min(offsetSim), max(offsetSim), 0, 1]);
xlabel('Sampling offset $$\Delta t$$', 'Interpreter', 'latex');
ylabel({'Successful busy channel'; 'detection probability $$P_{b}^{s}(\Delta t)$$'},...
    'Interpreter','Latex');
legend({'Short ACK sim', 'Short ACK ana', 'Long ACK sim:','Long ACK ana'},...
    'location', 'best', 'Interpreter','Latex', 'FontSize', 5);

%% Plot miss detection probability in busy channel detection verious offset
figure;
plot(offsetSim, busyDetectMiss(1, :), 'ro');
hold on;
plot(offsetAna, busyDetectProbMiss(1, :), 'r-');
hold on;

plot(offsetSim, busyDetectMiss(2, :), 'bs');
hold on;
plot(offsetAna, busyDetectProbMiss(2, :), 'b-.');
hold on;
axis([min(offsetSim), max(offsetSim), 0, 1]);
xlabel('Sampling offset $$\Delta t$$ ($$\mu s$$)', 'Interpreter', 'latex');
ylabel({'Miss probability $$P_{b}^{m}(\Delta t)$$'; 'of busy channel detection'},...
    'Interpreter','Latex');
legend({'Short ACK sim', 'Short ACK ana', 'Long ACK sim:','Long ACK ana'},...
    'location', 'best', 'Interpreter','Latex', 'FontSize', 5);

%% Plot false alarm probability in busy channel detection versus offset
figure;
plot(offsetSim, busyDetectFalseAlarm(1, :), 'ro');
hold on;
plot(offsetAna, busyDetectProbFalseAlarm(1, :), 'r-');
hold on;

plot(offsetSim, busyDetectFalseAlarm(2, :), 'bs');
hold on;
plot(offsetAna, busyDetectProbFalseAlarm(2, :), 'b-.');
hold on;

axis([min(offsetSim), max(offsetSim), 0, 1]);
xlabel('Sampling offset $$\Delta t$$ ($$\mu s$$)', 'Interpreter', 'latex');
ylabel({'False alarm probability $$P_{b}^{f}(\Delta t)$$';'of busy channel detection'},...
    'Interpreter','Latex');
legend({'Short ACK sim', 'Short ACK ana', 'Long ACK sim:','Long ACK ana'},...
    'location', 'best', 'Interpreter','Latex', 'FontSize', 5);

%% Plot successful ORS detection probability versus offset
figure;
plot(offsetSim, ORSDetectAccur(1, :), 'ro');
hold on;
plot(offsetAna, ORSDetectProb(1, :), 'r-');
hold on;

plot(offsetSim, ORSDetectAccur(2, :), 'bs');
hold on;
plot(offsetAna, ORSDetectProb(2, :), 'b-.');
hold on;

axis([min(offsetSim), max(offsetSim), 0, 1]);
xlabel('Sampling offset $$\Delta t$$ ($$\mu s$$)', 'Interpreter', 'latex');
ylabel({'Successful ORS detection';' probability  $$P_{o}^{s}$$'}, 'Interpreter','Latex')
axis([min(offsetSim), max(offsetSim), 0, 1]);
legend({'Short ACK sim', 'Short ACK ana', 'Long ACK sim:','Long ACK ana'},...
    'location', 'best', 'Interpreter','Latex', 'FontSize', 5);

%% Plot correct ORS type detection probability versus offset
figure;
plot(offsetSim, ORSDecodeAccur(1, :), 'ro');
hold on;
plot(offsetAna, ORSDecodeProb(1, :), 'r-');
hold on;

plot(offsetSim, ORSDecodeAccur(2, :), 'bs');
hold on;
plot(offsetAna, ORSDecodeProb(2, :), 'b-.');
hold on;

axis([min(offsetSim), max(offsetSim), 0, 1]);
xlabel('Sampling offset $$\Delta t$$ ($$\mu s$$)', 'Interpreter', 'latex');
ylabel({'Correct ORS type detection'; 'probability $$P_{o}^{c}(\delta t)$$'}, 'Interpreter','Latex')
axis([min(offsetSim), max(offsetSim), 0, 1]);
legend({'Short ACK sim', 'Short ACK ana', 'Long ACK sim:','Long ACK ana'},...
    'location', 'best', 'Interpreter','Latex', 'FontSize', 5);

%% Plot successful ACK detection probability versus offset
figure;
plot(offsetSim, ACKSignalDetectAccur(1, :), 'ro');
hold on;
plot(offsetAna, ACKSignalDetectProb(1, :), 'r-');
hold on;

plot(offsetSim, ACKSignalDetectAccur(2, :), 'bs');
hold on;
plot(offsetAna, ACKSignalDetectProb(2, :), 'b-.');
hold on;

axis([min(offsetSim), max(offsetSim), 0, 1]);
xlabel('Sampling offset $$\Delta t$$ ($$\mu s$$)', 'Interpreter', 'latex');
ylabel({'Successful ACK signal detection'; 'probability $$P_{s}^{s}(\Delta t)$$'},...
    'Interpreter','Latex')
legend({'Short ACK sim', 'Short ACK ana', 'Long ACK sim:','Long ACK ana'},...
    'location', 'best', 'Interpreter','Latex', 'FontSize', 5);

%% Plot correct ACK decoding probability versus offset
figure;
plot(offsetSim, ACKDecodeAccur(1, :), 'ro');
hold on;
plot(offsetAna, ACKDecodeProb(1, :), 'r-');
hold on;

plot(offsetSim, ACKDecodeAccur(2, :), 'bs');
hold on;
plot(offsetAna, ACKDecodeProb(2, :), 'b-.');
hold on;

axis([min(offsetSim), max(offsetSim), 0, 1]);
xlabel('Sampling offset $$\Delta t$$ ($$\mu s$$)', 'Interpreter', 'latex');
ylabel('Correct ACK decoding probability $$P_{c}$$', 'Interpreter','Latex')
legend({'Short ACK sim', 'Short ACK ana', 'Long ACK sim:','Long ACK ana'},...
    'location', 'best', 'Interpreter','Latex', 'FontSize', 5);