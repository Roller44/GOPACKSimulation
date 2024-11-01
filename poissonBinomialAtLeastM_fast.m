
function [cdf_complement] = poissonBinomialAtLeastM_fast(probabilities, M)
    % Calculate probability of at least M successes using fast method
    % Input: probabilities - vector of individual probabilities
    %        M - minimum number of successes required
    % Output: cdf_complement - P(X >= M)

    function [pmf] = poissonBinomialPMF_fast(probabilities)
        % Calculate PMF for Poisson binomial distribution using FFT method
        % Input: probabilities - vector of individual probabilities
        % Output: pmf - probability mass function for 0 to N successes
        
        N = length(probabilities);
        
        % Use FFT method
        % Convert probabilities to complex numbers on the unit circle
        omega = 2 * pi / (N + 1);
        t = exp(1i * omega);
        
        % Calculate characteristic function
        z = zeros(1, N + 1);
        parfor k = 0:N
            tk = t^k;
            z(k + 1) = prod(1 - probabilities + probabilities * tk);
        end
        
        % Use FFT to get PMF
        pmf = real(ifft(z)) / (N + 1);
        
        % Clean up numerical errors
        pmf = max(0, pmf);  % Remove negative values due to numerical errors
        pmf = pmf / sum(pmf);  % Normalize to ensure sum is 1
    end
    
    pmf = poissonBinomialPMF_fast(probabilities);
    cdf_complement = sum(pmf(M+1:end));
end

% Example usage:
% N = 100;  % try with larger number of samples
% probs = rand(1, N);  % random probabilities
% M = 50;  % we want at least 50 successes
% 
% tic
% prob_at_least_M = poissonBinomialAtLeastM_fast(probs, M);
% toc
% 
% fprintf('Probability of at least %d successes: %.4f\n', M, prob_at_least_M);