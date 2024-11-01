function [pmf] = poissonBinomialPMF(probabilities)
    % Calculate probability mass function (PMF) for Poisson binomial distribution
    % Input: probabilities - vector of individual probabilities
    % Output: pmf - probability mass function for 0 to N successes
    
    N = length(probabilities);
    pmf = zeros(1, N+1);
    
    % For each possible number of successes (0 to N)
    for m = 0:N
        % Get all possible combinations of m items from N items
        combinations = nchoosek(1:N, m);
        
        % If m is 0, handle separately
        if m == 0
            pmf(1) = prod(1 - probabilities);
            continue;
        end
        
        % Calculate probability for each combination
        probSum = 0;
        for ith = 1:size(combinations, 1)
            subset = combinations(ith, :);
            
            % Initialize probability for this combination
            tmpProb = 1;
            
            % Multiply probabilities for selected indices
            for jth = 1:N
                if ismember(jth, subset)
                    tmpProb = tmpProb * probabilities(jth);
                else
                    tmpProb = tmpProb * (1 - probabilities(jth));
                end
            end
            
            probSum = probSum + tmpProb;
        end
        
        pmf(m+1) = probSum;
    end
end

% Example usage:
% N = 4;  % total samples
% probs = [0.7, 0.3, 0.5, 0.8];  % individual probabilities
% pmf = poissonBinomialPMF(probs);
% 
% % Plot the distribution
% figure;
% bar(0:length(probs), pmf);
% xlabel('Number of successes');
% ylabel('Probability');
% title('Poisson Binomial Distribution');
% grid on;

