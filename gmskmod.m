function y = gmskmod(x,sps)
%GMSKMOD Gaussian Minimum shift keying modulation
%
%   Note: This is an internal undocumented function and its API and/or
%   functionality may change in subsequent releases.
%
%   Y = gmskmod(X,SPS) modulates the message signal X using Gaussian
%   minimum shift keying modulation. The elements of X must be 0 or 1.
%   SPS denotes the number of samples per symbol and must be a positive
%   integer.

%   Copyright 2018 The MathWorks, Inc.

%#codegen

% Parameters to generate the frequency pulse
h = 0.5;            % Modulation index
btProd = 0.5;       % Bandwidth-Time product
pulseLength = 1;    % Gaussian pulse length

% Generate the frequency pulse
q = gmskmodparams(btProd,pulseLength,sps);

% Calculate the initial phase
data = kron(double(x), ones(sps, 1));
ScaledData = h.*(2*data-1);
nSym = size(x,1);
oldPhase = coder.nullcopy(zeros(1,nSym+1));
phi = coder.nullcopy(zeros(1,nSym*sps));
oldPhase(1) = 0;

% Calculate the phase of data signal
for i = 1:nSym
    currentPhase = fliplr(ScaledData((i-pulseLength)*sps+1:i*sps)).*q;
    phi((i-pulseLength)*sps+1:i*sps) = oldPhase(i)+currentPhase;
    oldPhase_vec = sum(ScaledData(1:sps*(i-pulseLength+1)));
    oldPhase(i+1) = (0.5/sps)*oldPhase_vec;
end
phi = [0 phi(1:end-1)];
phi = 2*pi*phi;
sig = exp(1i*phi);

% Truncate the signal generated by the prehistory
y = sig(1:end).';
end

% Compute the parameters to generate a Gaussian pulse 
function q = gmskmodparams(Bb,L,N)
%   Generation of g (frequency transition pulse shape). g is generated so
%   that it compensates for the error that results from integration of
%   samples (as compared to integration of a continuous fcn) for low values
%   of N, the closed form for g is evaluated for all values on a fine time
%   line.  These values are collected into groups of R_up and averaged,
%   creating a warped version of g, g_wrap, that, when integrated, creates
%   a q that is within about 0.01% of the correct value for q (using a
%   min_oversample value of 64).

min_os_ratio = 64;
R_up = ceil(min_os_ratio/N); % Upsampling ratio for pulse shape estimation
tSym = 1;                % Notional symbol period
Ts   = tSym/(N*R_up);    % Notional oversampling period
Offset = Ts/2;           % Ts/2 (Trapezoidal integration rule)

% fine-grained time index for generating g to create
t = (Offset:Ts:L*tSym-Ts+Offset)';
K = 2*pi*Bb/sqrt(log(2));
t = t-tSym*(L/2); % Offset to pulse center
g = (1/(2*tSym))*(qfun((K*(t-tSym/2))) - qfun((K*(t+tSym/2))));
q = Ts*cumsum(g);
g = g*0.5/q(end); % Normalize so that the total phase transition is 0.5
g_wrap = mean(reshape(g,R_up,size(g,1)*size(g,2)/R_up),1)';
g = Ts*R_up*g_wrap;
q = cumsum(g);
end

function y = qfun(t)
    y = 0.5*(1-erf(t/sqrt(2)));
end