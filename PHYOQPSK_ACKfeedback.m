function txWaveform = PHYOQPSK_ACKfeedback(messages, numORS, lenType, RXType)

OSR = 100;

oddChipMap = [1; 0; 0; 1; 1/2; 0];
evenChipMap = [1; 1; 0; 0; 1/2; 0];

alpha = 4; % Number of basic signal unit.

numMsg = size(messages, 1);
if isequal(lenType, 'short')
    if isequal(RXType, 'BLE')
        numOddChips = numORS + 2;
        numEvenChips = numORS + 1;
    else
        numOddChips = (numORS + 1) .* alpha + 1;
        numEvenChips = (numORS + 1) .* alpha;
    end
else
    if isequal(RXType, 'BLE')
        numOddChips = 2 .* numORS + 1;
        numEvenChips = 2 .* numORS;
    else
        numOddChips = 2 .* numORS .* alpha + 1;
        numEvenChips = 2 .* numORS .* alpha;
    end
end
% oddChips = zeros(numMsg, numOddChips);
% evenChips = zeros(numMsg, numEvenChips);
% for ith = 1: 1: numMsg
%     if messages(ith, 1) == 6
%         oddChips(ith, :) = randi([0, 1], 1, numOddChips) .* 2 - 1;
%         evenChips(ith, :) = randi([0, 1], 1, numEvenChips) .* 2 - 1;
%     else
%         oddChips(ith, :) = repmat(oddChipMap(messages(ith, 1), :), 1, numOddChips) .* 2 - 1;
%         evenChips(ith, :) = repmat(evenChipMap(messages(ith, 1), :), 1, numEvenChips) .* 2 - 1;
%     end
% end

oddChips = repmat(oddChipMap(messages(:, 1)), 1, numOddChips) .* 2 - 1;
evenChips = repmat(evenChipMap(messages(:, 1)), 1, numEvenChips) .* 2 - 1;
if isempty(find(messages==6)) == 0
    numRandMsg = size(find(messages==6), 1);
    oddChips(find(messages==6), :) = randi([0, 1], numRandMsg, numOddChips) .* 2 - 1;
    evenChips(find(messages==6), :) = randi([0, 1], numRandMsg, numEvenChips) .* 2 - 1;
end

pulse = sin(0:pi/OSR:(OSR-1)*pi/OSR); % Half-period sine wave
signalLen = OSR + OSR .* numOddChips + OSR;
txWaveform = zeros(numMsg, signalLen);
for ith = 1: 1: numMsg

    filteredReal = pulse' * oddChips(ith, :);     % each column is now a filtered pulse
    filteredImag = pulse' * evenChips(ith, :);    % each column is now a filtered pulse

    re = filteredReal(:);
    im = [zeros(round(OSR/2), 1);  filteredImag(:); zeros(round(OSR/2), 1)];
    waveform = complex(re, im);
    [num_smpl, ~] = size(waveform);
    txWaveform(ith, :) = [zeros(1, OSR), reshape(waveform, [1, num_smpl]), zeros(1, OSR)];
%     figure;
%     subplot(2, 1, 1);
%     plot(real(txWaveform(ith, :)));
%     hold on;
%     subplot(2, 1, 2);
%     plot(imag(txWaveform(ith, :))); 
end

end