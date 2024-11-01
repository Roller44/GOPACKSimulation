function z = ZigBeeTx(sym)   
  % See Table 73 in IEEE 802.15.4,  2011 revision
  chipMap = ...
     [1 1 0 1 1 0 0 1 1 1 0 0 0 0 1 1 0 1 0 1 0 0 1 0 0 0 1 0 1 1 1 0;
      1 1 1 0 1 1 0 1 1 0 0 1 1 1 0 0 0 0 1 1 0 1 0 1 0 0 1 0 0 0 1 0;
      0 0 1 0 1 1 1 0 1 1 0 1 1 0 0 1 1 1 0 0 0 0 1 1 0 1 0 1 0 0 1 0;
      0 0 1 0 0 0 1 0 1 1 1 0 1 1 0 1 1 0 0 1 1 1 0 0 0 0 1 1 0 1 0 1;
      0 1 0 1 0 0 1 0 0 0 1 0 1 1 1 0 1 1 0 1 1 0 0 1 1 1 0 0 0 0 1 1;
      0 0 1 1 0 1 0 1 0 0 1 0 0 0 1 0 1 1 1 0 1 1 0 1 1 0 0 1 1 1 0 0;
      1 1 0 0 0 0 1 1 0 1 0 1 0 0 1 0 0 0 1 0 1 1 1 0 1 1 0 1 1 0 0 1;
      1 0 0 1 1 1 0 0 0 0 1 1 0 1 0 1 0 0 1 0 0 0 1 0 1 1 1 0 1 1 0 1;
      1 0 0 0 1 1 0 0 1 0 0 1 0 1 1 0 0 0 0 0 0 1 1 1 0 1 1 1 1 0 1 1;
      1 0 1 1 1 0 0 0 1 1 0 0 1 0 0 1 0 1 1 0 0 0 0 0 0 1 1 1 0 1 1 1;
      0 1 1 1 1 0 1 1 1 0 0 0 1 1 0 0 1 0 0 1 0 1 1 0 0 0 0 0 0 1 1 1;
      0 1 1 1 0 1 1 1 1 0 1 1 1 0 0 0 1 1 0 0 1 0 0 1 0 1 1 0 0 0 0 0;
      0 0 0 0 0 1 1 1 0 1 1 1 1 0 1 1 1 0 0 0 1 1 0 0 1 0 0 1 0 1 1 0;
      0 1 1 0 0 0 0 0 0 1 1 1 0 1 1 1 1 0 1 1 1 0 0 0 1 1 0 0 1 0 0 1;
      1 0 0 1 0 1 1 0 0 0 0 0 0 1 1 1 0 1 1 1 1 0 1 1 1 0 0 0 1 1 0 0;
      1 1 0 0 1 0 0 1 0 1 1 0 0 0 0 0 0 1 1 1 0 1 1 1 1 0 1 1 1 0 0 0];

%% O-QPSK modululation (part 1)
% split two 2 parallel streams, also map [0, 1] to [-1, 1]
chips = [];
for ith = 1: 1: length(sym)
    chips = [chips, chipMap(sym(1,ith), :)];
end
% chips = repmat(chips, 1, 3);
oddChips  = chips(1, 1: 2: end) * 2 - 1;
evenChips = chips(1, 2: 2: end) * 2 - 1;
%% Filtering
  % Half-sine pulse filtering for 2450 MHz
  OSR = 100;
  pulse = sin(0: pi/OSR: (OSR - 1) * pi / OSR); % Half-period sine wave
  filteredReal = pulse' .* oddChips;     % each column is now a filtered pulse
  filteredImag = pulse' .* evenChips;    % each column is now a filtered pulse  
%% O-QPSK modululation (part 2)
re = [filteredReal(:);         zeros(round(OSR/2), 1)];
im = [zeros(round(OSR/2), 1);  filteredImag(:)];
z = [zeros(OSR,1); complex(re, im); zeros(OSR,1)];
% figure;
% plot(re);
% hold on;
% plot(im);
% hold on;
% legend('real', 'image');
% hold on;