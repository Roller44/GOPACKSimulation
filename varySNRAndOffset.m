clear all;
clc;
%% Assume the ZigBee TX power is 10dBm.
global signalPower_dBm;
signalPower_dBm = 10;

%% parameter
maxTimes = 100; % 2000;
offsetSim = -50: 10: 50; % [-50, -45, -35, -25, -15, -5, 5, 15, 25, 35, 45, 50]; % us
offsetAna = -50: 1: 50; % us
% offsetAna = offsetSim;
% numORS = 15;
numORS = 3;

% Frame duration
PreambleDur = 128;
SFDDur = 32;
SHRDur = PreambleDur + SFDDur;
PHRDur = 32;
HeaderDur = SHRDur + PHRDur;    
numSym = 10: 20: 50; % 5, 10, and 25 bytes
PayloadDur = 16*numSym;
SIFSDur = 12*16; % The length of a SIFS is equal to that of 16 symbols.
packetDur = HeaderDur + PayloadDur;
ORSDur = 1;
ACKDur_ShortSignal = (numORS+1) .* ORSDur;
ACKDur_LongSignal = 2.*numORS.*ORSDur;
ProbPktSucc = 0.8;

settingsSim.ACKThreshold = 8;
settingsSim.ORSPhaseThreshold = 1;
settingsSim.ORSNumThreshold = 1;
settingsSim.powerThreshold = 0.013;
settingsSim.offset.isRandom = 0;
settingsSim.offset.offsetValue = 20;
settingsSim.offset.max = 50;
settingsSim.offset.min = -50;
settingsSim.numORS = numORS;
settingsSim.RXType = 'WiFi';

%% Simulation and model for metrics versus sampling offset
SNRStepSim = 0: -1: -1; % Debugging.
dispSNRStep = SNRStepSim;

busyDetectAccur_ShortSignal = zeros(length(SNRStepSim), length(offsetSim));
busyDetectAccurMiss_ShortSignal = zeros(length(SNRStepSim), length(offsetSim));
busyDetectAccurFalseAlarm_ShortSignal = zeros(length(SNRStepSim), length(offsetSim));
ORSDetectAccur_ShortSignal = zeros(length(SNRStepSim), length(offsetSim));
ACKSignalDetectAccur_ShortSignal = zeros(length(SNRStepSim), length(offsetSim));
ACKDecodeAccur_ShortSignal = zeros(length(SNRStepSim), length(offsetSim));

busyDetectAccur_LongSignal = zeros(length(SNRStepSim), length(offsetSim));
busyDetectAccurMiss_LongSignal = zeros(length(SNRStepSim), length(offsetSim));
busyDetectAccurFalseAlarm_LongSignal = zeros(length(SNRStepSim), length(offsetSim));
ORSDetectAccur_LongSignal = zeros(length(SNRStepSim), length(offsetSim));
ACKSignalDetectAccur_LongSignal = zeros(length(SNRStepSim), length(offsetSim));
ACKDecodeAccur_LongSignal = zeros(length(SNRStepSim), length(offsetSim));

