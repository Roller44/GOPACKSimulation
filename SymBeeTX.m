function txWaveform = SymBeeTX(ACKMessage)

msg = [];
for ith = 1: 1: length(ACKMessage)
    if ACKMessage(1, ith) == 0
        % It is "6, 7" but the array starts at 1.
        msg = [msg, 7, 8];
    else
        % It is "E, F" but the array starts at 1.
        msg = [msg, 15, 16];
    end
end

txWaveform = ZigBeeTx(msg);
end