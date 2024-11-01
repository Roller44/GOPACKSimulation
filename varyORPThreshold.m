clear all;
clc;

global signalPower_dBm;
signalPower_dBm = 10;

%% parameter
settingsSim.ACKThreshold = 10;
settingsSim.powerThreshold = 0.011;
settingsSim.offset.isRandom = 0;
settingsSim.offset.offsetValue = 25;
settingsSim.offset.max = 50;
settingsSim.offset.min = -50;
settingsSim.numORS = 15;


settingsAna.numORS = settingsSim.numORS;
settingsAna.ACKThreshold = settingsSim.ACKThreshold;
settingsAna.offset = settingsSim.offset;

maxTimes = 5000;
ORSThresholdStepSim = 0.1: 0.3: pi;
ORSThresholdStepAna = 0.1: 0.05: pi;
SNR_Step = 0: 5: 15;

ORSDetectAccur = zeros(length(ORSThresholdStepSim), length(SNR_Step));
ORSDetectProb = zeros(length(ORSThresholdStepSim), length(SNR_Step));

ORSDecodeAccur = zeros(length(ORSThresholdStepSim), length(SNR_Step));
ORSDecodeProb = zeros(length(ORSThresholdStepSim), length(SNR_Step));

ACKDecodeAccur = zeros(length(ORSThresholdStepSim), length(SNR_Step));
ACKDecodeProb = zeros(length(ORSThresholdStepSim), length(SNR_Step));

busyProb = 0.5;
notACKProb = 0.2;
ith = 1;
for ORSThreshold = ORSThresholdStepSim
    jth = 1;
    for SNR = SNR_Step
        disp(['Runing simulation for the case where ORSThreshold = ', num2str(ORSThreshold),' and SNR = ',num2str(SNR),'.']);
        % 50% chance a ACK signal is transmitted. The type of each ACK
        % signal is uniformly distributed.
        settingsSim.ACKSignalLenType = 'short';
        messages = unifrnd(0, 1, maxTimes, 1);
        messages(find(messages > busyProb), 1) = 5;
        messages(find(messages < busyProb*notACKProb), 1) = 6;
        messages(find((messages >= busyProb*notACKProb) & (messages < busyProb)), 1) = randi([1, 4], length(find((messages >= busyProb*notACKProb) & (messages < busyProb))), 1);
        settingsSim.messages = messages;
        txWaveform = PHYOQPSK_ACKfeedback(settingsSim.messages, settingsSim.numORS, settingsSim.ACKSignalLenType);
        settingsSim.rxWaveform = AddNoise(SNR, txWaveform);
        settingsSim.ORSThreshold = ORSThreshold;
        accuracies = AckDetection(settingsSim);
        ORSDetectAccur(ith, jth) = accuracies.accurDetectedORS;
        ORSDecodeAccur(ith, jth) = accuracies.accurDecodedORS;
        ACKDecodeAccur(ith, jth) = accuracies.accurDecodedACK;
        
        jth = jth + 1;
    end
    ith = ith + 1;
end

settingsAna = settingsSim;
settingsAna.ACKCorrectCases = ACKCorrectList(settingsSim.numORS);
settingsAna.busyProb = busyProb;
settingsAna.notACKProb = notACKProb;
ith = 1;
for ORSThreshold = ORSThresholdStepAna
    jth = 1;
    for SNR = SNR_Step
        disp(['Runing model for the case where ORSThreshold = ', num2str(ORSThreshold),' and SNR = ',num2str(SNR),'.']);
        settingsAna.ACKSignalLenType = 'short';
        settingsAna.ORSThreshold = ORSThreshold;
        settingsAna.SNR = SNR;
        results = ACKDetectProbCal(settingsAna);
        ORSDetectProb(ith, jth) = results.succORSProb;
        results = DecodeProbCal(settingsAna);
        ORSDecodeProb(ith, jth) = results.corrORSDecodeProb;
        ACKDecodeProb(ith, jth) = results.corrACKDecodeProb;

        jth = jth + 1;
    end
    ith = ith + 1;
end


%% Plot ORS successful detection ratio various ACK_threshold.
figure;
plot(ORSThresholdStepSim, ORSDetectAccur(:, 1), 'ro');
hold on;
plot(ORSThresholdStepSim, ORSDetectAccur(:, 2), 'b*');
hold on;
plot(ORSThresholdStepSim, ORSDetectAccur(:, 3), 'k+');
hold on;
plot(ORSThresholdStepSim, ORSDetectAccur(:, 4), 'm^');
hold on;