busyProb = 1;
notACKProb = 0;
for ith = 1: 1: length(SNRStepSim)
    SNR = SNRStepSim(1, ith);
    disp(['Runing simulation for SNR = ',num2str(SNR),'dB.']);
    for jth = 1: 1: length(offsetSim)
        settingsSim.offset.isRandom = 0;
        settingsSim.offset.offsetValue = offsetSim(1, jth);
        disp(['---Runing simulation for offset = ', num2str(offsetSim(1, jth)/100),'us.']);
        messages = randi([1, 4], maxTimes, 1);
        settingsSim.messages = messages;

        settingsSim.ACKSignalLenType = 'short';
        % Debugging.
        messages(find((messages >= busyProb*notACKProb) & (messages < busyProb)), 1)...
            = randi([1, 1], length(find((messages >= busyProb*notACKProb) & (messages < busyProb))), 1);
        settingsSim.messages = messages;
        txWaveform = PHYOQPSK_ACKfeedback(settingsSim.messages, settingsSim.numORS, settingsSim.ACKSignalLenType, settingsSim.RXType);
        settingsSim.rxWaveform = AddNoise(SNR, txWaveform);
        if isequal(settingsSim.RXType, 'BLE')
            accuracies = ACKDetectionBLE(settingsSim);
        else
            accuracies = ACKDetectionWiFi(settingsSim);
        end
        busyDetectAccur_ShortSignal(ith, jth) = accuracies.accurDetectedBusy;
        busyDetectAccurMiss_ShortSignal(ith, jth) = accuracies.missDetectedBusy;
        busyDetectAccurFalseAlarm_ShortSignal(ith, jth) = accuracies.falseAlarmDetectedBusy;
        ORSDetectAccur_ShortSignal(ith, jth) = accuracies.accurDetectedORS;
        ACKSignalDetectAccur_ShortSignal(ith, jth) = accuracies.accurDetectedACK;
        ACKDecodeAccur_ShortSignal(ith, jth) = accuracies.accurDecodedACK;

        settingsSim.ACKSignalLenType = 'long';
        txWaveform = PHYOQPSK_ACKfeedback(settingsSim.messages, settingsSim.numORS, settingsSim.ACKSignalLenType, settingsSim.RXType);
        settingsSim.rxWaveform = AddNoise(SNR, txWaveform);
        if isequal(settingsSim.RXType, 'BLE')
            accuracies = ACKDetectionBLE(settingsSim);
        else
            accuracies = ACKDetectionWiFi(settingsSim);
        end
        busyDetectAccur_LongSignal(ith, jth) = accuracies.accurDetectedBusy;
        busyDetectAccurMiss_LongSignal(ith, jth) = accuracies.missDetectedBusy;
        busyDetectAccurFalseAlarm_LongSignal(ith, jth) = accuracies.falseAlarmDetectedBusy;
        ORSDetectAccur_LongSignal(ith, jth) = accuracies.accurDetectedORS;
        ACKSignalDetectAccur_LongSignal(ith, jth) = accuracies.accurDetectedACK;
        ACKDecodeAccur_LongSignal(ith, jth) = accuracies.accurDecodedACK;
    end
end

ACKDetectAccur_ShortSignal = busyDetectAccur_ShortSignal .* ACKSignalDetectAccur_ShortSignal;
ACKDetectAccur_LongSignal = busyDetectAccur_LongSignal .* ACKSignalDetectAccur_LongSignal;
ACKReceptAccur_ShortSignal = sum((ACKDetectAccur_ShortSignal .* ACKDecodeAccur_ShortSignal), 2) ./ size(offsetSim, 2);
ACKReceptAccur_LongSignal = sum((ACKDetectAccur_LongSignal .* ACKDecodeAccur_LongSignal), 2) ./ size(offsetSim, 2);
overHeadSim_ShortSignal = zeros(length(numSym), length(SNRStepSim));
overHeadSim_LongSignal = zeros(length(numSym), length(SNRStepSim));
for ith = 1: 1: length(numSym)
    for jth = 1: 1: length(SNRStepSim)
        overHeadSim_ShortSignal(ith, jth) = (packetDur(1, ith) + SIFSDur + ACKDur_ShortSignal) .* (1./ (ProbPktSucc .* ACKReceptAccur_ShortSignal(jth, 1)));
        overHeadSim_LongSignal(ith, jth) = (packetDur(1, ith) + SIFSDur + ACKDur_LongSignal) .* (1./ (ProbPktSucc .* ACKReceptAccur_LongSignal(jth, 1)));
    end
end

SNRStepAna = SNRStepSim;
settingsAna = settingsSim;
settingsAna.ACKCorrectCases = ACKCorrectList(settingsAna.numORS);
% settingsAna.busyProb = busyProb;
% settingsAna.notACKProb = notACKProb;

