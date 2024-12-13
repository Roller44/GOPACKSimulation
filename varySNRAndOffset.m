%% Assume the ZigBee TX power is 10dBm.
global signalPower_dBm;
signalPower_dBm = 10;
global OSR;
OSR = 100;

%% Global parameter
maxTimes = 5000;
offsetSim = -0.5: 10/OSR: 0.5; % us
offsetAna = -0.5: 1/OSR: 0.5; % us
% offsetAna = offsetSim;
offsetSim = offsetSim .* OSR;
offsetAna = offsetAna .* OSR;


settingsSim.ORSPhaseThreshold = 1;
settingsSim.ORSNumThreshold = 1;
settingsSim.powerThreshold = 0.013;
settingsSim.offset.isRandom = 0;
settingsSim.offset.offsetValue = 20;
settingsSim.offset.max = 50;
settingsSim.offset.min = -50;

%% Simulations for ZigBee-to-BLE feedback, under various SNRs and sampling offsets.
settingsSim.numORS = 15;
settingsSim.ACKThreshold = 9;
settingsSim.RXType = 'BLE';

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
ACKDur_ShortSignal = (settingsSim.numORS + 1) .* ORSDur;
ACKDur_LongSignal = 2 .* settingsSim.numORS .* ORSDur;
ProbPktSucc = 0.8;

SNRStepSim = -5: 1: 5;

busyDetectAccur_ShortSignal_Z2B = zeros(length(SNRStepSim), length(offsetSim));
busyDetectAccurMiss_ShortSignal_Z2B = zeros(length(SNRStepSim), length(offsetSim));
busyDetectAccurFalseAlarm_ShortSignal_Z2B = zeros(length(SNRStepSim), length(offsetSim));
ORSDetectAccur_ShortSignal_Z2B = zeros(length(SNRStepSim), length(offsetSim));
ACKSignalDetectAccur_ShortSignal_Z2B = zeros(length(SNRStepSim), length(offsetSim));
ORSDecodeAccur_ShortSignal_Z2B = zeros(length(SNRStepSim), length(offsetSim));
ACKDecodeAccur_ShortSignal_Z2B = zeros(length(SNRStepSim), length(offsetSim));
QuaDecodeAccur_ShortSignal_Z2B = zeros(length(SNRStepSim), length(offsetSim));

busyDetectAccur_LongSignal_Z2B = zeros(length(SNRStepSim), length(offsetSim));
busyDetectAccurMiss_LongSignal_Z2B = zeros(length(SNRStepSim), length(offsetSim));
busyDetectAccurFalseAlarm_LongSignal_Z2B = zeros(length(SNRStepSim), length(offsetSim));
ORSDetectAccur_LongSignal_Z2B = zeros(length(SNRStepSim), length(offsetSim));
ACKSignalDetectAccur_LongSignal_Z2B = zeros(length(SNRStepSim), length(offsetSim));
ORSDecodeAccur_LongSignal_Z2B = zeros(length(SNRStepSim), length(offsetSim));
ACKDecodeAccur_LongSignal_Z2B = zeros(length(SNRStepSim), length(offsetSim));
QuaDecodeAccur_LongSignal_Z2B = zeros(length(SNRStepSim), length(offsetSim));

busyProb = 1;
notACKProb = 0;
for ith = 1: 1: length(SNRStepSim)
    SNR = SNRStepSim(1, ith);
    disp(['Runing simulation for SNR = ',num2str(SNR),'dB.']);
    for jth = 1: 1: length(offsetSim)
        settingsSim.offset = offsetSim(1, jth);
        disp(['---Runing simulation for ZigBee-to-BlE feedback, under SNR = ', num2str(SNR),'dB and offset = ', num2str(offsetSim(1, jth)/OSR),'us.']);
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
        busyDetectAccur_ShortSignal_Z2B(ith, jth) = accuracies.accurDetectedBusy;
        busyDetectAccurMiss_ShortSignal_Z2B(ith, jth) = accuracies.missDetectedBusy;
        busyDetectAccurFalseAlarm_ShortSignal_Z2B(ith, jth) = accuracies.falseAlarmDetectedBusy;
        ORSDetectAccur_ShortSignal_Z2B(ith, jth) = accuracies.accurDetectedORS;
        ACKSignalDetectAccur_ShortSignal_Z2B(ith, jth) = accuracies.accurDetectedACK;
        ORSDecodeAccur_ShortSignal_Z2B(ith, jth) = accuracies.accurDecodedORS;
        ACKDecodeAccur_ShortSignal_Z2B(ith, jth) = accuracies.accurDecodedACK;
        QuaDecodeAccur_ShortSignal_Z2B(ith, jth) = accuracies.accurQua;

        settingsSim.ACKSignalLenType = 'long';
        txWaveform = PHYOQPSK_ACKfeedback(settingsSim.messages, settingsSim.numORS, settingsSim.ACKSignalLenType, settingsSim.RXType);
        settingsSim.rxWaveform = AddNoise(SNR, txWaveform);
        if isequal(settingsSim.RXType, 'BLE')
            accuracies = ACKDetectionBLE(settingsSim);
        else
            accuracies = ACKDetectionWiFi(settingsSim);
        end
        busyDetectAccur_LongSignal_Z2B(ith, jth) = accuracies.accurDetectedBusy;
        busyDetectAccurMiss_LongSignal_Z2B(ith, jth) = accuracies.missDetectedBusy;
        busyDetectAccurFalseAlarm_LongSignal_Z2B(ith, jth) = accuracies.falseAlarmDetectedBusy;
        ORSDetectAccur_LongSignal_Z2B(ith, jth) = accuracies.accurDetectedORS;
        ACKSignalDetectAccur_LongSignal_Z2B(ith, jth) = accuracies.accurDetectedACK;
        ORSDecodeAccur_LongSignal_Z2B(ith, jth) = accuracies.accurDecodedORS;
        ACKDecodeAccur_LongSignal_Z2B(ith, jth) = accuracies.accurDecodedACK;
        QuaDecodeAccur_LongSignal_Z2B(ith, jth) = accuracies.accurQua;
    end
end

