clear all;
clc;
%% Assume the ZigBee TX power is 10dBm.
global signalPower_dBm;
signalPower_dBm = 10;

%% parameter
maxTimes = 5000;
offsetSim = 25;

settingsSim.ACKThreshold = 4;
settingsSim.ORSThreshold = 1;
settingsSim.powerThreshold = 0.009;
settingsSim.offset.isRandom = 0;
settingsSim.offset.max = 50;
settingsSim.offset.min = -50;
settingsSim.numORS = 15;
settingsSim.offset.isRandom = 0;
settingsSim.offset.offsetValue = 25;
SNRStepSim = 10: -1: -5;

busyDetectAccur = zeros(2, length(SNRStepSim));
busyDetectMiss = zeros(2, length(SNRStepSim));
busyDetectFalseAlarm = zeros(2, length(SNRStepSim));
ORSDetectAccur = zeros(2, length(SNRStepSim));
ACKSignalDetectAccur = zeros(2, length(SNRStepSim));
ORSDecodeAccur = zeros(2, length(SNRStepSim));

%% Fixed offset values.
jth = 1;
for SNR = SNRStepSim
    disp(['Running simulation for busyDetectAccur, busyDetectMiss, busyDetectFalseAlarm, ORSDetectAccur, ACKSignalDetectAccur, and ORSDecodeAccur' ...
        'in the case where offset = ', num2str(settingsSim.offset.offsetValue/100),'us and SNR = ',num2str(SNR),'.']);
    % 50% chance a ACK signal is transmitted. The type of each ACK
    % signal is uniformly distributed.
    messages = unifrnd(0, 1, maxTimes, 1);
    messages(find(messages>0.5), 1) = randi([1, 4], length(find(messages>0.5)), 1);
    messages(find(messages<=0.5), 1) = 5;
    settingsSim.messages = messages;

    settingsSim.ACKSignalLenType = 'short';
    txWaveform = PHYOQPSK_ACKfeedback(settingsSim.messages, settingsSim.numORS, settingsSim.ACKSignalLenType);
    settingsSim.rxWaveform = AddNoise(SNR, txWaveform);
    accuracies = ACKDetectionBLE(settingsSim);
    busyDetectAccur(1, jth) = accuracies.accurDetectedBusy;
    busyDetectMiss(1, jth) = accuracies.missDetectedBusy;
    busyDetectFalseAlarm(1, jth) = accuracies.falseAlarmDetectedBusy;
    ORSDetectAccur(1, jth) = accuracies.accurDetectedORS;
    ACKSignalDetectAccur(1, jth) = accuracies.accurDetectedACK;
    ORSDecodeAccur(1, jth) = accuracies.accurDecodedORS;

    settingsSim.ACKSignalLenType = 'long';
    txWaveform = PHYOQPSK_ACKfeedback(settingsSim.messages, settingsSim.numORS, settingsSim.ACKSignalLenType);
    settingsSim.rxWaveform = AddNoise(SNR, txWaveform);
    accuracies = ACKDetectionBLE(settingsSim);
    busyDetectAccur(2, jth) = accuracies.accurDetectedBusy;
    busyDetectMiss(2, jth) = accuracies.missDetectedBusy;
    busyDetectFalseAlarm(2, jth) = accuracies.falseAlarmDetectedBusy;
    ORSDetectAccur(2, jth) = accuracies.accurDetectedORS;
    ACKSignalDetectAccur(2, jth) = accuracies.accurDetectedACK;
    ORSDecodeAccur(2, jth) = accuracies.accurDecodedORS;
    jth = jth + 1;
end

settingsAna = settingsSim;
settingsAna.ACKCorrectCases = ACKCorrectList(settingsSim.numORS);
SNRStepAna = 10: -0.1: -5;

busyDetectProb = zeros(2, length(SNRStepAna));
busyDetectProbMiss = zeros(2, length(SNRStepAna));
busyDetectProbFalseAlarm = zeros(2, length(SNRStepAna));
ORSDetectProb = zeros(2, length(SNRStepAna));
ACKSignalDetectProb = zeros(2, length(SNRStepAna));
ORSDecodeProb = zeros(2, length(SNRStepAna));

