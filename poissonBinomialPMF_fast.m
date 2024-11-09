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