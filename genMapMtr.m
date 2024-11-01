function [mapMtrL, mapMtrR] = genMapMtr

mapMtrL = zeros(16, 16);
mapMtrR = zeros(16, 16);

[z,message]= ZigBeeMap;
sig = z;
len = size(z);
samples = zeros(1, 16*16);
ph = zeros(1, 16*16);
bits = zeros(1, 16*16);
nSamp = 32;
sn = zeros();

%% left mapping matrix
k = 1;
s(1,:) = 0;
for j = 33 - 2: nSamp: len - 2 %Left
    k = k + 1;
    sampleL(k, :) = sig(j, :);
end

for j = 2 :1 : length(sampleL)
    sn = sampleL(j, 1)*(conj(sampleL(j - 1, 1)));
    phL(j-1) = angle(sn);   %连续两个采样点之间的phase   atan
end
% Sig=reshape(ph,16,[]);%竖着看 每一列是一个symbol

for j = 1: 1: 256
    if phL(j) > 0
        bitsL(j) = 1;
    else
        bitsL(j) = 0;
    end
end
mapMtrL = reshape(bitsL,16,[]); %竖着

%% right mapping matrix
kk = 1;
for j = 1 + 2: nSamp: len + 2  % Right
    sampleR(kk, :) = z(j, :);%s是一列 采样后的sample
    kk = kk + 1;
end

for j = 2 :1 : length(sampleR)
    sn = sampleR(j, 1)*(conj(sampleR(j - 1, 1)));
    phR(j - 1) = angle(sn);   %连续两个采样点之间的phase    atan
end

for j = 1: 1: 256
    if phR(j) > 0
        bitsR(j) = 1;
    else
        bitsR(j) = 0;
    end
end
mapMtrR = reshape(bitsR,16,[]);

end