jth = 1;
for SNR = SNRStepAna
    disp(['Running model for busyDetectProb, busyDetectProbMiss, busyDetectProbFalseAlarm, ORSDetectProb, ACKSignalDetectProb' ...
        ' in the case where offset = ', num2str(settingsAna.offset.offsetValue/100),'us and SNR = ',num2str(SNR),'.']);
    settingsAna.SNR = SNR;

    settingsAna.ACKSignalLenType = 'short';
    results = BusyChannelDetectProbCal(settingsAna);
    busyDetectProb(1, jth) = results.succProb;
    busyDetectProbMiss(1, jth) = results.missProb;
    busyDetectProbFalseAlarm(1, jth) = results.falseAlarmProb;
    results = ACKDetectProbCal(settingsAna);
    ORSDetectProb(1, jth) = results.succORSProb;
    ACKSignalDetectProb(1, jth) = results.succACKProb;
    results = DecodeProbCal(settingsAna);
    ORSDecodeProb(1, jth) = results.corrORSDecodeProb;

    settingsAna.ACKSignalLenType = 'long';
    results = BusyChannelDetectProbCal(settingsAna);
    busyDetectProb(2, jth) = results.succProb;
    busyDetectProbMiss(2, jth) = results.missProb;
    busyDetectProbFalseAlarm(2, jth) = results.falseAlarmProb;
    results = ACKDetectProbCal(settingsAna);
    ORSDetectProb(2, jth) = results.succORSProb;
    ACKSignalDetectProb(2, jth) = results.succACKProb;
    results = DecodeProbCal(settingsAna);
    ORSDecodeProb(2, jth) = results.corrORSDecodeProb;
    

    jth = jth + 1;
end

noisePowerSim = 10 - SNRStepSim + 1;
noisePowerAna = 10 - SNRStepAna + 1;

%% Plot successful busy channel detection probability verious noise power
figure;
plot(noisePowerSim, busyDetectAccur(1, :), 'ro');
hold on;
plot(noisePowerAna, busyDetectProb(1, :), 'r-');
hold on;

plot(noisePowerSim, busyDetectAccur(2, :), 'bs');
hold on;
plot(noisePowerAna, busyDetectProb(2, :), 'b-.');
hold on;

axis([min(noisePowerSim), max(noisePowerSim), 0, 1]);
xlabel('Noise power $$2\sigma^{2} (dBm)$$', 'Interpreter', 'latex');
ylabel({'Successful busy channel'; 'detection probability $$P_{b}^{s}(\Delta t)$$'},...
    'Interpreter','Latex');
legend({'Short ACK sim', 'Short ACK ana', 'Long ACK sim:','Long ACK ana'},...
    'location', 'best', 'Interpreter','Latex', 'FontSize', 5);


%% Plot miss detection probability in busy channel detection verious noise power
figure;
plot(noisePowerSim, busyDetectMiss(1, :), 'ro');
hold on;
plot(noisePowerAna, busyDetectProbMiss(1, :), 'r-');
hold on;

plot(noisePowerSim, busyDetectMiss(2, :), 'bs');
hold on;
plot(noisePowerAna, busyDetectProbMiss(2, :), 'b-.');
hold on;
axis([min(noisePowerSim), max(noisePowerSim), 0, 1]);
xlabel('Noise power $$2\sigma^{2} (dBm)$$', 'Interpreter', 'latex');
ylabel({'Miss probability $$P_{b}^{m}(\Delta t)$$'; 'of busy channel detection'},...
    'Interpreter','Latex');
legend({'Short ACK sim', 'Short ACK ana', 'Long ACK sim:','Long ACK ana'},...
    'location', 'best', 'Interpreter','Latex', 'FontSize', 5);

%% Plot false alarm probability in busy channel detection versus noise power
figure;
plot(noisePowerSim, busyDetectFalseAlarm(1, :), 'ro');
hold on;
plot(noisePowerAna, busyDetectProbFalseAlarm(1, :), 'r-');
hold on;

plot(noisePowerSim, busyDetectFalseAlarm(2, :), 'bs');
hold on;
plot(noisePowerAna, busyDetectProbFalseAlarm(2, :), 'b-.');
hold on;
axis([min(noisePowerSim), max(noisePowerSim), 0, 1]);
xlabel('Noise power $$2\sigma^{2} (dBm)$$', 'Interpreter', 'latex');
ylabel({'False alarm probability $$P_{b}^{f}(\Delta t)$$';'of busy channel detection'},...
    'Interpreter','Latex');
legend({'Short ACK sim', 'Short ACK ana', 'Long ACK sim:','Long ACK ana'},...
    'location', 'best', 'Interpreter','Latex', 'FontSize', 5);


%% Plot successful ORS detection probability versus noise power
figure;
plot(noisePowerSim, ORSDetectAccur(1, :), 'ro');
hold on;
plot(noisePowerAna, ORSDetectProb(1, :), 'r-');
hold on;

