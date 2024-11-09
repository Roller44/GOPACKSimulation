% Parameters
K = 5;  % Number of sampling instances (adjust as needed)
j_star = 1;  % Correct quadrant (assumed to be 1)

% Define the probabilities p_k^j for each sampling instance k
% p is a K x 4 matrix where p(k, j) is the probability of sampling quadrant j at instance k
% Example: Varying probabilities for illustration
p = [ % p_k^1, p_k^2, p_k^3, p_k^4
    0.6, 0.2, 0.1, 0.1;
    0.5, 0.3, 0.1, 0.1;
    0.7, 0.1, 0.1, 0.1;
    0.4, 0.4, 0.1, 0.1;
    0.8, 0.05, 0.1, 0.05
    % Add more rows if K > 5
];

% Initialize the probability table
% Since counts can range from 0 to K for each L_j, we need (K+1) x (K+1) x (K+1) x (K+1) array
% To save memory, we'll use a sparse representation or a map to store only non-zero probabilities

% Use a map to store probabilities with state (L1, L2, L3, L4) as key
prev_probs = containers.Map();  % Probabilities after processing k-1 instances
prev_probs('0,0,0,0') = 1;      % Initial state

% Iterate over sampling instances
for k = 1:K
    curr_probs = containers.Map();  % Probabilities after processing k instances
    keys = prev_probs.keys();       % Get all states from previous step
    for idx = 1:length(keys)
        key = keys{idx};
        counts = sscanf(key, '%d,%d,%d,%d')';
        L1 = counts(1); L2 = counts(2); L3 = counts(3); L4 = counts(4);
        prev_prob = prev_probs(key);
        
        % Iterate over possible quadrants
        for j = 1:4
            % Update counts
            counts_new = counts;
            counts_new(j) = counts_new(j) + 1;
            % Check if counts are within limits
            if all(counts_new <= K)
                % Update probability
                prob = prev_prob * p(k, j);
                % Create new key
                key_new = sprintf('%d,%d,%d,%d', counts_new(1), counts_new(2), counts_new(3), counts_new(4));
                % Accumulate probability
                if isKey(curr_probs, key_new)
                    curr_probs(key_new) = curr_probs(key_new) + prob;
                else
                    curr_probs(key_new) = prob;
                end
            end
        end
    end
    % Move to next instance
    prev_probs = curr_probs;
end

% Compute total successful detection probability
total_probability = 0;
keys = prev_probs.keys();
for idx = 1:length(keys)
    key = keys{idx};
    counts = sscanf(key, '%d,%d,%d,%d')';
    L1 = counts(1); L2 = counts(2); L3 = counts(3); L4 = counts(4);
    % Check if counts sum to K
    if sum(counts) == K
        % Check if L1 > max(L2, L3, L4)
        if L1 > max([L2, L3, L4])
            prob = prev_probs(key);
            total_probability = total_probability + prob;
        end
    end
end

fprintf('Exact successful detection probability for K = %d: %.6f\n', K, total_probability);