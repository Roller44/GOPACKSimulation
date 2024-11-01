clear all
clc

% Frame duration
PreambleDur = 128;
SFDDur = 32;
SHRDur = PreambleDur + SFDDur;
PHRDur = 32;
HeaderDur = SHRDur + PHRDur;
num_sym = 50; % 25 bytes
PayloadDur = 16*num_sym;
SIFSDur = 12*16; % The length of a SIFS is equal to that of 16 symbols.
frameDur = HeaderDur + PayloadDur + SIFSDur;
ACKDur = 1*16;
Header = ones(1, 3); % We only require the receiver to successfully detect the last symbol of the preamble
Header(1, 2) = 15;
Header(1, 3) = 6;
BlueBeeMap = BlueBeeMapGenerator;

FRR = 0.55; % Frame reception rate.
SNR = 10: 2: 30;
Thg = zeros(3, length(SNR));
max_times = 1000;
%% WeBee
% ith = 1;
for ith = 1: length(SNR)
    disp(['Running BlueBee for the case where SNR=',num2str(SNR(1, ith)),'dB.']);
    % tx_times = 6;
    % tx_times = 0;
    num_crr_bits = 0;
    retx_times = 10;
    for jth = 1: 1: max_times
        txData = randi([1,16], 1, num_sym);
        txFrame = [Header txData];
        txWaveform = BlueBee(txFrame, BlueBeeMap);
        %         txWaveform = ZigBeeTx(txFrame);
        txWaveform = reshape(txWaveform, [1, length(txWaveform)]);
        crr_flag = 0;
        for kth = 1: 1: retx_times
            rxWaveform = awgn(txWaveform, SNR(1, ith), 'measured');
            rxFrame = OQPSKdemodulation3(rxWaveform, randi([-49,49],1,1));
            if sum(rxFrame==txFrame) == length(txFrame)
                crr_flag = 1;
            end
            % tx_times = tx_times + 1;
        end
        if crr_flag == 1
            num_crr_bits = num_crr_bits + 4*num_sym;
        end
    end
    Thg(1, ith) = num_crr_bits / (frameDur * retx_times * max_times);
    %     ith = ith + 1;
end

%% WeBee + Symbol-ACK
ACK_Threshold = 10;
ORP_Threshold = 0.6;
[mapMtrL, mapMtrR] = genMapMtr;
ACK_sym = [zeros(1, 8), 14, 5, 022, 10, ones(1, 10)] + 1;
ACKDur = length(ACK_sym) * 16;
txACKWaveform = ZigBeeTx(ACK_sym);
txACKWaveform = reshape(txACKWaveform, 1, length(txACKWaveform));
max_retx_times = 5;
% ith = 1;
for ith = 1: length(SNR)
    decode_accur = 0;
    disp(['Running BlueBee+XBee for the case where SNR=',num2str(SNR(1, ith)),'dB.']);
    tx_times = 0;
    retx_times_total = 0;
    num_crr_bits = 0;
    for jth = 1: 1: max_times
        retx_times = 0;
        txData = randi([1,16], 1, num_sym);
        txFrame = [Header txData];
        txWaveform = BlueBee(txFrame, BlueBeeMap);
        txWaveform = reshape(txWaveform, [1, length(txWaveform)]);
        crr_flag = 0;
        crr_ack = 0;
        while (retx_times <= max_retx_times)
            rxWaveform = awgn(txWaveform, SNR(1, ith), 'measured');
            rxFrame = OQPSKdemodulation3(rxWaveform, randi([-49,49],1,1));
            tx_times = tx_times + 1;
            if sum(rxFrame==txFrame) == length(txFrame)
                if crr_flag == 0
                    crr_flag = 1;
                    num_crr_bits = num_crr_bits + 4*num_sym;                    
                end
                rxACKWaveform = awgn(txACKWaveform, SNR(1, ith), 'measured');
                decode_accur = XBeeRX(txACKWaveform, randi([-49,49],1,1), mapMtrL, mapMtrR, ACK_sym);
                if decode_accur == 1
                    break;
                end
            else
                retx_times = retx_times + 1;
                retx_times_total = retx_times_total + 1;
            end
        end
    end
    Thg(2, ith) = num_crr_bits / ((frameDur+ACKDur)*retx_times_total + (frameDur)*(tx_times-retx_times_total));
    %     ith = ith + 1;
end

