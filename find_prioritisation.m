function find_prioritisation(parameters)

% Evaluate heuristic
	
% Load parameters
nIsland = parameters{1};
budget = parameters{6};
nSubActions = parameters{8};
solver = parameters{9};
subActionCosts = parameters{12};
startingSeason = parameters{17};
verbose = parameters{49};

%% find list of actions that are within the budget (dynamic programming)
feasibleActions = generate_actions(nSubActions, ...
	subActionCosts, [], nIsland, budget, []);
parameters{13} = feasibleActions;
parameters{14} = size(feasibleActions, 1); % number of feasible actions

%% Solve MDP with neighbouring states appromxiation
if solver == 1     
	startTime = datetime('now');
	if verbose >= 1, fprintf('\nSolve MDP: '); end
	[policy, ~] = solve_ADP_2(parameters);
	save('policy.mat', 'policy');
	duration = floor(seconds(datetime('now')-startTime)); % running time
	fprintf('\nOffline solver: %i s', duration);
% 	if verbose >= 1, fprintf('\nMDP solved.\n'); end
	% power2 is useful to calculate state number from each sub-state
	power2 = 2 .^ [nIsland-1 : -1 : 0]';
end	

if solver == 2  %  SPUDD - extract policy graph	
	SPUDDPolicyName = parameters{45};
	[nodeLabels, edgeLabels] = dot_to_graph(SPUDDPolicyName);
end

states = ones(1, nIsland);
previousActions = ones(1, nIsland);
load IslandData.mat;
allIsland = Sort_Islands(allIsland); %#ok<*NODEF>
islandsToManage = cell(1, nIsland);

%%
for iStep = 1 : nIsland
	
		if solver == 0  %  continuous state appromxiation - online
			[~, actions, ~] = solve_ADP(parameters, states);
		elseif solver == 1   %  neighbouring states appromxiation - offline
			stateNumber = states * power2 + 1;
			actionNumber = policy(stateNumber);
			actions = feasibleActions(actionNumber, :);
		elseif solver == 2  %  SPUDD			
			actions = SPUDD_action(parameters, startingSeason, states, nodeLabels, edgeLabels, 1);
		end
		
			[~,index] = sortrows([actions' previousActions'], [1 2]);
			islandToManage = index(end);
			states(islandToManage)= 0;
			previousActions = actions;
			
			islandsToManage{iStep} = allIsland(islandToManage).engName;
			fprintf([ islandsToManage{iStep} '\n']);
		
end

end
