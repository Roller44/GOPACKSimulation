numSamples = 16;
ORSCorrectCases = [];
for numQ1 = 0: 1: numSamples
    for numQ2 = 0: 1: (numSamples-numQ1)
        for numQ3 = 0: 1: (numSamples-numQ1-numQ2)
            numQ4 = numSamples - numQ3 - numQ2 - numQ1;
            if (numQ1>=numQ2) && (numQ1>=numQ3) && (numQ1>=numQ4)
                % Only consider the case where samples fall in the first quadrant are the most.
                ORSCorrectCases = [ORSCorrectCases; [numQ1, numQ2, numQ3, numQ4]];
            end
        end
    end
end