busyDetectProb_ShortSignal = zeros(length(SNRStepAna), length(offsetAna));
busyDetectMissProb_ShortSignal = zeros(length(SNRStepAna), length(offsetAna));
busyDetectFalseAlarmProb_ShortSignal = zeros(length(SNRStepAna), length(offsetAna));
ORSDetectProb_ShortSignal = zeros(length(SNRStepAna), length(offsetAna));
ACKSignalDetectProb_ShortSignal = zeros(length(SNRStepAna), length(offsetAna));
ACKDecodeProb_ShortSignal = zeros(length(SNRStepAna), length(offsetAna));

busyDetectProb_LongSignal = zeros(length(SNRStepAna), length(offsetAna));
busyDetectMissProb_LongSignal = zeros(length(SNRStepAna), length(offsetAna));
busyDetectFalseAlarmProb_LongSignal = zeros(length(SNRStepAna), length(offsetAna));
ORSDetectProb_LongSignal = zeros(length(SNRStepAna), length(offsetAna));
ACKSignalDetectProb_LongSignal = zeros(length(SNRStepAna), length(offsetAna));
ACKDecodeProb_LongSignal = zeros(length(SNRStepAna), length(offsetAna));

for ith = 1: 1: length(SNRStepAna)
    settingsAna.SNR = SNRStepAna(1, ith);
    disp(['---Runing model for SNR = ',num2str(SNRStepAna(1, ith)),'dB.']);
    for jth = 1: 1: length(offsetAna)
        settingsAna.offset.isRandom = 0;
        settingsAna.offset.offsetValue = offsetAna(1, jth);

        disp(['---Runing model for offset = ', num2str(offsetAna(1, jth)/100),'us.']);

        settingsAna.ACKSignalLenType = 'short';
        results = BusyChannelDetectProbCal(settingsAna);
        busyDetectProb_ShortSignal(ith, jth) = results.succProb;
        busyDetectMissProb_ShortSignal(ith, jth) = results.succProb;
        busyDetectFalseAlarmProb_ShortSignal(ith, jth) = results.succProb;
        results = ACKDetectProbCal(settingsAna);
        ORSDetectProb_ShortSignal(ith, jth) = results.succORSProb;
        ACKSignalDetectProb_ShortSignal(ith, jth) = results.succACKProb;
        results = DecodeProbCal(settingsAna);
        ACKDecodeProb_ShortSignal(ith, jth) = results.corrACKDecodeProb;

        settingsAna.ACKSignalLenType = 'long';
        results = BusyChannelDetectProbCal(settingsAna);
        busyDetectProb_LongSignal(ith, jth) = results.succProb;
        busyDetectMissProb_LongSignal(ith, jth) = results.succProb;
        busyDetectFalseAlarmProb_LongSignal(ith, jth) = results.succProb;
        results = ACKDetectProbCal(settingsAna);
        ORSDetectProb_LongSignal(ith, jth) = results.succORSProb;
        ACKSignalDetectProb_LongSignal(ith, jth) = results.succACKProb;
        results = DecodeProbCal(settingsAna);
        ACKDecodeProb_LongSignal(ith, jth) = results.corrACKDecodeProb;
    end
end

ACKDetectProb_ShortSignal = busyDetectProb_ShortSignal .* ACKSignalDetectProb_ShortSignal;
ACKDetectProb_LongSignal = busyDetectProb_LongSignal .* ACKSignalDetectProb_LongSignal;
ACKReceptProb_ShortSignal = sum((ACKDetectProb_ShortSignal .* ACKDecodeProb_ShortSignal), 2) ./ size(offsetAna, 2);
ACKReceptProb_LongSignal = sum((ACKDetectProb_LongSignal .* ACKDecodeProb_LongSignal), 2) ./ size(offsetAna, 2);
overHeadAna_ShortSignal = zeros(length(numSym), length(SNRStepAna));
overHeadAna_LongSignal = zeros(length(numSym), length(SNRStepAna));
for ith = 1: 1: length(numSym)
    for jth = 1: 1: length(SNRStepAna)
        overHeadAna_ShortSignal(ith, jth) = (packetDur(1, ith) + SIFSDur + ACKDur_ShortSignal) .* (1./ (ProbPktSucc .* ACKReceptProb_ShortSignal(jth, 1)));
        overHeadAna_LongSignal(ith, jth) = (packetDur(1, ith) + SIFSDur + ACKDur_LongSignal) .* (1./ (ProbPktSucc .* ACKReceptProb_LongSignal(jth, 1)));
    end