ACKDetectAccur_ShortSignal_Z2B = busyDetectAccur_ShortSignal_Z2B .* ACKSignalDetectAccur_ShortSignal_Z2B;
ACKDetectAccur_LongSignal_Z2B = busyDetectAccur_LongSignal_Z2B .* ACKSignalDetectAccur_LongSignal_Z2B;
ACKReceptAccur_ShortSignal_Z2B = sum((ACKDetectAccur_ShortSignal_Z2B .* ACKDecodeAccur_ShortSignal_Z2B), 2) ./ size(offsetSim, 2);
ACKReceptAccur_LongSignal_Z2B = sum((ACKDetectAccur_LongSignal_Z2B .* ACKDecodeAccur_LongSignal_Z2B), 2) ./ size(offsetSim, 2);
overHeadSim_ShortSignal_Z2B = zeros(length(numSym), length(SNRStepSim));
overHeadSim_LongSignal_Z2B = zeros(length(numSym), length(SNRStepSim));
for ith = 1: 1: length(numSym)
    for jth = 1: 1: length(SNRStepSim)
        overHeadSim_ShortSignal_Z2B(ith, jth) = (packetDur(1, ith) + SIFSDur + ACKDur_ShortSignal) .* (1./ (ProbPktSucc .* ACKReceptAccur_ShortSignal_Z2B(jth, 1)));
        overHeadSim_LongSignal_Z2B(ith, jth) = (packetDur(1, ith) + SIFSDur + ACKDur_LongSignal) .* (1./ (ProbPktSucc .* ACKReceptAccur_LongSignal_Z2B(jth, 1)));
    end
end

%% Models for ZigBee-to-BLE feedback under various SNRs and sampling offsets.

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
ACKDur_ShortSignal = (settingsSim.numORS + 1) .* ORSDur;
ACKDur_LongSignal = 2 .* settingsSim.numORS .* ORSDur;
ProbPktSucc = 0.8;

SNRStepAna = SNRStepSim;
settingsAna = settingsSim;
settingsAna.ACKCorrectCases = ACKCorrectList(settingsAna.numORS);

% settingsAna.busyProb = busyProb;
% settingsAna.notACKProb = notACKProb;


busyDetectProb_ShortSignal_Z2B = zeros(length(SNRStepAna), length(offsetAna));
busyDetectMissProb_ShortSignal_Z2B = zeros(length(SNRStepAna), length(offsetAna));
busyDetectFalseAlarmProb_ShortSignal_Z2B = zeros(length(SNRStepAna), length(offsetAna));
ORSDetectProb_ShortSignal_Z2B = zeros(length(SNRStepAna), length(offsetAna));
ACKSignalDetectProb_ShortSignal_Z2B = zeros(length(SNRStepAna), length(offsetAna));
ORSDecodeProb_ShortSignal_Z2B = zeros(length(SNRStepAna), length(offsetAna));
ACKDecodeProb_ShortSignal_Z2B = zeros(length(SNRStepAna), length(offsetAna));
QuaDecodeProb_ShortSignal_Z2B = zeros(length(SNRStepAna), length(offsetAna));

busyDetectProb_LongSignal_Z2B = zeros(length(SNRStepAna), length(offsetAna));
busyDetectMissProb_LongSignal_Z2B = zeros(length(SNRStepAna), length(offsetAna));
busyDetectFalseAlarmProb_LongSignal_Z2B = zeros(length(SNRStepAna), length(offsetAna));
ORSDetectProb_LongSignal_Z2B = zeros(length(SNRStepAna), length(offsetAna));
ACKSignalDetectProb_LongSignal_Z2B = zeros(length(SNRStepAna), length(offsetAna));
ORSDecodeProb_LongSignal_Z2B = zeros(length(SNRStepAna), length(offsetAna));
ACKDecodeProb_LongSignal_Z2B = zeros(length(SNRStepAna), length(offsetAna));
QuaDecodeProb_LongSignal_Z2B = zeros(length(SNRStepAna), length(offsetAna));

for ith = 1: 1: length(SNRStepAna)
    settingsAna.SNR = SNRStepAna(1, ith);
    disp(['Runing model for SNR = ',num2str(SNRStepAna(1, ith)),'dB.']);
    for jth = 1: 1: length(offsetAna)
        settingsAna.offset = offsetAna(1, jth);

        disp(['---Runing model for ZigBee-to-BlE feedback, under SNR = ', num2str(settingsAna.SNR),'dB and offset = ', num2str(offsetAna(1, jth)/OSR),'us.']);
        settingsAna.ACKSignalLenType = 'short';
        results = BusyChannelDetectProbCal(settingsAna);
        busyDetectProb_ShortSignal_Z2B(ith, jth) = results.succProb;
        busyDetectMissProb_ShortSignal_Z2B(ith, jth) = results.succProb;
        busyDetectFalseAlarmProb_ShortSignal_Z2B(ith, jth) = results.succProb;
        results = ACKDetectProbCal(settingsAna);
        ORSDetectProb_ShortSignal_Z2B(ith, jth) = results.succORSProb;
        ACKSignalDetectProb_ShortSignal_Z2B(ith, jth) = results.succACKProb;
        results = DecodeProbCal(settingsAna);
        ORSDecodeProb_ShortSignal_Z2B(ith, jth) = results.corrORSDecodeProb;
        ACKDecodeProb_ShortSignal_Z2B(ith, jth) = results.corrACKDecodeProb;
        QuaDecodeProb_ShortSignal_Z2B(ith, jth) = results.corrQuaDecodeProb;

        settingsAna.ACKSignalLenType = 'long';
        results = BusyChannelDetectProbCal(settingsAna);
        busyDetectProb_LongSignal_Z2B(ith, jth) = results.succProb;
        busyDetectMissProb_LongSignal_Z2B(ith, jth) = results.succProb;
        busyDetectFalseAlarmProb_LongSignal_Z2B(ith, jth) = results.succProb;
        results = ACKDetectProbCal(settingsAna);
        ORSDetectProb_LongSignal_Z2B(ith, jth) = results.succORSProb;
        ACKSignalDetectProb_LongSignal_Z2B(ith, jth) = results.succACKProb;
        results = DecodeProbCal(settingsAna);
        ORSDecodeProb_LongSignal_Z2B(ith, jth) = results.corrORSDecodeProb;
        ACKDecodeProb_LongSignal_Z2B(ith, jth) = results.corrACKDecodeProb;
        QuaDecodeProb_LongSignal_Z2B(ith, jth) = results.corrQuaDecodeProb;
    end
end

