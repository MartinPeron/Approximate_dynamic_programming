function feasibleActions = calculate_feasible_actions(maxBudget, nSubActions, nNodes)


% if input variable "feasibleActions" is a scalar then it is the maximum 
% number of sub-actions #2 that can be implemented
% at the same time, e.g. a budget. 
if nSubActions > 2
	errortxt = 'Only up to two sub-actions are allowed if feasibleActions is a scalar. ';
	errortxt2 = 'Please modify infestationProba or feasibleActions.';
	error([errortxt errortxt2]);
end
feasibleActions = ones(1, nNodes);  % corresponds to budget 0 (action 1 everywhere)
for budget = 1 : maxBudget    % j is the # of nodes managed with sub-action #2
	tempFeasibleActions = ones(nchoosek(nNodes, budget), nNodes);  % initialise matrix
	indices = nchoosek(1:nNodes, budget);  % find indices of nodes managed with sub-action #2
	for action = 1 : nchoosek(nNodes, budget)
		tempFeasibleActions(action, indices(action, :)) = 2;  % fill matrix
	end
	feasibleActions = [feasibleActions; tempFeasibleActions];  % concatenate for diff. budgets
end
	


end