end

offsetSim = offsetSim / 100;
offsetAna = offsetAna / 100;

lineSpace = {'-', '--', '-.'};
markerSpace = ['o', '+', '*'];
colorSpace = ['r', 'b'];

noisePwrSim_dBm = signalPower_dBm - SNRStepSim;
noisePwrAna_dBm = signalPower_dBm - SNRStepAna;
dispNoisePwr_dBm = signalPower_dBm - dispSNRStep;
% Plot successful ACK detection probability versus sampling offset
figure;
jth = 1;
for ith = 1: 5: length(dispSNRStep)
    p1 = plot(offsetSim, ACKDetectAccur_ShortSignal(ith, :), 'Color', colorSpace(1, 1),...
        'Marker', markerSpace(1, 1), 'LineStyle', 'none');
    hold on;
    p2 = plot(offsetAna, ACKDetectProb_ShortSignal(ith, :), 'Color', colorSpace(1, 1),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 1));
    hold on;

    p3 = plot(offsetSim, ACKDetectAccur_LongSignal(ith, :), 'Color', colorSpace(1, 2),...
        'Marker', markerSpace(1, 2), 'LineStyle', 'none');
    hold on;
    p4 = plot(offsetAna, ACKDetectProb_LongSignal(ith, :), 'Color', colorSpace(1, 2),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 2));
    hold on;

    jth = jth + 1;
end
hold off;
axis([min(offsetSim), max(offsetSim), 0, 1]);
xlabel('Sampling offset $$\Delta t$$', 'Interpreter', 'latex');
ylabel('Successful probability $$P_{d}(\Delta t)$$ of ACK detection', 'Interpreter','Latex');
% legend([p1, p2, p3, p4], 'Short ACK (sim)', 'Short ACK (ana)', 'Long ACK (sim)', 'Long ACK (ana)', 'location', 'best', 'Interpreter','Latex');
legend([p1, p2, p3, p4], 'Short ACK', 'Short ACK *', 'Long ACK', 'Long ACK *', 'location', 'best', 'Interpreter','Latex');


% Plot successful busy channel detection probability versus sampling offset
figure;
jth = 1;
for ith = 1: 5: length(dispSNRStep)
    p1 = plot(offsetSim, busyDetectAccur_ShortSignal(ith, :), 'Color', colorSpace(1, 1),...
        'Marker', markerSpace(1, 1), 'LineStyle', 'none');
    hold on;
    p2 = plot(offsetAna, busyDetectProb_ShortSignal(ith, :), 'Color', colorSpace(1, 1),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 1));
    hold on;

    p3 = plot(offsetSim, busyDetectAccur_LongSignal(ith, :), 'Color', colorSpace(1, 2),...
        'Marker', markerSpace(1, 2), 'LineStyle', 'none');
    hold on;
    p4 = plot(offsetAna, busyDetectProb_LongSignal(ith, :), 'Color', colorSpace(1, 2),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 2));
    hold on;

    jth = jth + 1;
end
hold off;
axis([min(offsetSim), max(offsetSim), 0, 1]);
xlabel('Sampling offset $$\Delta t$$', 'Interpreter', 'latex');
ylabel({'Successful probability $$P_{C1}(\Delta t)$$';' of detecting busy channel'}, 'Interpreter', 'Latex');
legend([p1, p2, p3, p4], 'Short ACK (sim)', 'Short ACK (ana)', 'Long ACK (sim)', 'Long ACK (ana)', 'location', 'best', 'Interpreter','Latex');