ACKDetectProb_ShortSignal_Z2B = busyDetectProb_ShortSignal_Z2B .* ACKSignalDetectProb_ShortSignal_Z2B;
ACKDetectProb_LongSignal_Z2B = busyDetectProb_LongSignal_Z2B .* ACKSignalDetectProb_LongSignal_Z2B;
ACKReceptProb_ShortSignal_Z2B = sum((ACKDetectProb_ShortSignal_Z2B .* ACKDecodeProb_ShortSignal_Z2B), 2) ./ size(offsetAna, 2);
ACKReceptProb_LongSignal_Z2B = sum((ACKDetectProb_LongSignal_Z2B .* ACKDecodeProb_LongSignal_Z2B), 2) ./ size(offsetAna, 2);
overHeadAna_ShortSignal_Z2B = zeros(length(numSym), length(SNRStepAna));
overHeadAna_LongSignal_Z2B = zeros(length(numSym), length(SNRStepAna));
for ith = 1: 1: length(numSym)
    for jth = 1: 1: length(SNRStepAna)
        overHeadAna_ShortSignal_Z2B(ith, jth) = (packetDur(1, ith) + SIFSDur + ACKDur_ShortSignal) .* (1./ (ProbPktSucc .* ACKReceptProb_ShortSignal_Z2B(jth, 1)));
        overHeadAna_LongSignal_Z2B(ith, jth) = (packetDur(1, ith) + SIFSDur + ACKDur_LongSignal) .* (1./ (ProbPktSucc .* ACKReceptProb_LongSignal_Z2B(jth, 1)));
    end
end

%% Simulation for ZigBee-to-WiFi feedback, under various SNRs and sampling offsets.
settingsSim.numORS = 3;
settingsSim.ACKThreshold = 1;
settingsSim.RXType = 'WiFi';

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
ACKDur_ShortSignal = (settingsSim.numORS + 1) .* ORSDur;
ACKDur_LongSignal = 2 .* settingsSim.numORS .* ORSDur;
ProbPktSucc = 0.8;

busyDetectAccur_ShortSignal_Z2W = zeros(length(SNRStepSim), length(offsetSim));
busyDetectAccurMiss_ShortSignal_Z2W = zeros(length(SNRStepSim), length(offsetSim));
busyDetectAccurFalseAlarm_ShortSignal_Z2W = zeros(length(SNRStepSim), length(offsetSim));
ORSDetectAccur_ShortSignal_Z2W = zeros(length(SNRStepSim), length(offsetSim));
ACKSignalDetectAccur_ShortSignal_Z2W = zeros(length(SNRStepSim), length(offsetSim));
ORSDecodeAccur_ShortSignal_Z2W = zeros(length(SNRStepSim), length(offsetSim));
ACKDecodeAccur_ShortSignal_Z2W = zeros(length(SNRStepSim), length(offsetSim));
QuaDecodeAccur_ShortSignal_Z2W = zeros(length(SNRStepSim), length(offsetSim));

busyDetectAccur_LongSignal_Z2W = zeros(length(SNRStepSim), length(offsetSim));
busyDetectAccurMiss_LongSignal_Z2W = zeros(length(SNRStepSim), length(offsetSim));
busyDetectAccurFalseAlarm_LongSignal_Z2W = zeros(length(SNRStepSim), length(offsetSim));
ORSDetectAccur_LongSignal_Z2W = zeros(length(SNRStepSim), length(offsetSim));
ACKSignalDetectAccur_LongSignal_Z2W = zeros(length(SNRStepSim), length(offsetSim));
ORSDecodeAccur_LongSignal_Z2W = zeros(length(SNRStepSim), length(offsetSim));
ACKDecodeAccur_LongSignal_Z2W = zeros(length(SNRStepSim), length(offsetSim));
QuaDecodeAccur_LongSignal_Z2W = zeros(length(SNRStepSim), length(offsetSim));

busyProb = 1;
notACKProb = 0;
for ith = 1: 1: length(SNRStepSim)
    SNR = SNRStepSim(1, ith);
    disp(['Runing simulation for SNR = ',num2str(SNR),'dB.']);
    for jth = 1: 1: length(offsetSim)
        settingsSim.offset = offsetSim(1, jth);
        disp(['---Runing simulation for ZigBee-to-WiFi feedback, under SNR = ', num2str(SNR),'dB and offset = ', num2str(offsetSim(1, jth)/OSR),'us.']);
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
        busyDetectAccur_ShortSignal_Z2W(ith, jth) = accuracies.accurDetectedBusy;
        busyDetectAccurMiss_ShortSignal_Z2W(ith, jth) = accuracies.missDetectedBusy;
        busyDetectAccurFalseAlarm_ShortSignal_Z2W(ith, jth) = accuracies.falseAlarmDetectedBusy;
        ORSDetectAccur_ShortSignal_Z2W(ith, jth) = accuracies.accurDetectedORS;
        ACKSignalDetectAccur_ShortSignal_Z2W(ith, jth) = accuracies.accurDetectedACK;
        ORSDecodeAccur_ShortSignal_Z2W(ith, jth) = accuracies.accurDecodedORS;
        ACKDecodeAccur_ShortSignal_Z2W(ith, jth) = accuracies.accurDecodedACK;
        QuaDecodeAccur_ShortSignal_Z2W(ith, jth) = accuracies.accurQua;

        settingsSim.ACKSignalLenType = 'long';
        txWaveform = PHYOQPSK_ACKfeedback(settingsSim.messages, settingsSim.numORS, settingsSim.ACKSignalLenType, settingsSim.RXType);
        settingsSim.rxWaveform = AddNoise(SNR, txWaveform);
        if isequal(settingsSim.RXType, 'BLE')
            accuracies = ACKDetectionBLE(settingsSim);
        else
            accuracies = ACKDetectionWiFi(settingsSim);
        end
        busyDetectAccur_LongSignal_Z2W(ith, jth) = accuracies.accurDetectedBusy;
        busyDetectAccurMiss_LongSignal_Z2W(ith, jth) = accuracies.missDetectedBusy;
        busyDetectAccurFalseAlarm_LongSignal_Z2W(ith, jth) = accuracies.falseAlarmDetectedBusy;
        ORSDetectAccur_LongSignal_Z2W(ith, jth) = accuracies.accurDetectedORS;
        ACKSignalDetectAccur_LongSignal_Z2W(ith, jth) = accuracies.accurDetectedACK;
        ORSDecodeAccur_LongSignal_Z2W(ith, jth) = accuracies.accurDecodedORS;
        ACKDecodeAccur_LongSignal_Z2W(ith, jth) = accuracies.accurDecodedACK;
        QuaDecodeAccur_LongSignal_Z2W(ith, jth) = accuracies.accurQua;
    end
