function waveform = bleWaveformGenerator(message,sps)
% Type cast sps, channelIndex to double, if not a float
if ~isfloat(sps)
    spsCastToDouble  = double(sps);
    
else
    spsCastToDouble = sps;
    
end

% Perform GMSK modulation on physical layer frame
waveform = gmskmod(double(message),spsCastToDouble);
end

