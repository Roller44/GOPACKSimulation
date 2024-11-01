function txWaveform = BlueBee(messages, BlueBeeMap)

% BlueBeeMap = ...
%      [1 1 0 0 0 0 0 0 1 1 0 0 0 0 1 1 1 1 0 0 0 0 0 0 0 0 0 0 1 1 0 0;
%       1 1 0 0 1 1 0 0 0 0 0 0 1 1 0 0 0 0 1 1 1 1 0 0 0 0 0 0 0 0 0 0;
%       0 0 0 0 1 1 0 0 1 1 0 0 0 0 0 0 1 1 0 0 0 0 1 1 1 1 0 0 0 0 0 0;
%       0 0 0 0 0 0 0 0 1 1 0 0 1 1 0 0 0 0 0 0 1 1 0 0 0 0 1 1 1 1 0 0;
%       1 1 0 0 0 0 0 0 0 0 0 0 1 1 0 0 1 1 0 0 0 0 0 0 1 1 0 0 0 0 1 1;
%       0 0 1 1 1 1 1 1 0 0 0 0 0 0 0 0 1 1 1 1 1 1 0 0 1 1 1 1 1 1 0 0;
%       1 1 0 0 0 0 1 1 1 1 0 0 0 0 0 0 0 0 0 0 1 1 0 0 1 1 0 0 0 0 0 0;
%       0 0 0 0 1 1 0 0 0 0 1 1 1 1 0 0 0 0 0 0 0 0 0 0 1 1 0 0 1 1 0 0;
%       0 0 0 0 1 1 0 0 0 0 0 0 0 0 1 1 0 0 0 0 1 1 1 1 0 0 1 1 0 0 1 1;
%       0 0 1 1 0 0 0 0 1 1 0 0 0 0 0 0 0 0 1 1 0 0 0 0 1 1 1 1 0 0 1 1;
%       0 0 1 1 0 0 1 1 0 0 0 0 1 1 0 0 0 0 0 0 0 0 1 1 0 0 0 0 1 1 1 1;
%       1 1 1 1 0 0 1 1 0 0 1 1 0 0 0 0 1 1 0 0 0 0 0 0 0 0 1 1 0 0 0 0;
%       0 0 0 0 1 1 1 1 0 0 1 1 0 0 1 1 0 0 0 0 1 1 0 0 0 0 0 0 0 0 1 1;
%       0 0 1 1 0 0 0 0 1 1 1 1 0 0 1 1 0 0 1 1 0 0 0 0 1 1 0 0 0 0 0 0;
%       0 0 0 0 0 0 1 1 0 0 0 0 1 1 1 1 0 0 1 1 0 0 1 1 0 0 0 0 1 1 0 0;
%       1 1 0 0 0 0 0 0 0 0 1 1 0 0 0 0 1 1 1 1 0 0 1 1 0 0 1 1 0 0 0 0];

num_msg = length(messages);
chips = zeros(1, 16 * num_msg);
for ith = 1: 1: num_msg
   chips(1, 16*(ith-1)+1: 16*(ith)) = BlueBeeMap(messages(1,ith),:);
end

% BLEBits = chips(1:2:end);
sps = 100;
txWaveform = bleWaveformGenerator(chips',sps);
[num_smpl, ~] = size(txWaveform);
txWaveform = [zeros(1, sps), reshape(txWaveform, [1, num_smpl]), zeros(1, sps)];
% plot(real(txWaveform));
% hold on;
% plot(imag(txWaveform));
end