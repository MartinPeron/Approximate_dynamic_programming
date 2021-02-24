function [parameters, bestAction, maxActionValue] = solve_Continuous(parameters, initialStates)

%% Select best action online by assuming action cannot change in the future, and with 
% continuous states.
	
% Load parameters
nNodes = parameters{1};
discount = parameters{3};
nIter = parameters{4};
feasibleActions = parameters{13};
nAction = parameters{14}; % number of feasible actions
% season = parameters{17};   % not used now
infestationProba = parameters{36};
transmissionProba = parameters{40};
rewards = parameters{42};


% reward = 0.5;
maxActionValue = -Inf;
%% Loop on actions
for a = 1 : nAction
	
	states = initialStates;   % initialise states
% 	mainland = 0;        % mainland not infested at the beginning
	actions = feasibleActions(a, :);  % retrieve sub-actions from action a
	
	% Skip actions if susceptible island is managed
	if any(actions>=2 & states == 0), continue;	end
	
	for i = 1 : nNodes
		actionProba(i) = infestationProba(i, actions(i));
	end
	
	actionValue = 0;
	TimeStep = 1 : nIter;   % TODO compare precision if decreasing
% 	storeState = [];
%% Loop on time steps
	for timeStep = TimeStep	
		
% 	Update value
		totalReward = (1-states) * rewards(1, :)' + states * rewards(2, :)'; 
		actionValue = actionValue + totalReward * discount ^ (timeStep - 1);
		
% 		proba of not being colonised from given island
		currentTransmission = 1 - transmissionProba .* (ones(nNodes, 1) * [states 1]);
		nonColonisationProb = prod(currentTransmission,2); % proba for each island
		
		for i = 1 : nNodes
			nextState(i) = states(i)*actionProba(i) + (1-states(i)) * (1 - nonColonisationProb(i));
		end		
		states = nextState;
		
	end
	if actionValue > maxActionValue
		maxActionValue = actionValue;
		bestAction = actions;		
	end
	if maxActionValue < -10^6
		erfsef
	end
end

if ~exist('bestAction')
	assert(0==1)
end

end
