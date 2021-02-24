function [meanValueSimu, bounds] = evaluate_heuristic(solver, ...
	infestationProba, transmissionProba, rewards, feasibleActions, ...
	nSimu, discount, nNeighbours, initialStates, ...
	nIter, verbose, SPUDDPolicyName)

%% TODO: 

%% Evaluate different approaches on SIS-MDP, i.e. Markov decision processes built on a
% Susceptible-Infested-Susceptible network. 
% Terminology: the SIS network is comprised of N nodes. The management action on one node is called
% sub-action. The combination of sub-actions across all nodes is the (MDP) action. 
% 
% Input parameters:
% - 'solver' is the type of approach being evaluated (0 for 'Continuous' 
% approach - online, 1 for 'Neighbor' approach - offline, 2 for SPUDD - offline) 
% - 'infestationProba' of size (N, NA): item (i,j) is the probability that node i remains infested over
% one time step (one minus the action effectiveness) after sub-action j. This matrix determines the 
% number of nodes (N), and the number of possible sub-action for each node (NA). 
% - 'transmissionProba' of size (N,N) or of size (N,N+1): item i,j is the infestation (colonisation) 
% probability from node j to node i. If of size (N,N+1), the last column depicts the transition
% probabilities from an always infested source. 
% - 'rewards' of size (2,N): Items (1,i) and (2,i) are the rewards when node i
% is susceptible or infested respectively. The total reward is the sum of the reward for eaech node.
% Rewards do not depend on the action implemented.
% - 'feasibleActions' comes in two possible formats:
% 	1) matrix (A,N): item (i,j) is the sub-action implemented on node j when action  i is selected. 
% 	2) scalar: the number of nodes that can be simultaneously treated with sub-action #2. Sub-action 
% #1 is seen as	"do nothing". 
% - 'nSimu' is the number of simulations to run. 
% - 'discount' is the discount factor. 
% - 'nNeighbours' is the number of neighbours activated ('Neighbor' and SPUDD only).
% - 'initialStates' of size (1,N): item (1,i) describes the initial state of node i, in {0,1}={S,I}
% - 'nNIter' is the horizon of the rollout algorithm. Usually in [3,10].
% - 'verbose' is the level of information printed by this program, in [0,3]. '2' includes profiling.

% Example 1: Running 50 simulations of 'Continuous' on 2 nodes, where we aim at protecting node 1: 
% evaluate_heuristic(0,[0.9 0.8;0.5 0.8],[0 0.5;0.5 0],[1 0;0 0],[1 1;1 2;2 1],50,0.9,2,[1 1],5,1);
% (here feasibleActions = [1 1;1 2;2 1] could be replaced with feasibleActions = 2)

% Example 2: Running 10 simulations of 'Neighbor' on 3 nodes, where we aim at protecting all nodes.
% 2 nodes out of 3 can be managed with sub-action #2:
% evaluate_heuristic(1,[1 0;1 0;1 0],[0 0.5 0.5;0.5 0 0.5;0.5 0.5 0],[1 1 1;0 0 0],2,10,0.9,2,[1 1 1],5,1); 

% outputs:
% the average performance across all simulations and the 95% confidence interval.

%% Build "feasibleActions" if input is a scalar
nNodes = size(infestationProba, 1); % # of nodes
nSubActions = size(infestationProba, 2);
if isscalar(feasibleActions)
	feasibleActions = calculate_feasible_actions(feasibleActions, nSubActions, nNodes);
end

%% Save parameters for sub-functions
parameters{1} = nNodes;
parameters{2} = nNeighbours; % nIslands allowed to change in neigh. approach
% Discount rate in containment case or eradication cases
parameters{3} = discount;
parameters{4} = nIter;
parameters{5} = solver;
parameters{13} = feasibleActions;
parameters{14} = size(feasibleActions, 1); % nAction
% startingSeason = parameters{17};
parameters{36} = infestationProba;
% add extra column for external transmission if it's not in input data
if size(transmissionProba, 1) == size(transmissionProba, 2)
	transmissionProba = [transmissionProba zeros(size(transmissionProba, 1), 1)];
end
parameters{40} = transmissionProba;
parameters{42} = rewards;
parameters{49} = verbose;
if any(rewards(1, 1:nNodes - 1)) || any(rewards(2, 1:nNodes)) 
	objective = 1;  % all other objectives
else, objective = 0;   % containment out of the last node
end
parameters{60} = objective;
	