% Plot successful ACK signal detection probability versus offset
figure;
jth = 1;
for ith = 1: 5: length(dispSNRStep)
    p1 = plot(offsetSim, ACKSignalDetectAccur_ShortSignal(ith, :), 'Color', colorSpace(1, 1),...
        'Marker', markerSpace(1, 1), 'LineStyle', 'none');
    hold on;
    p2 = plot(offsetAna, ACKSignalDetectProb_ShortSignal(ith, :), 'Color', colorSpace(1, 1),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 1));
    hold on;

    p3 = plot(offsetSim, ACKSignalDetectAccur_LongSignal(ith, :), 'Color', colorSpace(1, 2),...
        'Marker', markerSpace(1, 2), 'LineStyle', 'none');
    hold on;
    p4 = plot(offsetAna, ACKSignalDetectProb_LongSignal(ith, :), 'Color', colorSpace(1, 2),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 2));
    hold on;

    jth = jth + 1;
end
hold off;
axis([min(offsetSim), max(offsetSim), 0, 1]);
xlabel('Sampling offset $$\Delta t$$ ($$\mu s$$)', 'Interpreter', 'latex');
ylabel({'Successful probability $$P_{C2}(\Delta t)$$'; 'of detecting an ACK signal'}, 'Interpreter','Latex')
% legend([p1, p2, p3, p4], 'Short ACK (sim)', 'Short ACK (ana)', 'Long ACK (sim)', 'Long ACK (ana)', 'location', 'best', 'Interpreter','Latex');
legend([p1, p2, p3, p4], 'Short ACK', 'Short ACK *', 'Long ACK', 'Long ACK *', 'location', 'best', 'Interpreter','Latex');

% % Plot successful ORS detection probability versus offset
% figure;
% jth = 1;
% for ith = 1: 1: length(dispSNRStep)
%     p1 = plot(offsetSim, ORSDetectAccur_ShortSignal(ith, :), 'Color', colorSpace(1, 1),...
%         'Marker', markerSpace(1, 1), 'LineStyle', 'none');
%     hold on;
%     p2 = plot(offsetAna, ORSDetectProb_ShortSignal(ith, :), 'Color', colorSpace(1, 1),...
%         'Marker', 'none', 'LineStyle', lineSpace(1, 1));
%     hold on;
% 
%     p3 = plot(offsetSim, ORSDetectAccur_LongSignal(ith, :), 'Color', colorSpace(1, 2),...
%         'Marker', markerSpace(1, 2), 'LineStyle', 'none');
%     hold on;
%     p4 = plot(offsetAna, ORSDetectProb_LongSignal(ith, :), 'Color', colorSpace(1, 2),...
%         'Marker', 'none', 'LineStyle', lineSpace(1, 2));
%     hold on;
% 
%     jth = jth + 1;
% end
% hold off;
% axis([min(offsetSim), max(offsetSim), 0, 1]);
% xlabel('Sampling offset $$\Delta t$$ ($$\mu s$$)', 'Interpreter', 'latex');
% ylabel('Successful probability $$P_{o}^{s}(\Delta t)$$ of ORS detection', 'Interpreter','Latex')
% legend([p1, p2, p3, p4], 'Short ACK (sim)', 'Short ACK (ana)', 'Long ACK (sim)', 'Long ACK (ana)', 'location', 'best', 'Interpreter','Latex');

% Plot correct ACK decoding probability versus sampling offset
figure;
jth = 1;
for ith = 1: 5: length(dispSNRStep)
    p1 = plot(offsetSim, ACKDecodeAccur_ShortSignal(ith, :), 'Color', colorSpace(1, 1),...
        'Marker', markerSpace(1, 1), 'LineStyle', 'none');
    hold on;
    p2 = plot(offsetAna, ACKDecodeProb_ShortSignal(ith, :), 'Color', colorSpace(1, 1),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 1));
    hold on;

    p3 = plot(offsetSim, ACKDecodeAccur_LongSignal(ith, :), 'Color', colorSpace(1, 2),...
        'Marker', markerSpace(1, 2), 'LineStyle', 'none');
    hold on;
    p4 = plot(offsetAna, ACKDecodeProb_LongSignal(ith, :), 'Color', colorSpace(1, 2),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 2));
    hold on;

    jth = jth + 1;