plot(noisePowerSim, ORSDetectAccur(2, :), 'bs');
hold on;
plot(noisePowerAna, ORSDetectProb(2, :), 'b-.');
hold on;
axis([min(noisePowerSim), max(noisePowerSim), 0, 1]);
xlabel('Noise power $$2\sigma^{2} (dBm)$$', 'Interpreter', 'latex');
ylabel({'Successful ORS detection'; 'probability $$P_{o}^{s}$$'}, 'Interpreter','Latex')
legend({'Short ACK sim', 'Short ACK ana', 'Long ACK sim:','Long ACK ana'},...
    'location', 'best', 'Interpreter','Latex', 'FontSize', 5);

%% Plot correct ORS type detection probability versus noise power
figure;
plot(noisePowerSim, ORSDecodeAccur(1, :), 'ro');
hold on;
plot(noisePowerAna, ORSDecodeProb(2, :), 'r-');
hold on;

plot(noisePowerSim, ORSDecodeAccur(1, :), 'bs');
hold on;
plot(noisePowerAna, ORSDecodeProb(2, :), 'b-.');
hold on;

axis([min(noisePowerSim), max(noisePowerSim), 0, 1]);
xlabel('Noise power $$2\sigma^{2} (dBm)$$', 'Interpreter', 'latex');
ylabel({'Correct ORS type'; 'detection probability $$P_{o}^{c}$$'},...
    'Interpreter','Latex');
legend({'Short ACK sim', 'Short ACK ana', 'Long ACK sim:','Long ACK ana'},...
    'location', 'best', 'Interpreter','Latex', 'FontSize', 5);

%% Plot successful ACK detection probability versus noise power
figure;
plot(noisePowerSim, ACKSignalDetectAccur(1, :), 'ro');
hold on;
plot(noisePowerAna, ACKSignalDetectProb(1, :), 'r-');
hold on;

plot(noisePowerSim, ACKSignalDetectAccur(2, :), 'bs');
hold on;
plot(noisePowerAna, ACKSignalDetectProb(2, :), 'b-.');
hold on;
axis([min(noisePowerSim), max(noisePowerSim), 0, 1]);
xlabel('Noise power $$2\sigma^{2} (dBm)$$', 'Interpreter', 'latex');
ylabel({'Successful ACK signal detection'; 'probability $$P_{s}^{s}(\Delta t)$$'},...
    'Interpreter','Latex')
legend({'Short ACK sim', 'Short ACK ana', 'Long ACK sim:','Long ACK ana'},...
    'location', 'best', 'Interpreter','Latex', 'FontSize', 5);

%% Calculate successfully detection and correct decoding probabilities.
settingsSim.offset.isRandom = 0;

busyDetectAccur = zeros(2, length(SNRStepSim));
busyDetectMiss = zeros(2, length(SNRStepSim));
busyDetectFalseAlarm = zeros(2, length(SNRStepSim));
ORSDetectAccur = zeros(2, length(SNRStepSim));
ACKSignalDetectAccur = zeros(2, length(SNRStepSim));
ORSDecodeAccur = zeros(2, length(SNRStepSim));
ACKDecodeAccur = zeros(2, length(SNRStepSim));
jth = 1;
for SNR = SNRStepSim
    disp(['Running simulation for busyDetectAccur, busyDetectMiss, busyDetectFalseAlarm, ORSDetectAccur, and ACKSignalDetectAccur' ...
        'in the case where offset is random and SNR = ',num2str(SNR),'.']);
    % 50% chance a ACK signal is transmitted. The type of each ACK
    % signal is uniformly distributed.
    messages = unifrnd(0, 1, maxTimes, 1);
    messages(find(messages>0.5), 1) = randi([1, 4], length(find(messages>0.5)), 1);
    messages(find(messages<=0.5), 1) = 5;
    settingsSim.messages = messages;

    settingsSim.ACKSignalLenType = 'short';
    txWaveform = PHYOQPSK_ACKfeedback(settingsSim.messages, settingsSim.numORS, settingsSim.ACKSignalLenType);
    settingsSim.rxWaveform = AddNoise(SNR, txWaveform);
    accuracies = ACKDetectionBLE(settingsSim);
    busyDetectAccur(1, jth) = accuracies.accurDetectedBusy;
    busyDetectMiss(1, jth) = accuracies.missDetectedBusy;
    busyDetectFalseAlarm(1, jth) = accuracies.falseAlarmDetectedBusy;
    ORSDetectAccur(1, jth) = accuracies.accurDetectedORS;
    ACKSignalDetectAccur(1, jth) = accuracies.accurDetectedACK;

    settingsSim.ACKSignalLenType = 'long';
    txWaveform = PHYOQPSK_ACKfeedback(settingsSim.messages, settingsSim.numORS, settingsSim.ACKSignalLenType);
    settingsSim.rxWaveform = AddNoise(SNR, txWaveform);
    accuracies = ACKDetectionBLE(settingsSim);
    busyDetectAccur(2, jth) = accuracies.accurDetectedBusy;
    busyDetectMiss(2, jth) = accuracies.missDetectedBusy;
    busyDetectFalseAlarm(2, jth) = accuracies.falseAlarmDetectedBusy;
    ORSDetectAccur(2, jth) = accuracies.accurDetectedORS;
    ACKSignalDetectAccur(2, jth) = accuracies.accurDetectedACK;

    jth = jth + 1;