%% WeBee + Bit-level-ACK
ACK_Threshold = 10;
ORP_Threshold = 0.6;
[mapMtrL, mapMtrR] = genMapMtr;
ACK_sym = [zeros(1, 8), 14, 5, 022, 10, ones(1, 10)] + 1;
ACKDur = length(ACK_sym) * 16;
txACKWaveform = ZigBeeTx(ACK_sym);
txACKWaveform = reshape(txACKWaveform, 1, length(txACKWaveform));
max_retx_times = 5;
% ith = 1;
for ith = 1: length(SNR)
    decode_accur = 0;
    disp(['Running BlueBee+XBee for the case where SNR=',num2str(SNR(1, ith)),'dB.']);
    tx_times = 0;
    retx_times_total = 0;
    num_crr_bits = 0;
    for jth = 1: 1: max_times
        retx_times = 0;
        txData = randi([1,16], 1, num_sym);
        txFrame = [Header txData];
        txWaveform = BlueBee(txFrame, BlueBeeMap);
        txWaveform = reshape(txWaveform, [1, length(txWaveform)]);
        crr_flag = 0;
        crr_ack = 0;
        while (retx_times <= max_retx_times)
            rxWaveform = awgn(txWaveform, SNR(1, ith), 'measured');
            rxFrame = OQPSKdemodulation3(rxWaveform, randi([-49,49],1,1));
            tx_times = tx_times + 1;
            if sum(rxFrame==txFrame) == length(txFrame)
                if crr_flag == 0
                    crr_flag = 1;
                    num_crr_bits = num_crr_bits + 4*num_sym;                    
                end
                rxACKWaveform = awgn(txACKWaveform, SNR(1, ith), 'measured');
                decode_accur = XBeeRX(txACKWaveform, randi([-49,49],1,1), mapMtrL, mapMtrR, ACK_sym);
                if decode_accur == 1
                    break;
                end
            else
                retx_times = retx_times + 1;
                retx_times_total = retx_times_total + 1;
            end
        end
    end
    Thg(2, ith) = num_crr_bits / ((frameDur+ACKDur)*retx_times_total + (frameDur)*(tx_times-retx_times_total));
    %     ith = ith + 1;
end

%% WeBee + GRP-ACK
ACK_Threshold = 10;
ORP_Threshold = 0.6;
% ith = 1;
for ith = 1: length(SNR)
    disp(['Running BlueBee+GRP-ACK for the case where SNR=',num2str(SNR(1, ith)),'dB.']);
    max_retx_times = 5;
    tx_times = 0;
    retx_times_total = 0;
    num_crr_bits = 0;
    for jth = 1: 1: max_times
        retx_times = 0;
        txData = randi([1,16], 1, num_sym);
        txFrame = [Header txData];
        txWaveform = BlueBee(txFrame, BlueBeeMap);
        txWaveform = reshape(txWaveform, [1, length(txWaveform)]);
        crr_flag = 0;
        crr_ack = 0;
        while (retx_times <= max_retx_times)
            rxWaveform = awgn(txWaveform, SNR(1, ith), 'measured');
            rxFrame = OQPSKdemodulation3(rxWaveform, randi([-49,49],1,1));
            tx_times = tx_times + 1;
            if sum(rxFrame==txFrame) == length(txFrame)
                if crr_flag == 0
                    crr_flag = 1;
                    num_crr_bits = num_crr_bits + 4*num_sym;
                end
                if retx_times == 0
                    ACK_sym = 1; % Successful transmission
                else
                    ACK_sym = 3; % Successful retransmission
                end
            else
                if retx_times == 0
                    ACK_sym = 2; % Unsuccessful transmission
                else
                    ACK_sym = 4; % Unsccessful retransmission
                end
                retx_times = retx_times + 1;
                retx_times_total = retx_times_total + 1;
            end
            txACKWaveform = PHYOQPSK_ACKfeedback(ACK_sym);
            rxACKWaveform = awgn(txACKWaveform, SNR(1, ith), 'measured');
            [~, decode_accur] = AckDetection(rxACKWaveform, ACK_Threshold, ORP_Threshold, ACK_sym, randi([-49,49],1,1));
            if (ACK_sym==1||ACK_sym==3) && (decode_accur==1)
                break;
            end
        end
    end
    Thg(3, ith) = num_crr_bits / ((frameDur+ACKDur)*retx_times_total + frameDur*(tx_times-retx_times_total));
    %     ith = ith + 1;
end

%% Plot figures
Thg = Thg .* 10^6; % us -> s
Thg = Thg .* 10^(-3); % bps -> kbps
plot(SNR, Thg(1, :), '--*', 'linewidth', 1.5);
hold on;
plot(SNR, Thg(2, :), '-^', 'linewidth', 1.5);
hold on;
plot(SNR, Thg(3, :), '-o', 'linewidth', 1.5);
xlabel('SNR (dB)');
ylabel('Throughput (kbps)');
legend('Original BlueBee', 'BlueBee+XBee', 'BlueBee+GRP-ACK', 'location', 'northwest');