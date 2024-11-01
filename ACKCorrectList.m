function ACKCorrectCases = ACKCorrectList(numORS)
    %{
        This function list all the cases of ACK type detection. 
        The i-th row of the output represents the i-th possible detection case. 
        In this row, the j-th column indicates the number of ORS sampling
        instances fall into the j-th quadrant.

        In calculation of model, we focus on the case where type-1 ACK is
        transmitted. Thus, the list only contain the case where samples
        fall in the first quadrant are the most.

        Input:
            numORS: Number of ORSs belonging to each ACK signal.
    %}
    disp('Listing ACKCorrectCases...');
    ACKCorrectCases = [];
    for numQ1 = 0: 1: numORS
        for numQ2 = 0: 1: (numORS-numQ1)
            for numQ3 = 0: 1: (numORS-numQ1-numQ2)
                numQ4 = numORS - numQ3 - numQ2 - numQ1;
                if (numQ1>=numQ2) && (numQ1>=numQ3) && (numQ1>=numQ4)
                    % Only consider the case where samples fall in the first quadrant are the most.
                    ACKCorrectCases = [ACKCorrectCases; [numQ1, numQ2, numQ3, numQ4]];
                end
            end
        end
    end
    disp('Done.');
end