end

settingsSim.offset.isRandom = 1;
jth = 1;
for SNR = SNRStepSim
    disp(['Running decoding simulation in the case where offset is random and SNR = ',num2str(SNR),'.']);
%     messages = randi([1, 4], maxTimes, 1);
%     settingsSim.messages = messages;

    messages = unifrnd(0, 1, maxTimes, 1);
    messages(find(messages>0.5), 1) = randi([1, 4], length(find(messages>0.5)), 1);
    messages(find(messages<=0.5), 1) = 5;
    settingsSim.messages = messages;

    settingsSim.ACKSignalLenType = 'short';
    txWaveform = PHYOQPSK_ACKfeedback(settingsSim.messages, settingsSim.numORS, settingsSim.ACKSignalLenType);
    settingsSim.rxWaveform = AddNoise(SNR, txWaveform);
    accuracies = ACKDetectionBLE(settingsSim);
    ORSDecodeAccur(1, jth) = accuracies.accurDecodedORS;
    ACKDecodeAccur(1, jth) = accuracies.accurDecodedACK;

    settingsSim.ACKSignalLenType = 'long';
    txWaveform = PHYOQPSK_ACKfeedback(settingsSim.messages, settingsSim.numORS, settingsSim.ACKSignalLenType);
    settingsSim.rxWaveform = AddNoise(SNR, txWaveform);
    accuracies = AckDetection(settingsSim);
    ORSDecodeAccur(2, jth) = accuracies.accurDecodedORS;
    ACKDecodeAccur(2, jth) = accuracies.accurDecodedACK;
    
    jth = jth + 1;
end

ACKDetectAccur = busyDetectAccur .* ACKSignalDetectAccur;

settingsAna = settingsSim;
settingsAna.offset.isRandom = 0;
settingsAna.ACKCorrectCases = ACKCorrectList(settingsSim.numORS);
offsetAna = -50: 1: 50;
busyDetectProb = zeros(2.*length(offsetAna), length(SNRStepAna));
busyDetectProbMiss = zeros(2.*length(offsetAna), length(SNRStepAna));
busyDetectProbFalseAlarm = zeros(2.*length(offsetAna), length(SNRStepAna));
ORSDetectProb = zeros(2.*length(offsetAna), length(SNRStepAna));
ACKSignalDetectProb = zeros(2.*length(offsetAna), length(SNRStepAna));

for ith = 1: 1: length(offsetAna)
    jth = 1;
    for SNR = SNRStepAna
        disp(['Running decoding model in the case where offset = ', num2str(offsetAna(1, ith)/100),'us and SNR = ',num2str(SNR),'.']);
        settingsAna.SNR = SNR;
        settingsAna.offset.offsetValue = offsetAna(1, ith);

        settingsAna.ACKSignalLenType = 'short';
        results = BusyChannelDetectProbCal(settingsAna);
        busyDetectProb(ith, jth) = results.succProb;
        busyDetectProbMiss(ith, jth) = results.missProb;
        busyDetectProbFalseAlarm(ith, jth) = results.falseAlarmProb;
        results = ACKDetectProbCal(settingsAna);
        ORSDetectProb(ith, jth) = results.succORSProb;
        ACKSignalDetectProb(ith, jth) = results.succACKProb;

        settingsAna.ACKSignalLenType = 'long';
        results = BusyChannelDetectProbCal(settingsAna);
        busyDetectProb(ith+length(offsetAna), jth) = results.succProb;
        busyDetectProbMiss(ith+length(offsetAna), jth) = results.missProb;
        busyDetectProbFalseAlarm(ith+length(offsetAna), jth) = results.falseAlarmProb;
        results = ACKDetectProbCal(settingsAna);
        ORSDetectProb(ith+length(offsetAna), jth) = results.succORSProb;
        ACKSignalDetectProb(ith+length(offsetAna), jth) = results.succACKProb;

        jth = jth + 1;
    end
