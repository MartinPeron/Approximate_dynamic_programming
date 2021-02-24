function feasibleActions = generate_actions(nSubActions, subActionCosts, ...
	SubActionsSoFar, nIslandRemaining, actionBalance, feasibleActions)

% recursive function to generate a list of actions for the bound models.

if nIslandRemaining == 0
% 	if actionBalance == 0    % added: only keep actions that spend entire budget
		feasibleActions = [feasibleActions; SubActionsSoFar];
% 	end
else
	for iSubAction = 1 : nSubActions
		nextActionBalance = actionBalance - subActionCosts(iSubAction);
		if nextActionBalance >= 0
			feasibleActions = generate_actions(nSubActions, subActionCosts, ...
				[SubActionsSoFar iSubAction], nIslandRemaining - 1, nextActionBalance, ...
					feasibleActions);
		end
	end
end


end