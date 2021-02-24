function [policy, value] = solve_Neighbour(parameters)

% Solve MDPs by allowing only a handful of islands to change state.	
	
% Load parameters
nNodes = parameters{1};
nNeighbours = parameters{2};
discount = parameters{3};
nIter = parameters{4};
feasibleActions = parameters{13};
nAction = parameters{14}; % number of feasible actions
% startingSeason = parameters{17};
infestationProba = parameters{36};
transmissionProba = parameters{40};
% transmissionToMainland = parameters{41};
rewards = parameters{42};
verbose = parameters{49};

%% Pre-processing & initialisation
% Initialise MDP value
nStates = 2^nNodes;
for s = 1 : nStates
	states = dec2bin(s-1,nNodes)-'0';
	value(s) = (1-states) * rewards(1, :)' + states * rewards(2, :)'; 
end

% fill a matrix of nchoosek logicals - will be useful when computing future state probas.
nNeighbours = min(nNodes, nNeighbours);
changing = cell(1, nNeighbours + 1);
changing{1} = false(1, nNodes);

for n = 1 : nNeighbours
	indicesChanging = nchoosek(1 : nNodes,n);
	nCombination = size(indicesChanging, 1);
	logicalChanging = false(nCombination, nNodes);
	for iCombination = 1 : nCombination
		logicalChanging(iCombination, indicesChanging(iCombination, :)) = true;		
	end
	changing{n+1} = logicalChanging;
end

% The array power2 is useful to go from base 2 to decimals
% i.e. to calculate state number from each sub-state
power2 = 2 .^ [nNodes-1 : -1 : 0]';

%% Start dynamic programming
if verbose >= 1
fprintf('%i value iteration steps\n', nIter);
end

for iter = 1 : nIter  % backward induction
	showProgress(iter, nIter, verbose);
		
	futureValue = zeros(1, nStates);
	for s = 1 : nStates
		states = dec2bin(s-1,nNodes)-'0';
		
% 		% proba of not colonising the mainland within the next time step
% 		mainlandNotInfested = prod(1 - states .* transmissionToMainland);
		
		% Proba of colonisation given current state ('1' is for infested PNG).
		currentTransmission = 1 - transmissionProba(:, logical([states 1]));
		
		% switchProba is the probability of switching state. Here, from sus to inf:
		switchProba = (1 - prod(currentTransmission,2))';
		
		% Pre-processing 
		for n = 0 : nNeighbours     % # of islands that will change (inf/sus)
				logicalChanging = changing{n+1};
				nCombination = size(logicalChanging, 1);				
				% find the state numbers corresponding to the future states:
				numberMatrix = ones(nCombination, 1) * states;
				numberMatrix(logicalChanging) = 1 - numberMatrix(logicalChanging);
				stateNumberNChanging{n+1} = numberMatrix * power2 + 1;			
		end
		
		% compute immediate reward for each state
		totalReward = (1-states) * rewards(1, :)' + states * rewards(2, :)'; 
		actionV = totalReward * ones(1, nAction);  
		
		for a = 1 : nAction
			actions = feasibleActions(a, :);
			% no action on susceptible island
			if any(actions>=2 & states == 0), continue;	end
			
			% fill switchProba from inf to sus:
			for i = 1 : nNodes
				if states(i) == 1  % only fill those islands that are infested					
					switchProba(i) = 1 - infestationProba(i, actions(i));
				end
			end
% 			futureValue = 0.5;    % reward at current time step
			for n = 0 : nNeighbours     % # of islands that will change (inf/sus)
				logicalChanging = changing{n+1};
				nCombination = size(logicalChanging, 1);				
				
				% Load the state numbers corresponding to the future states:
				stateNumbers = stateNumberNChanging{n+1};
				
				% calculate probas of ending up in these future states
				probaMatrix = ones(nCombination, 1) * switchProba;
				probaMatrix(~logicalChanging) = 1 - probaMatrix(~logicalChanging);
				probaMatrix2 = prod(probaMatrix, 2);
				
				% increase value due to these future states (for action a)
				actionV(a) = actionV(a) + ...
						discount * (value(stateNumbers) * probaMatrix2);	
					
			end
		end		% end loop actions		
		
		[futureValue(s), policy(s)] = max(actionV); % select best action
	end
	value = futureValue;  % update value array
	plott(iter) = value(end);
end

if verbose >= 2
% 	format('short');
	fprintf('\n\n');
	
	% Print policy
	fprintf('\n----------------------------------------');
	fprintf('\nPolicy: \n');
	fprintf('State');
	for i = 1 : nNodes, fprintf('		'); end
	fprintf('--->	Action');	
	for i = 1 : nNodes, fprintf('		'); end
	fprintf('Value \n');	
	
	for s = 1 : nStates
		states = dec2bin(s-1,nNodes)-'0';
		for i = 1 : nNodes
			fprintf('%i		', states(i));
		end
		fprintf('		--->	');
		actions = feasibleActions(policy(s), :);  % array of recommended actions in state s
		for i = 1 : nNodes
			feasibleActions(a, :);
			fprintf('%i		', actions(i));
		end		
		fprintf('			%.3g		', value(s));
		fprintf('\n');
	end
	fprintf('----------------------------------------\n');
% 	policy
% 	plot(plott);
end


end