end
hold off;
axis([min(offsetSim), max(offsetSim), 0.45, 1]);
xlabel('Sampling offset $$\Delta t$$ ($$\mu s$$)', 'Interpreter', 'latex');
ylabel({'Successful probability $$P_{C3}(\Delta t)$$ of'; 'detecting ACK type'}, 'Interpreter','Latex')
% legend([p1, p2, p3, p4], 'Short ACK (sim)', 'Short ACK (ana)', 'Long ACK (sim)', 'Long ACK (ana)', 'location', 'best', 'Interpreter','Latex');
legend([p1, p2, p3, p4], 'Short ACK', 'Short ACK *', 'Long ACK', 'Long ACK *', 'location', 'best', 'Interpreter','Latex');

% Plot succuessful ACK reception probability
figure;
plot(noisePwrSim_dBm, ACKReceptAccur_ShortSignal(:, 1), 'Color', colorSpace(1, 1),...
    'Marker', markerSpace(1, 1), 'LineStyle', 'none', 'DisplayName', 'Short ACK sim');
hold on;
plot(noisePwrAna_dBm, ACKReceptProb_ShortSignal(:, 1), 'Color', colorSpace(1, 1),...
    'Marker', 'none', 'LineStyle', lineSpace(1, 1), 'DisplayName', 'Short ACK ana');
hold on;

plot(noisePwrSim_dBm, ACKReceptAccur_LongSignal(:, 1), 'Color', colorSpace(1, 2),...
    'Marker', markerSpace(1, 2), 'LineStyle', 'none', 'DisplayName', 'Long ACK sim');
hold on;
plot(noisePwrAna_dBm, ACKReceptProb_LongSignal(:, 1), 'Color', colorSpace(1, 2),...
    'Marker', 'none', 'LineStyle', lineSpace(1, 2), 'DisplayName', 'Long ACK ana');
hold off;

axis([min(noisePwrSim_dBm), max(noisePwrSim_dBm), 0, 1]);
xlabel('Noise power $\sigma^2$ (dBm)', 'Interpreter', 'latex');
ylabel('Successful ACK decoding probability $$P_{ACK}^{s}$$', 'Interpreter','Latex')
legend('location', 'best', 'Interpreter','Latex', 'FontSize', 8);

% Plot packet delivery overhead
figure;
jth = 1;
for ith = 1: 1: length(numSym)
    p1 = plot(noisePwrSim_dBm, overHeadSim_ShortSignal(ith, :), 'Color', colorSpace(1, 1),...
        'Marker', markerSpace(1, 1), 'LineStyle', 'none');
    hold on;
    p2 = plot(noisePwrAna_dBm, overHeadAna_ShortSignal(ith, :), 'Color', colorSpace(1, 1),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 1));
    hold on;

    p3 = plot(noisePwrSim_dBm, overHeadSim_LongSignal(ith, :), 'Color', colorSpace(1, 2),...
        'Marker', markerSpace(1, 2), 'LineStyle', 'none');
    hold on;
    p4 = plot(noisePwrAna_dBm, overHeadAna_LongSignal(ith, :), 'Color', colorSpace(1, 2),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 2));
    hold on;

    jth = jth + 1;
end
hold off;
axis([min(noisePwrSim_dBm), max(noisePwrSim_dBm), 0, 1.5.*10^5]);
xlabel('Noise power $\sigma^2$ (dBm)', 'Interpreter', 'latex');
ylabel('Mean complete transmission time $$E(\Omega)$$ ($$\mu s$$)', 'Interpreter','Latex')
% legend('location', 'best', 'Interpreter','Latex', 'FontSize', 8, 'NumColumns',2);
% legend([p1, p2, p3, p4], 'Short ACK (sim)', 'Short ACK (ana)', 'Long ACK (sim)', 'Long ACK (ana)', 'location', 'best', 'Interpreter','Latex');
legend([p1, p2, p3, p4], 'Short ACK', 'Short ACK *', 'Long ACK', 'Long ACK *', 'location', 'best', 'Interpreter','Latex');