plot(ORSThresholdStepAna, ORSDetectProb(:, 1), 'r-');
hold on;
plot(ORSThresholdStepAna, ORSDetectProb(:, 2), 'b--');
hold on;
plot(ORSThresholdStepAna, ORSDetectProb(:, 3), 'k-.');
hold on;
plot(ORSThresholdStepAna, ORSDetectProb(:, 4), 'm:');
xlabel('The threshold $$\Delta\hat{\varphi}_{th}$$ used for ORS detection', 'Interpreter', 'latex');
ylabel('Successful ORS detection probability', 'Interpreter','Latex')
axis([min(ORSThresholdStepSim), max(ORSThresholdStepSim), 0, 1]);
legend({'Sim: SNR=0dB', 'Sim: SNR=5dB', 'Sim: SNR=10dB', 'Sim: SNR=15dB',...
    'Ana: SNR=0dB', 'Ana: SNR=5dB', 'Ana: SNR=10dB', 'Ana: SNR=15dB'},...
    'location', 'best', 'Interpreter','Latex', 'FontSize', 4);

figure;
plot(ORSThresholdStepSim, ORSDecodeAccur(:, 1), 'ro');
hold on;
plot(ORSThresholdStepSim, ORSDecodeAccur(:, 2), 'b*');
hold on;
plot(ORSThresholdStepSim, ORSDecodeAccur(:, 3), 'k+');
hold on;
plot(ORSThresholdStepSim, ORSDecodeAccur(:, 4), 'm^');
hold on;

plot(ORSThresholdStepAna, ORSDecodeProb(:, 1), 'r-');
hold on;
plot(ORSThresholdStepAna, ORSDecodeProb(:, 2), 'b--');
hold on;
plot(ORSThresholdStepAna, ORSDecodeProb(:, 3), 'k-.');
hold on;
plot(ORSThresholdStepAna, ORSDecodeProb(:, 4), 'm:');
xlabel('The threshold $$\Delta\hat{\varphi}_{th}$$ used for ORS detection', 'Interpreter', 'latex');
ylabel('Correct ORS decoding probability', 'Interpreter','Latex')
axis([min(ORSThresholdStepSim), max(ORSThresholdStepSim), 0, 1]);
legend({'Sim: SNR=0dB', 'Sim: SNR=5dB', 'Sim: SNR=10dB', 'Sim: SNR=15dB',...
    'Ana: SNR=0dB', 'Ana: SNR=5dB', 'Ana: SNR=10dB', 'Ana: SNR=15dB'},...
    'location', 'best', 'Interpreter','Latex', 'FontSize', 4);

figure;
plot(ORSThresholdStepSim, ACKDecodeAccur(:, 1), 'ro');
hold on;
plot(ORSThresholdStepSim, ACKDecodeAccur(:, 2), 'b*');
hold on;
plot(ORSThresholdStepSim, ACKDecodeAccur(:, 3), 'k+');
hold on;
plot(ORSThresholdStepSim, ACKDecodeAccur(:, 4), 'm^');
hold on;

plot(ORSThresholdStepAna, ACKDecodeProb(:, 1), 'r-');
hold on;
plot(ORSThresholdStepAna, ACKDecodeProb(:, 2), 'b--');
hold on;
plot(ORSThresholdStepAna, ACKDecodeProb(:, 3), 'k-.');
hold on;
plot(ORSThresholdStepAna, ACKDecodeProb(:, 4), 'm:');
xlabel('The threshold $$\Delta\hat{\varphi}_{th}$$ used for ORS detection', 'Interpreter', 'latex');
ylabel('Correct ACK decoding probability', 'Interpreter','Latex')
axis([min(ORSThresholdStepSim), max(ORSThresholdStepSim), 0, 1]);
legend({'Sim: SNR=0dB', 'Sim: SNR=5dB', 'Sim: SNR=10dB', 'Sim: SNR=15dB',...
    'Ana: SNR=0dB', 'Ana: SNR=5dB', 'Ana: SNR=10dB', 'Ana: SNR=15dB'},...
    'location', 'best', 'Interpreter','Latex', 'FontSize', 4);
