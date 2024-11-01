clear;
clc;

y = RegularizedIncompleteBetaFun(1, 2, 0);

function y = RegularizedIncompleteBetaFun(a, b, upper)
    betaFun = @(t) t^(a-1) .* (1-t).^(b-1);
    y = integral(betaFun, 0, upper) ./ beta(a, b);
end