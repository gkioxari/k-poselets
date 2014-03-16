function [w, bias] = svm_solver_train(y, X, C, ub, w_and_bias, lbfgs_opts)
% [w, bias] = svm_solver_train(y, X, C, [ub, w_and_bias, lbfgs_opts]);
%
% Inputs
%  y          [m x 1] vector of training labels (1 or -1)
%  X          [m x f] matrix of m training instance with f features
%  C          SVM regularization tradeoff
%  ub         (optional) [f x 1] vector of upper bound range constrains
%             for the weights; use -inf for no upper bound
%  w_and_bias (optional) [f+1 x 1] vector for warm starting
%  lbfgs_opts (optional) options to pass to minConf's lbfgs implementation
%
% Output
%  w          [f x 1] weight vector
%  bias       bias
%  
%  The decision function for [f x 1] vector x is sign(w'*x + bias).

% bias multiplier
B = 10;

% check for warm start
if ~exist('w_and_bias', 'var') || isempty(w_and_bias)
  % initialize to zero and bias of -1
  w = zeros(size(X,1)+1, 1);
else
  % use warm start
  w = w_and_bias;
  w(end) = w(end)/B;
end

% set upper bounds to inf if not given
if ~exist('ub', 'var') || isempty(ub)
  ub = inf(size(w));
else
  % assume upper bounds are given for weights only,
  % so add one dimension for the bias
  ub = [ub; inf];
end
% set lower bounds to -inf
lb =  -inf(size(w));

% options for lbfgs
if ~exist('lbfgs_opts', 'var') || isempty(lbfgs_opts)
  lbfgs_opts.verbose = 2;
  lbfgs_opts.maxIter = 1000;
  lbfgs_opts.optTol  = 0.000001;
end

% run optimizer
obj_func = @(w_) svm_obj_func(w_, y, X, B, C);
w = minConf_TMP(obj_func, w, lb, ub, lbfgs_opts);

% parse output into weight vector and bias
bias = w(end)*B;
w = w(1:end-1);


% ------------------------------------------------------------------------
function [v, g] = svm_obj_func(w, y, X, B, C)
% ------------------------------------------------------------------------

z = y'.*(w(1:end-1)'*X + B*w(end));

loss = max(0, 1 - z);
I = find(loss > 0);


g = C .* [-X(:,I)*y(I); -B*sum(y(I))];

%g = C .* sum(bsxfun(@times, [X(I,:) B*ones(length(I), 1)], -y(I)), 1)';
g(1:end-1) = g(1:end-1) + w(1:end-1);

v = C * sum(loss) + 0.5 * w(1:end-1)'*w(1:end-1);