end

ACKDetectAccur_ShortSignal_Z2W = busyDetectAccur_ShortSignal_Z2W .* ACKSignalDetectAccur_ShortSignal_Z2W;
ACKDetectAccur_LongSignal_Z2W = busyDetectAccur_LongSignal_Z2W .* ACKSignalDetectAccur_LongSignal_Z2W;
ACKReceptAccur_ShortSignal_Z2W = sum((ACKDetectAccur_ShortSignal_Z2W .* ACKDecodeAccur_ShortSignal_Z2W), 2) ./ size(offsetSim, 2);
ACKReceptAccur_LongSignal_Z2W = sum((ACKDetectAccur_LongSignal_Z2W .* ACKDecodeAccur_LongSignal_Z2W), 2) ./ size(offsetSim, 2);
overHeadSim_ShortSignal_Z2W = zeros(length(numSym), length(SNRStepSim));
overHeadSim_LongSignal_Z2W = zeros(length(numSym), length(SNRStepSim));
for ith = 1: 1: length(numSym)
    for jth = 1: 1: length(SNRStepSim)
        overHeadSim_ShortSignal_Z2W(ith, jth) = (packetDur(1, ith) + SIFSDur + ACKDur_ShortSignal) .* (1./ (ProbPktSucc .* ACKReceptAccur_ShortSignal_Z2W(jth, 1)));
        overHeadSim_LongSignal_Z2W(ith, jth) = (packetDur(1, ith) + SIFSDur + ACKDur_LongSignal) .* (1./ (ProbPktSucc .* ACKReceptAccur_LongSignal_Z2W(jth, 1)));
    end
end

%% Models for ZigBee-to-WiFi feedback under various SNRs and sampling offsets.
settingsSim.numORS = 3;
settingsSim.ACKThreshold = 1;
settingsSim.RXType = 'WiFi';

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
ACKDur_ShortSignal = (settingsSim.numORS + 1) .* ORSDur;
ACKDur_LongSignal = 2 .* settingsSim.numORS .* ORSDur;
ProbPktSucc = 0.8;

SNRStepAna = SNRStepSim;
settingsAna = settingsSim;
settingsAna.ACKCorrectCases = ACKCorrectList(settingsAna.numORS);

% settingsAna.busyProb = busyProb;
% settingsAna.notACKProb = notACKProb;


busyDetectProb_ShortSignal_Z2W = zeros(length(SNRStepAna), length(offsetAna));
busyDetectMissProb_ShortSignal_Z2W = zeros(length(SNRStepAna), length(offsetAna));
busyDetectFalseAlarmProb_ShortSignal_Z2W = zeros(length(SNRStepAna), length(offsetAna));
ORSDetectProb_ShortSignal_Z2W = zeros(length(SNRStepAna), length(offsetAna));
ACKSignalDetectProb_ShortSignal_Z2W = zeros(length(SNRStepAna), length(offsetAna));
ORSDecodeProb_ShortSignal_Z2W = zeros(length(SNRStepAna), length(offsetAna));
ACKDecodeProb_ShortSignal_Z2W = zeros(length(SNRStepAna), length(offsetAna));
QuaDecodeProb_ShortSignal_Z2W = zeros(length(SNRStepAna), length(offsetAna));

busyDetectProb_LongSignal_Z2W = zeros(length(SNRStepAna), length(offsetAna));
busyDetectMissProb_LongSignal_Z2W = zeros(length(SNRStepAna), length(offsetAna));
busyDetectFalseAlarmProb_LongSignal_Z2W = zeros(length(SNRStepAna), length(offsetAna));
ORSDetectProb_LongSignal_Z2W = zeros(length(SNRStepAna), length(offsetAna));
ACKSignalDetectProb_LongSignal_Z2W = zeros(length(SNRStepAna), length(offsetAna));
ORSDecodeProb_LongSignal_Z2W = zeros(length(SNRStepAna), length(offsetAna));
ACKDecodeProb_LongSignal_Z2W = zeros(length(SNRStepAna), length(offsetAna));
QuaDecodeProb_LongSignal_Z2W = zeros(length(SNRStepAna), length(offsetAna));

for ith = 1: 1: length(SNRStepAna)
    settingsAna.SNR = SNRStepAna(1, ith);
    disp(['Runing model for SNR = ',num2str(SNRStepAna(1, ith)),'dB.']);
    for jth = 1: 1: length(offsetAna)
        settingsAna.offset = offsetAna(1, jth);

        disp(['---Runing model for ZigBee-to-WiFi feedback, under SNR = ', num2str(settingsAna.SNR),'dB and offset = ', num2str(offsetAna(1, jth)/OSR),'us.']);

        settingsAna.ACKSignalLenType = 'short';
        results = BusyChannelDetectProbCal(settingsAna);
        busyDetectProb_ShortSignal_Z2W(ith, jth) = results.succProb;
        busyDetectMissProb_ShortSignal_Z2W(ith, jth) = results.succProb;
        busyDetectFalseAlarmProb_ShortSignal_Z2W(ith, jth) = results.succProb;
        results = ACKDetectProbCal(settingsAna);
        ORSDetectProb_ShortSignal_Z2W(ith, jth) = results.succORSProb;
        ACKSignalDetectProb_ShortSignal_Z2W(ith, jth) = results.succACKProb;
        results = DecodeProbCal(settingsAna);
        ORSDecodeProb_ShortSignal_Z2W(ith, jth) = results.corrORSDecodeProb;
        ACKDecodeProb_ShortSignal_Z2W(ith, jth) = results.corrACKDecodeProb;
        QuaDecodeProb_ShortSignal_Z2W(ith, jth) = results.corrQuaDecodeProb;

        settingsAna.ACKSignalLenType = 'long';
        results = BusyChannelDetectProbCal(settingsAna);
        busyDetectProb_LongSignal_Z2W(ith, jth) = results.succProb;
        busyDetectMissProb_LongSignal_Z2W(ith, jth) = results.succProb;
        busyDetectFalseAlarmProb_LongSignal_Z2W(ith, jth) = results.succProb;
        results = ACKDetectProbCal(settingsAna);
        ORSDetectProb_LongSignal_Z2W(ith, jth) = results.succORSProb;
        ACKSignalDetectProb_LongSignal_Z2W(ith, jth) = results.succACKProb;
        results = DecodeProbCal(settingsAna);
        ORSDecodeProb_LongSignal_Z2W(ith, jth) = results.corrORSDecodeProb;
        ACKDecodeProb_LongSignal_Z2W(ith, jth) = results.corrACKDecodeProb;
        QuaDecodeProb_LongSignal_Z2W(ith, jth) = results.corrQuaDecodeProb;
    end