end

ACKDetectProb = zeros(2, length(SNRStepAna));
ORSDecodeProbOverall = zeros(2, length(SNRStepAna));
for jth = 1: 1: length(SNRStepAna)
    ACKDetectProb(1, jth) = sum(busyDetectProb(1: 1: length(offsetAna), jth) .* ACKSignalDetectProb(1: 1: length(offsetAna), jth), 1) ./ (max(offsetAna) - min(offsetAna));
    ACKDetectProb(2, jth) = sum(busyDetectProb(length(offsetAna)+1: 1: end, jth) .* ACKSignalDetectProb(length(offsetAna)+1: 1: end, jth), 1) ./ (max(offsetAna) - min(offsetAna));
end

ACKDecodeProb = zeros(2, length(SNRStepAna));
ORSDecodeProb = zeros(2, length(SNRStepAna));
settingsAna.offset.isRandom = 1;

jth = 1;
for SNR = SNRStepAna
    disp(['Running model for calculating ORSDecodeProb & ACKDecodeProb in the case where SNR = ',num2str(SNR),'.']);
    settingsAna.SNR = SNR;

    settingsAna.ACKSignalLenType = 'short';
    results = DecodeProbCal(settingsAna);
    ACKDecodeProb(1, jth) = results.corrACKDecodeProb;
    ORSDecodeProb(1, jth) = results.corrORSDecodeProb;

    settingsAna.ACKSignalLenType = 'long';
    results = DecodeProbCal(settingsAna);
    ACKDecodeProb(2, jth) = results.corrACKDecodeProb;
    ORSDecodeProb(2, jth) = results.corrORSDecodeProb;

    jth = jth + 1;
end

%% Plot successful ACK detection probability verious noise power
figure;
plot(noisePowerSim, ACKDetectAccur(1, :), 'ro');
hold on;
plot(noisePowerAna, ACKDetectProb(2, :), 'r-');
hold on;

plot(noisePowerSim, ACKDetectAccur(1, :), 'bs');
hold on;
plot(noisePowerAna, ACKDetectProb(2, :), 'b-.');
hold on;

axis([min(noisePowerSim), max(noisePowerSim), 0, 1]);
xlabel('Noise power $$2\sigma^{2} (dBm)$$', 'Interpreter', 'latex');
ylabel({'Successful ACK detection'; 'probability $$P_{ACK}^{s}$$'},...
    'Interpreter','Latex');
legend({'Short ACK sim', 'Short ACK ana', 'Long ACK sim:','Long ACK ana'},...
    'location', 'best', 'Interpreter','Latex', 'FontSize', 5);

%% Plot overvall correct ORS type detection probability verious noise power
figure;
plot(noisePowerSim, ORSDecodeAccur(1, :), 'ro');
hold on;
plot(noisePowerAna, ORSDecodeProb(2, :), 'r-');
hold on;

plot(noisePowerSim, ORSDecodeAccur(1, :), 'bs');
hold on;
plot(noisePowerAna, ORSDecodeProb(2, :), 'b-.');
hold on;

axis([min(noisePowerSim), max(noisePowerSim), 0, 1]);
xlabel('Noise power $$2\sigma^{2} (dBm)$$', 'Interpreter', 'latex');
ylabel({'Overall correct ORS type'; 'detection probability $$\bar{P}_{o}^{c}$$'},...
    'Interpreter','Latex');
legend({'Short ACK sim', 'Short ACK ana', 'Long ACK sim:','Long ACK ana'},...
    'location', 'best', 'Interpreter','Latex', 'FontSize', 5);

%% Plot correct ACK decoding probability versus noise power
figure;
plot(noisePowerSim, ACKDecodeAccur(1, :), 'ro');
hold on;
plot(noisePowerAna, ACKDecodeProb(1, :), 'r-');
hold on;

plot(noisePowerSim, ACKDecodeAccur(2, :), 'bs');
hold on;
plot(noisePowerAna, ACKDecodeProb(2, :), 'b-.');
hold on;
axis([min(noisePowerSim), max(noisePowerSim), 0, 1]);
xlabel('Noise power $$2\sigma^{2} (dBm)$$', 'Interpreter', 'latex');
ylabel('Correct ACK decoding probability $$P_{c}$$', 'Interpreter','Latex')
legend({'Short ACK sim', 'Short ACK ana', 'Long ACK sim:','Long ACK ana'},...
    'location', 'best', 'Interpreter','Latex', 'FontSize', 5);