if verbose >= 1
	if solver == 0		
		fprintf('Solver: Continuous\n'); 
		fprintf('%i nodes, %i simulations.', nNodes, nSimu);
	elseif solver == 1
		fprintf('Solver: Neighbor\n'); 
		fprintf('%i nodes with up to %i changing, %i simulations.', ...
			nNodes, nNeighbours, nSimu);	
	elseif solver == 2
		parameters{45} = SPUDDPolicyName;
		fprintf('Solver: SPUDD\n'); 
		fprintf('%i nodes %i changing, %i simulations.', ...
			nNodes, nNeighbours, nSimu);	
	elseif solver == 3
		fprintf('\nExport problem in SPUDD format\n'); 
	end	
	fprintf('\n'); 
end

maxTimeStep = 200;

%% 'Neighbor' approach requires solving MDP before simulations
if solver == 1     
	startTime = datetime('now');
	if verbose >= 1, fprintf('\nSolve MDP: '); end
	[policy, ~] = solve_Neighbour(parameters);
	save('policy.mat', 'policy');
	duration = floor(seconds(datetime('now')-startTime)); % running time
	fprintf('\nOffline solver: %i s\n', duration);
% 	if verbose >= 1, fprintf('\nMDP solved.\n'); end
	% power2 is useful to calculate state number from each sub-state
	power2 = 2 .^ [nNodes-1 : -1 : 0]';
else policy = 0;
end	

if solver == 2  %  SPUDD - extract policy graph	
	SPUDDPolicyName = parameters{45};
	[nodeLabels, edgeLabels] = dot_to_graph('Mosquitoes\4,4,1,1-OPTpolicy.dot');
% 	[nodeLabels, edgeLabels] = dot_to_graph('Mosquitoes\SPUDD-OPTpolicy.dot');
% 	[nodeLabels, edgeLabels] = dot_to_graph('Mosquitoes\SPUDD-OPTpolicy17_5.dot');
% 	SPUDDPolicyName = 'Mosquitoes\SPUDD-OPTpolicy17_4_low.dot';
	% [nodeLabels, edgeLabels] = dot_to_graph(SPUDDPolicyName);
else
	nodeLabels = 0; edgeLabels = 0;
end


%% Run simulations
valueSimu = [];
if verbose >= 2, fprintf('\nStart simulations\n'); end
startTime = datetime('now');
for iSimu = 1 : nSimu
	showProgress(iSimu, nSimu, verbose);   % display % of simulations completed
	value = 0;   % initialise simulation value
% 	states = dec2bin(initialState-1,nNodes)-'0';  % retrieve island states from state #.		
	states = initialStates;  % initialise sub-states of nodes
% 	season = startingSeason; 
	timeStep = 1;
	continueSimu = 1;
	while continueSimu
		
		% Update value.
		totalReward = (1-states) * rewards(1, :)' + states * rewards(2, :)'; 
		value = value + totalReward * discount ^ (timeStep - 1);
		
		% Choose action depending on selected solver. 
		if solver == 0  %  continuous state appromxiation - online
			[~, actions, ~] = solve_Continuous(parameters, states);
		elseif solver == 1   %  neighbouring states appromxiation - offline
			stateNumber = states * power2 + 1;
			actionNumber = policy(stateNumber);
			actions = feasibleActions(actionNumber, :);
		elseif solver == 2  %  SPUDD			
			actions = SPUDD_action(parameters, 0, states, nodeLabels, ...
				edgeLabels, 1);  % '0' is for season, which is now deactivated.
		end
		
		if verbose >= 3  % display states and actions if required
			states
			actions
		end
		
		% 'Implement' action and draw the future state of the system.
		[states] = draw_next_state(parameters, states, actions); 
		
		% Decide whether or not to continue the current simulation
		continueSimu = logical(maxTimeStep > timeStep);	 % stop if enough time steps
		
		if objective == 0  % containment
			continueSimu = 1 - states(end); % stop if mainland (or protected node) is infested
		end
		timeStep = timeStep + 1;
	end
	valueSimu = [valueSimu value];   % store value
end

%% find prioritisation ranking, i.e. which nodes should be managed in priority.
% makes sense if one sub-action is better than others (e.g. manage vs do nothing)
if verbose >= 1
	fprintf('\n\n');
	find_prioritisation_ranking(parameters,...
		policy, nodeLabels, edgeLabels);
end

%% Display computation time and approach performance. 
duration = floor(seconds(datetime('now')-startTime)); % running time
fprintf('\nSimulation running time: %i s', duration);
fprintf('\nRunning time per simulation: %f s', duration/nSimu);
bounds = 1.96 * std(valueSimu) / sqrt(nSimu);
meanValueSimu = mean(valueSimu);
if verbose >= 1
pm=char(177);
if objective == 0  % containment
	fprintf('\n Average time: %.1f %c %.1f \n', mean(valueSimu), pm, bounds);
else			
	fprintf('\n Average value: %.1f %c %.1f \n', mean(valueSimu), pm, bounds);
end

end



end