end

ACKDetectProb_ShortSignal_Z2W = busyDetectProb_ShortSignal_Z2W .* ACKSignalDetectProb_ShortSignal_Z2W;
ACKDetectProb_LongSignal_Z2W = busyDetectProb_LongSignal_Z2W .* ACKSignalDetectProb_LongSignal_Z2W;
ACKReceptProb_ShortSignal_Z2W = sum((ACKDetectProb_ShortSignal_Z2W .* ACKDecodeProb_ShortSignal_Z2W), 2) ./ size(offsetAna, 2);
ACKReceptProb_LongSignal_Z2W = sum((ACKDetectProb_LongSignal_Z2W .* ACKDecodeProb_LongSignal_Z2W), 2) ./ size(offsetAna, 2);
overHeadAna_ShortSignal_Z2W = zeros(length(numSym), length(SNRStepAna));
overHeadAna_LongSignal_Z2W = zeros(length(numSym), length(SNRStepAna));
for ith = 1: 1: length(numSym)
    for jth = 1: 1: length(SNRStepAna)
        overHeadAna_ShortSignal_Z2W(ith, jth) = (packetDur(1, ith) + SIFSDur + ACKDur_ShortSignal) .* (1./ (ProbPktSucc .* ACKReceptProb_ShortSignal_Z2W(jth, 1)));
        overHeadAna_LongSignal_Z2W(ith, jth) = (packetDur(1, ith) + SIFSDur + ACKDur_LongSignal) .* (1./ (ProbPktSucc .* ACKReceptProb_LongSignal_Z2W(jth, 1)));
    end
end

offsetSim = offsetSim / OSR;
offsetAna = offsetAna / OSR;

lineSpace = {'-', '--', '-.', ':'};
markerSpace = ['o', '+', '*', '^'];
colorSpace = ['r', 'b', 'g', 'k'];

% Plot successful ACK detection probability versus sampling offset
figure;
jth = 1;
for ith = 1: 5: length(SNRStepSim)
    p1 = plot(offsetSim, ACKDetectAccur_ShortSignal_Z2B(ith, :), 'Color', colorSpace(1, 1),...
        'Marker', markerSpace(1, 1), 'LineStyle', 'none');
    hold on;
    p2 = plot(offsetAna, ACKDetectProb_ShortSignal_Z2B(ith, :), 'Color', colorSpace(1, 1),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 1));
    hold on;

    p3 = plot(offsetSim, ACKDetectAccur_LongSignal_Z2B(ith, :), 'Color', colorSpace(1, 2),...
        'Marker', markerSpace(1, 2), 'LineStyle', 'none');
    hold on;
    p4 = plot(offsetAna, ACKDetectProb_LongSignal_Z2B(ith, :), 'Color', colorSpace(1, 2),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 2));
    hold on;

    p5 = plot(offsetSim, ACKDetectAccur_ShortSignal_Z2W(ith, :), 'Color', colorSpace(1, 3),...
        'Marker', markerSpace(1, 3), 'LineStyle', 'none');
    hold on;
    p6 = plot(offsetAna, ACKDetectProb_ShortSignal_Z2W(ith, :), 'Color', colorSpace(1, 3),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 3));
    hold on;

    p7 = plot(offsetSim, ACKDetectAccur_LongSignal_Z2W(ith, :), 'Color', colorSpace(1, 4),...
        'Marker', markerSpace(1, 2), 'LineStyle', 'none');
    hold on;
    p8 = plot(offsetAna, ACKDetectProb_LongSignal_Z2W(ith, :), 'Color', colorSpace(1, 4),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 4));
    hold on;

    jth = jth + 1;
end
hold off;
axis([min(offsetSim), max(offsetSim), 0.6, 1]);
xlabel('Sampling offset $$\Delta t$$', 'Interpreter', 'latex');
ylabel('Successful probability $$P_{d}(\Delta t)$$ of ACK detection', 'Interpreter','Latex');
legend([p1, p2, p3, p4, p5, p6, p7, p8],...
    'Short ACK (Z&B)', 'Short ACK * (Z&B)', 'Long ACK (Z&B)', 'Long ACK * (Z&B)',...
    'Short ACK (Z&W)', 'Short ACK * (Z&W)', 'Long ACK (Z&W)', 'Long ACK * (Z&W)',...
    'location', 'best', 'Interpreter','Latex');


% Plot successful busy channel detection probability versus sampling offset
figure;
jth = 1;
for ith = 1: 5: length(SNRStepSim)
    p1 = plot(offsetSim, busyDetectAccur_ShortSignal_Z2B(ith, :), 'Color', colorSpace(1, 1),...
        'Marker', markerSpace(1, 1), 'LineStyle', 'none');
    hold on;
    p2 = plot(offsetAna, busyDetectProb_ShortSignal_Z2B(ith, :), 'Color', colorSpace(1, 1),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 1));
    hold on;

    p3 = plot(offsetSim, busyDetectAccur_LongSignal_Z2B(ith, :), 'Color', colorSpace(1, 2),...
        'Marker', markerSpace(1, 2), 'LineStyle', 'none');
    hold on;
    p4 = plot(offsetAna, busyDetectProb_LongSignal_Z2B(ith, :), 'Color', colorSpace(1, 2),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 2));
    hold on;

    p5 = plot(offsetSim, busyDetectAccur_ShortSignal_Z2W(ith, :), 'Color', colorSpace(1, 3),...
        'Marker', markerSpace(1, 3), 'LineStyle', 'none');
    hold on;
    p6 = plot(offsetAna, busyDetectProb_ShortSignal_Z2W(ith, :), 'Color', colorSpace(1, 3),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 3));
    hold on;

    p7 = plot(offsetSim, busyDetectAccur_LongSignal_Z2W(ith, :), 'Color', colorSpace(1, 4),...
        'Marker', markerSpace(1, 4), 'LineStyle', 'none');
    hold on;
    p8 = plot(offsetAna, busyDetectProb_LongSignal_Z2W(ith, :), 'Color', colorSpace(1, 4),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 4));
    hold on;

    jth = jth + 1;
