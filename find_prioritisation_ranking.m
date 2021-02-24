function find_prioritisation_ranking(parameters, ...
	policy, nodeLabels, edgeLabels)

% find prioritisation ranking, i.e. which nodes should be managed in priority.
%% initialisation
nNodes = parameters{1};
solver = parameters{5};
feasibleActions = parameters{13};
states = ones(1, nNodes);
previousActions = ones(1, nNodes);
load IslandData.mat;
% allIsland = Sort_Islands(allIsland); %#ok<*NODEF>
power2 = 2 .^ [nNodes-1 : -1 : 0]';
ranking = [];

%% loop on nodes

for iStep = 1 : nNodes
	
		% Choose action depending on selected server. 
		if solver == 0  %  continuous state approximation - online
			[~, actions, ~] = solve_Continuous(parameters, states);
		elseif solver == 1   %  neighbouring states appromxiation - offline
			stateNumber = states * power2 + 1;
			actionNumber = policy(stateNumber);
			actions = feasibleActions(actionNumber, :);
		elseif solver == 2  %  SPUDD			
			actions = SPUDD_action(parameters, 0, states, nodeLabels, ...
				edgeLabels, 1);  % '0' is for season, which is now deactivated.
		end
		
		[~,index] = sortrows([actions' previousActions'], [1 2]);
		islandToManage = index(end);
		ranking = [ranking islandToManage];
		states(islandToManage) = 0;
		previousActions = actions;
		
% 		islandsToManage{iStep} = allIsland(islandToManage).engName;
% 		fprintf([ islandsToManage{iStep} '\n']);
		
end
ranking
end
