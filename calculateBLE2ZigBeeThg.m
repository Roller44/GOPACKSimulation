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
frameDur = HeaderDur + PayloadDur;
Header = ones(1, 3); % We only require the receiver to successfully detect the last symbol of the preamble
Header(1, 2) = 15;
Header(1, 3) = 6;
BlueBeeMap = BlueBeeMapGenerator;

SNR = 0: 5: 20;
Thg = zeros(3, length(SNR));
num_crr_bits = zeros(3, length(SNR));
num_crr_pkts = zeros(3, length(SNR));
overvall_mu_second = zeros(3, length(SNR));
ack_times = zeros(3, length(SNR));
ack_timeout_times = zeros(3, length(SNR));
tx_times = zeros(3, length(SNR));
max_times = 10^4; %5*10^5;
%% BlueBee
% ith = 1;
parfor ith = 1: length(SNR)
    disp(['Running BlueBee for the case where SNR=',num2str(SNR(1, ith)),'dB.']);
    retx_times = 20;
    for jth = 1: 1: max_times
        txData = randi([1,16], 1, num_sym);
        txFrame = [Header txData];
        txWaveform = BlueBee(txFrame, BlueBeeMap);
        txWaveform = reshape(txWaveform, [1, length(txWaveform)]);
        crr_flag = 0;
        for kth = 1: 1: retx_times
            rxWaveform = awgn(txWaveform, SNR(1, ith), 'measured');
            rxFrame = OQPSKdemodulation3(rxWaveform, randi([-49,49],1,1));
            if (sum(rxFrame==txFrame) == length(txFrame))
                num_crr_pkts(1, ith) = num_crr_pkts(1, ith) + 1;
            end
            if (sum(rxFrame==txFrame) == length(txFrame)) && (crr_flag == 0)
                crr_flag = 1;
                num_crr_bits(1, ith) = num_crr_bits(1, ith) + 4*num_sym;
            end
        end
    end
    overvall_mu_second(1, ith) = (frameDur + SIFSDur) * retx_times * max_times;
end

%% BlueBee + XBee
[mapMtrL, mapMtrR] = genMapMtr;
ACK_sym = [zeros(1, 8), 14, 5, 0, 2, 2, 10, ones(1, 10)] + 1;
ACKDur = length(ACK_sym) * 16 + SIFSDur;
ACKTimeoutDur = length(ACK_sym) * 16 + SIFSDur;
txACKWaveform = ZigBeeTx(ACK_sym);
txACKWaveform = reshape(txACKWaveform, 1, length(txACKWaveform));
max_retx_times = 6;
parfor ith = 1: length(SNR)
    disp(['Running BlueBee+XBee for the case where SNR=',num2str(SNR(1, ith)),'dB.']);
    for jth = 1: 1: max_times
        decode_accur = 0;
        txData = randi([1,16], 1, num_sym);
        txFrame = [Header txData];
        txWaveform = BlueBee(txFrame, BlueBeeMap);
        txWaveform = reshape(txWaveform, [1, length(txWaveform)]);
        crr_flag = 0;
        for retx_times = 0: 1: max_retx_times
            rxWaveform = awgn(txWaveform, SNR(1, ith), 'measured');
            rxFrame = OQPSKdemodulation3(rxWaveform, randi([-49,49],1,1));
            tx_times(2, ith) = tx_times(2, ith) + 1;
            if sum(rxFrame==txFrame) == length(txFrame)
                num_crr_pkts(2, ith) = num_crr_pkts(2, ith) + 1;
                if crr_flag == 0
                    crr_flag = 1;
                    num_crr_bits(2, ith) = num_crr_bits(2, ith) + 4*num_sym;                    
                end
                rxACKWaveform = awgn(txACKWaveform, SNR(1, ith), 'measured');
                ack_times(2, ith) = ack_times(2, ith) + 1;
                decode_accur = XBeeRX(rxACKWaveform, randi([-49,49],1,1), mapMtrL, mapMtrR, ACK_sym);
            else
                ack_timeout_times(2, ith) = ack_timeout_times(2, ith) + 1;
            end
            if decode_accur == 1
                break;
            end
        end
    end
    overvall_mu_second(2, ith) = ACKDur*ack_times(2, ith) + (frameDur)*tx_times(2, ith) +ACKTimeoutDur*ack_timeout_times(2, ith);
end

%% BlueBee + GOP-ACK
settings.ACK_Threshold = 10;
settings.ORS_Threshold = 0.6;
settings.offset.isRandom = 1;
settings.offset.offsetValue = 0;
max_retx_times = 6;
ACKDur = 1*16;
for ith = 1: length(SNR)
    disp(['Running BlueBee+GOP-ACK for the case where SNR=',num2str(SNR(1, ith)),'dB.']);
    for jth = 1: 1: max_times
        txData = randi([1,16], 1, num_sym);
        txFrame = [Header txData];
        txWaveform = BlueBee(txFrame, BlueBeeMap);
        txWaveform = reshape(txWaveform, [1, length(txWaveform)]);
        crr_flag = 0;
        crr_ack = 0;
        for retx_times = 0: 1: max_retx_times
            rxWaveform = awgn(txWaveform, SNR(1, ith), 'measured');
            rxFrame = OQPSKdemodulation3(rxWaveform, randi([-49,49],1,1));
            tx_times(3, ith) = tx_times(3, ith) + 1;
            if sum(rxFrame==txFrame) == length(txFrame)
                num_crr_pkts(3, ith) = num_crr_pkts(3, ith) + 1;
                if crr_flag == 0
                    crr_flag = 1;
                    num_crr_bits(3, ith) = num_crr_bits(3, ith) + 4*num_sym;
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
            end
            settings.messages = ACK_sym;
            txACKWaveform = PHYOQPSK_ACKfeedback(ACK_sym);
            rxACKWaveform = awgn(txACKWaveform, SNR(1, ith), 'measured');
            settings.rxWaveform = rxACKWaveform;
            ack_times(3, ith) = ack_times(3, ith) + 1;
            [~, ~, decode_accur] = AckDetection(settings);
            if (ACK_sym==1||ACK_sym==3) && (decode_accur==1)
                break;
            end
        end
    end
    overvall_mu_second(3, ith) = ACKDur*ack_times(3, ith) + frameDur*tx_times(3, ith);
end

num_crr_kbits = num_crr_bits ./ (10^3); % bits -> kbits
overvall_seconds = overvall_mu_second ./ (10^6); % us -> s
Thg = num_crr_kbits ./ overvall_seconds;

%% Plot figures
% Thg = Thg .* 10^6; % us -> s
% Thg = Thg .* 10^(-3); % bps -> kbps
plot(SNR, Thg(1, :), '--*', 'linewidth', 1.5);
hold on;
plot(SNR, Thg(2, :), '-^', 'linewidth', 1.5);
hold on;
plot(SNR, Thg(3, :), '-o', 'linewidth', 1.5);
xlabel('SNR (dB)');
ylabel('System throughput (kbps)');
legend('Original BlueBee', 'BlueBee+XBee', 'BlueBee+GOP-ACK', 'location', 'southeast');