end
hold off;
axis([min(offsetSim), max(offsetSim), 0.5, 1]);
xlabel('Sampling offset $$\Delta t$$', 'Interpreter', 'latex');
ylabel({'Successful probability $$P_{C1}(\Delta t)$$';' of detecting busy channel'}, 'Interpreter', 'Latex');
legend([p1, p2, p3, p4, p5, p6, p7, p8],...
    'Short ACK (Z&B)', 'Short ACK * (Z&B)', 'Long ACK (Z&B)', 'Long ACK * (Z&B)',...
    'Short ACK (Z&W)', 'Short ACK * (Z&W)', 'Long ACK (Z&W)', 'Long ACK * (Z&W)',...
    'location', 'best', 'Interpreter','Latex');


% Plot successful ACK signal detection probability versus offset
figure;
jth = 1;
for ith = 1: 5: length(SNRStepSim)
    p1 = plot(offsetSim, ACKSignalDetectAccur_ShortSignal_Z2B(ith, :), 'Color', colorSpace(1, 1),...
        'Marker', markerSpace(1, 1), 'LineStyle', 'none');
    hold on;
    p2 = plot(offsetAna, ACKSignalDetectProb_ShortSignal_Z2B(ith, :), 'Color', colorSpace(1, 1),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 1));
    hold on;

    p3 = plot(offsetSim, ACKSignalDetectAccur_LongSignal_Z2B(ith, :), 'Color', colorSpace(1, 2),...
        'Marker', markerSpace(1, 2), 'LineStyle', 'none');
    hold on;
    p4 = plot(offsetAna, ACKSignalDetectProb_LongSignal_Z2B(ith, :), 'Color', colorSpace(1, 2),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 2));
    hold on;

    p5 = plot(offsetSim, ACKSignalDetectAccur_ShortSignal_Z2W(ith, :), 'Color', colorSpace(1, 3),...
        'Marker', markerSpace(1, 3), 'LineStyle', 'none');
    hold on;
    p6 = plot(offsetAna, ACKSignalDetectProb_ShortSignal_Z2W(ith, :), 'Color', colorSpace(1, 3),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 3));
    hold on;

    p7 = plot(offsetSim, ACKSignalDetectAccur_LongSignal_Z2W(ith, :), 'Color', colorSpace(1, 4),...
        'Marker', markerSpace(1, 4), 'LineStyle', 'none');
    hold on;
    p8 = plot(offsetAna, ACKSignalDetectProb_LongSignal_Z2W(ith, :), 'Color', colorSpace(1, 4),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 4));
    hold on;

    jth = jth + 1;
end
hold off;
axis([min(offsetSim), max(offsetSim), 0, 1]);
xlabel('Sampling offset $$\Delta t$$ ($$\mu s$$)', 'Interpreter', 'latex');
ylabel({'Successful probability $$P_{C2}(\Delta t)$$'; 'of detecting an ACK signal'}, 'Interpreter','Latex')
legend([p1, p2, p3, p4, p5, p6, p7, p8],...
    'Short ACK (Z&B)', 'Short ACK * (Z&B)', 'Long ACK (Z&B)', 'Long ACK * (Z&B)',...
    'Short ACK (Z&W)', 'Short ACK * (Z&W)', 'Long ACK (Z&W)', 'Long ACK * (Z&W)',...
    'location', 'best', 'Interpreter','Latex');

% % Plot successful ORS detection probability versus offset
figure;
jth = 1;
for ith = 1: 5: length(SNRStepSim)
    p1 = plot(offsetSim, ORSDetectAccur_ShortSignal_Z2B(ith, :), 'Color', colorSpace(1, 1),...
        'Marker', markerSpace(1, 1), 'LineStyle', 'none');
    hold on;
    p2 = plot(offsetAna, ORSDetectProb_ShortSignal_Z2B(ith, :), 'Color', colorSpace(1, 1),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 1));
    hold on;

    p3 = plot(offsetSim, ORSDetectAccur_LongSignal_Z2B(ith, :), 'Color', colorSpace(1, 2),...
        'Marker', markerSpace(1, 2), 'LineStyle', 'none');
    hold on;
    p4 = plot(offsetAna, ORSDetectProb_LongSignal_Z2B(ith, :), 'Color', colorSpace(1, 2),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 2));
    hold on;

    p5 = plot(offsetSim, ORSDetectAccur_ShortSignal_Z2W(ith, :), 'Color', colorSpace(1, 3),...
        'Marker', markerSpace(1, 3), 'LineStyle', 'none');
    hold on;
    p6 = plot(offsetAna, ORSDetectProb_ShortSignal_Z2W(ith, :), 'Color', colorSpace(1, 3),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 3));
    hold on;

    p7 = plot(offsetSim, ORSDetectAccur_LongSignal_Z2W(ith, :), 'Color', colorSpace(1, 4),...
        'Marker', markerSpace(1, 4), 'LineStyle', 'none');
    hold on;
    p8 = plot(offsetAna, ORSDetectProb_LongSignal_Z2W(ith, :), 'Color', colorSpace(1, 4),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 4));
    hold on;

    jth = jth + 1;
end
hold off;
axis([min(offsetSim), max(offsetSim), 0, 1]);
xlabel('Sampling offset $$\Delta t$$ ($$\mu s$$)', 'Interpreter', 'latex');
ylabel('Successful probability $$P_{o}^{s}(\Delta t)$$ of ORS detection', 'Interpreter','Latex')
legend([p1, p2, p3, p4, p5, p6, p7, p8],...
    'Short ACK (Z&B)', 'Short ACK * (Z&B)', 'Long ACK (Z&B)', 'Long ACK * (Z&B)',...
    'Short ACK (Z&W)', 'Short ACK * (Z&W)', 'Long ACK (Z&W)', 'Long ACK * (Z&W)',...
    'location', 'best', 'Interpreter','Latex');

% Plot correct ORS decoding probability versus sampling offset
figure;
jth = 1;
for ith = 1: 5: length(SNRStepSim)
    p1 = plot(offsetSim, QuaDecodeAccur_ShortSignal_Z2B(ith, :), 'Color', colorSpace(1, 1),...
        'Marker', markerSpace(1, 1), 'LineStyle', 'none');
    hold on;
    p2 = plot(offsetAna, QuaDecodeProb_ShortSignal_Z2B(ith, :), 'Color', colorSpace(1, 1),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 1));
    hold on;

    p3 = plot(offsetSim, QuaDecodeAccur_LongSignal_Z2B(ith, :), 'Color', colorSpace(1, 2),...
        'Marker', markerSpace(1, 2), 'LineStyle', 'none');
    hold on;
    p4 = plot(offsetAna, QuaDecodeProb_LongSignal_Z2B(ith, :), 'Color', colorSpace(1, 2),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 2));
    hold on;

    p5 = plot(offsetSim, QuaDecodeAccur_ShortSignal_Z2W(ith, :), 'Color', colorSpace(1, 3),...
        'Marker', markerSpace(1, 3), 'LineStyle', 'none');
    hold on;
    p6 = plot(offsetAna, QuaDecodeProb_ShortSignal_Z2W(ith, :), 'Color', colorSpace(1, 3),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 3));
    hold on;

    p7 = plot(offsetSim, QuaDecodeAccur_LongSignal_Z2W(ith, :), 'Color', colorSpace(1, 4),...
        'Marker', markerSpace(1, 4), 'LineStyle', 'none');
    hold on;
    p8 = plot(offsetAna, QuaDecodeProb_LongSignal_Z2W(ith, :), 'Color', colorSpace(1, 4),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 4));
    hold on;

    jth = jth + 1;
end
hold off;
axis([min(offsetSim), max(offsetSim), 0, 1]);
xlabel('Sampling offset $$\Delta t$$ ($$\mu s$$)', 'Interpreter', 'latex');
ylabel({'Successful probability of'; 'detecting sample type'}, 'Interpreter','Latex')
legend([p1, p2, p3, p4, p5, p6, p7, p8],...
    'Short ACK (Z&B)', 'Short ACK * (Z&B)', 'Long ACK (Z&B)', 'Long ACK * (Z&B)',...
    'Short ACK (Z&W)', 'Short ACK * (Z&W)', 'Long ACK (Z&W)', 'Long ACK * (Z&W)',...
    'location', 'best', 'Interpreter','Latex');

% Plot correct ORS decoding probability versus sampling offset
figure;
jth = 1;
for ith = 1: 5: length(SNRStepSim)
    p1 = plot(offsetSim, ORSDecodeAccur_ShortSignal_Z2B(ith, :), 'Color', colorSpace(1, 1),...
        'Marker', markerSpace(1, 1), 'LineStyle', 'none');
    hold on;
    p2 = plot(offsetAna, ORSDecodeProb_ShortSignal_Z2B(ith, :), 'Color', colorSpace(1, 1),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 1));
    hold on;

    p3 = plot(offsetSim, ORSDecodeAccur_LongSignal_Z2B(ith, :), 'Color', colorSpace(1, 2),...
        'Marker', markerSpace(1, 2), 'LineStyle', 'none');
    hold on;
    p4 = plot(offsetAna, ORSDecodeProb_LongSignal_Z2B(ith, :), 'Color', colorSpace(1, 2),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 2));
    hold on;

    p5 = plot(offsetSim, ORSDecodeAccur_ShortSignal_Z2W(ith, :), 'Color', colorSpace(1, 3),...
        'Marker', markerSpace(1, 3), 'LineStyle', 'none');
    hold on;
    p6 = plot(offsetAna, ORSDecodeProb_ShortSignal_Z2W(ith, :), 'Color', colorSpace(1, 3),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 3));
    hold on;

    p7 = plot(offsetSim, ORSDecodeAccur_LongSignal_Z2W(ith, :), 'Color', colorSpace(1, 4),...
        'Marker', markerSpace(1, 4), 'LineStyle', 'none');
    hold on;
    p8 = plot(offsetAna, ORSDecodeProb_LongSignal_Z2W(ith, :), 'Color', colorSpace(1, 4),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 4));
    hold on;

    jth = jth + 1;
end
hold off;
axis([min(offsetSim), max(offsetSim), 0, 1]);
xlabel('Sampling offset $$\Delta t$$ ($$\mu s$$)', 'Interpreter', 'latex');
ylabel({'Successful probability of'; 'detecting ORS type'}, 'Interpreter','Latex')
legend([p1, p2, p3, p4, p5, p6, p7, p8],...
    'Short ACK (Z&B)', 'Short ACK * (Z&B)', 'Long ACK (Z&B)', 'Long ACK * (Z&B)',...
    'Short ACK (Z&W)', 'Short ACK * (Z&W)', 'Long ACK (Z&W)', 'Long ACK * (Z&W)',...
    'location', 'best', 'Interpreter','Latex');

% Plot correct ACK decoding probability versus sampling offset
figure;
jth = 1;
for ith = 1: 5: length(SNRStepSim)
    p1 = plot(offsetSim, ACKDecodeAccur_ShortSignal_Z2B(ith, :), 'Color', colorSpace(1, 1),...
        'Marker', markerSpace(1, 1), 'LineStyle', 'none');
    hold on;
    p2 = plot(offsetAna, ACKDecodeProb_ShortSignal_Z2B(ith, :), 'Color', colorSpace(1, 1),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 1));
    hold on;

    p3 = plot(offsetSim, ACKDecodeAccur_LongSignal_Z2B(ith, :), 'Color', colorSpace(1, 2),...
        'Marker', markerSpace(1, 2), 'LineStyle', 'none');
    hold on;
    p4 = plot(offsetAna, ACKDecodeProb_LongSignal_Z2B(ith, :), 'Color', colorSpace(1, 2),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 2));
    hold on;

    p5 = plot(offsetSim, ACKDecodeAccur_ShortSignal_Z2W(ith, :), 'Color', colorSpace(1, 3),...
        'Marker', markerSpace(1, 3), 'LineStyle', 'none');
    hold on;
    p6 = plot(offsetAna, ACKDecodeProb_ShortSignal_Z2W(ith, :), 'Color', colorSpace(1, 3),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 3));
    hold on;

    p7 = plot(offsetSim, ACKDecodeAccur_LongSignal_Z2W(ith, :), 'Color', colorSpace(1, 4),...
        'Marker', markerSpace(1, 4), 'LineStyle', 'none');
    hold on;
    p8 = plot(offsetAna, ACKDecodeProb_LongSignal_Z2W(ith, :), 'Color', colorSpace(1, 4),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 4));
    hold on;

    jth = jth + 1;
end
hold off;
axis([min(offsetSim), max(offsetSim), 0, 1]);
xlabel('Sampling offset $$\Delta t$$ ($$\mu s$$)', 'Interpreter', 'latex');
ylabel({'Successful probability $$P_{C3}(\Delta t)$$ of'; 'detecting ACK type'}, 'Interpreter','Latex')
legend([p1, p2, p3, p4, p5, p6, p7, p8],...
    'Short ACK (Z&B)', 'Short ACK * (Z&B)', 'Long ACK (Z&B)', 'Long ACK * (Z&B)',...
    'Short ACK (Z&W)', 'Short ACK * (Z&W)', 'Long ACK (Z&W)', 'Long ACK * (Z&W)',...
    'location', 'best', 'Interpreter','Latex');

% Plot succuessful ACK reception probability
figure;
plot(SNRStepSim, ACKReceptAccur_ShortSignal_Z2B(:, 1), 'Color', colorSpace(1, 1),...
    'Marker', markerSpace(1, 1), 'LineStyle', 'none', 'DisplayName', 'Short ACK (Z&B)');
hold on;
plot(SNRStepAna, ACKReceptProb_ShortSignal_Z2B(:, 1), 'Color', colorSpace(1, 1),...
    'Marker', 'none', 'LineStyle', lineSpace(1, 1), 'DisplayName', 'Short ACK * (Z&B)');
hold on;

plot(SNRStepSim, ACKReceptAccur_LongSignal_Z2B(:, 1), 'Color', colorSpace(1, 2),...
    'Marker', markerSpace(1, 2), 'LineStyle', 'none', 'DisplayName', 'Long ACK (Z&B)');
hold on;
plot(SNRStepAna, ACKReceptProb_LongSignal_Z2B(:, 1), 'Color', colorSpace(1, 2),...
    'Marker', 'none', 'LineStyle', lineSpace(1, 2), 'DisplayName', 'Long ACK * (Z&B)');
hold on;

plot(SNRStepSim, ACKReceptAccur_ShortSignal_Z2W(:, 1), 'Color', colorSpace(1, 3),...
    'Marker', markerSpace(1, 3), 'LineStyle', 'none', 'DisplayName', 'Short ACK (Z&W)');
hold on;
plot(SNRStepAna, ACKReceptProb_ShortSignal_Z2W(:, 1), 'Color', colorSpace(1, 3),...
    'Marker', 'none', 'LineStyle', lineSpace(1, 3), 'DisplayName', 'Short ACK * (Z&W)');
hold on;

plot(SNRStepSim, ACKReceptAccur_LongSignal_Z2W(:, 1), 'Color', colorSpace(1, 4),...
    'Marker', markerSpace(1, 4), 'LineStyle', 'none', 'DisplayName', 'Long ACK (Z&W)');
hold on;
plot(SNRStepAna, ACKReceptProb_LongSignal_Z2W(:, 1), 'Color', colorSpace(1, 4),...
    'Marker', 'none', 'LineStyle', lineSpace(1, 4), 'DisplayName', 'Long ACK * (Z&W)');
hold off;

axis([min(SNRStepSim), max(SNRStepSim), 0, 1]);
xlabel('SNR (dB)', 'Interpreter', 'latex');
ylabel('Successful ACK decoding probability $$P_{ACK}^{s}$$', 'Interpreter','Latex')
legend('location', 'best', 'Interpreter','Latex', 'FontSize', 8);

% Plot packet delivery overhead
figure;
jth = 1;
scaleFactor = 1000;
for ith = 1: 1: length(numSym)
    p1 = plot(SNRStepSim, overHeadSim_ShortSignal_Z2B(ith, :)./scaleFactor, 'Color', colorSpace(1, 1),...
        'Marker', markerSpace(1, 1), 'LineStyle', 'none');
    hold on;
    p2 = plot(SNRStepSim, overHeadAna_ShortSignal_Z2B(ith, :)./scaleFactor, 'Color', colorSpace(1, 1),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 1));
    hold on;

    p3 = plot(SNRStepSim, overHeadSim_LongSignal_Z2B(ith, :)./scaleFactor, 'Color', colorSpace(1, 2),...
        'Marker', markerSpace(1, 2), 'LineStyle', 'none');
    hold on;
    p4 = plot(SNRStepSim, overHeadAna_LongSignal_Z2B(ith, :)./scaleFactor, 'Color', colorSpace(1, 2),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 2));
    hold on;

    p5 = plot(SNRStepSim, overHeadSim_ShortSignal_Z2W(ith, :)./scaleFactor, 'Color', colorSpace(1, 3),...
        'Marker', markerSpace(1, 3), 'LineStyle', 'none');
    hold on;
    p6 = plot(SNRStepSim, overHeadAna_ShortSignal_Z2W(ith, :)./scaleFactor, 'Color', colorSpace(1, 3),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 3));
    hold on;

    p7 = plot(SNRStepSim, overHeadSim_LongSignal_Z2W(ith, :)./scaleFactor, 'Color', colorSpace(1, 4),...
        'Marker', markerSpace(1, 4), 'LineStyle', 'none');
    hold on;
    p8 = plot(SNRStepSim, overHeadAna_LongSignal_Z2W(ith, :)./scaleFactor, 'Color', colorSpace(1, 4),...
        'Marker', 'none', 'LineStyle', lineSpace(1, 4));
    hold on;

    jth = jth + 1;
end
hold off;
axis([min(dispSNR), max(dispSNR), 0, 30]);
xlabel('SNR (dB)', 'Interpreter', 'latex');
ylabel('Mean complete transmission time $$E(\Omega)$$ ($$\mu s$$)', 'Interpreter','Latex')
legend([p1, p2, p3, p4, p5, p6, p7, p8],...
    'Short ACK (Z&B)', 'Short ACK * (Z&B)', 'Long ACK (Z&B)', 'Long ACK * (Z&B)',...
    'Short ACK (Z&W)', 'Short ACK * (Z&W)', 'Long ACK (Z&W)', 'Long ACK * (Z&W)',...
    'location', 'best', 'Interpreter','Latex');
