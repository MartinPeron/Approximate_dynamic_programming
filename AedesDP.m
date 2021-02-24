function [meanValues, boundArray] = ...
	AedesDP(solver, maxNIsland, nNeighbours, objective, low, nNIter, ...
	nSimu, verbose, SPUDDPolicyName)
%   Approximate Dynamic Programming for management of aedes Albopictus

%% Parameters that can be changed by users
% minNIsland = 1;	% min number of islands <= maxNIsland
minNIsland = maxNIsland;	% min number of islands <= maxNIsland
budget = 3;     % 6-month budget >=0
subActionCosts = [0 1 2]; % costs of implementing sub-actions: [Do nothing, light management, strong management].
nSubActions = length(subActionCosts); %   # of sub-actions (3)
% objective = params(2);  % Containment (0) or eradication (1)

startingSeason = 1;					% Dry season is 0, wet is 1.
if exist('SPUDDPolicyName')  % useful for HPC
	solver = 2; % Evaluate SPUDD's policy
else
	SPUDDPolicyName = '';  % for sub-functions
end

%% Initialisations
RandStream.setGlobalStream(RandStream('mt19937ar','seed',sum(100*clock)));
format('long');
% params(1) = min(params(1), maxNIsland);   
nNeighbours = min(nNeighbours, maxNIsland + 1);  % no more neighbours than islands inc. Main

%% Fill variable 'parameters'
parameters = {0, nNeighbours, 0, 0, 0, budget, 0, ...
	nSubActions, solver, nSimu, solver, subActionCosts, 0, 0, 0, 0, startingSeason}; 
%TODO clean
parameters{43} = 1;  % Transmission from PNG allowed (1) or not (0).
parameters{49} = verbose; 
parameters{59} = low;  % High (0), low (1) or random colonisation probabilities.
parameters{60} = objective;
nIslandArray = minNIsland : maxNIsland; parameters{61} = nIslandArray;


if verbose >= 1
	close all; clc; 
	fprintf('\nCase study: managing Aedes albopictus'); 
% 	if solver == 0		
% 		fprintf('\nContinuous state approximation\n'); 
% 		fprintf('\n%i islands, %i simulations.', maxNIsland, nSimu);
% 	elseif solver == 1
% 		fprintf('\nNeighbouring states approximation\n'); 
% 		fprintf('\n%i islands with up to %i changing, %i simulations.', ...
% 			maxNIsland, nNeighbours, nSimu);	
% 	elseif solver == 2
% 		parameters{45} = SPUDDPolicyName;
% 		fprintf('\nImplement SPUDD''s policy\n'); 
% 		fprintf('\n%i islands %i changing, %i simulations.', ...
% 			maxNIsland, nNeighbours, nSimu);	
% 	elseif solver == 3
% 		fprintf('\nExport problem in SPUDD format\n'); 
% 	end
	 
	
	if objective == 0
		fprintf('\nObjective: Containment\n'); 
		discount = 0.99999999;	% containment
	elseif objective == 1
		fprintf('\nObjective: Eradication\n'); 
		discount = 0.95;	%#ok<*SEPEX> % eradication
	end
	
	if low == 0, fprintf('Transmissions: High\n'); 
	elseif low == 1, fprintf('Transmissions: Low\n'); 
	else, fprintf('Transmissions: Random\n'); 
	end		
end

if verbose >= 2
	profile clear; profile on;
end

%% Generate and solve MDP models - start loop on #islands and models
for nIsland = nIslandArray					% Loop on islands
	
	% fill rewards. the first line are the rewards when sus, 2nd line is inf. 
	if objective == 0    % containment - add the mainland as state
		% only mainland susceptible triggers a reward
		rewards = [zeros(1, nIsland) 0.5; zeros(1, nIsland+1)]; 
		initialStates = [ones(1,nIsland) 0];    % initial state - all islands infested
	elseif objective == 1   % eradication
		% each susceptible island triggers a reward
		rewards = [ones(1, nIsland); zeros(1, nIsland)];
		initialStates = [ones(1,nIsland)];    % initial state - all islands infested
	end
	
	parameters{1} = nIsland;
	
	%% find list of actions that are within the budget (dynamic programming)
	feasibleActions = generate_actions(nSubActions, ...
		subActionCosts, [], nIsland, budget, []);
	parameters{14} = size(feasibleActions, 1); % number of feasible actions
	if objective == 0  % containment - add the mainland as state
		feasibleActions = [feasibleActions ones(parameters{14}, 1)];
	end	
	parameters{13} = feasibleActions;
feasibleActions
	% Load and display information on islands
	[parameters, infestationProba, transmissionProba, ...
		~]= load_islands_features(parameters);
	infestationProba
	transmissionProba(end,:) = 1;
	if solver == 3
		export_SPUDD(parameters);
	else
	
		% Evaluate heuristic
		meanValues = [];
		boundArray = [];
		
		for nIter = nNIter
			parameters{4} = nIter;
			[meanValue, bounds] = evaluate_heuristic(solver, ...
				infestationProba, transmissionProba, rewards, ...
				feasibleActions, nSimu, discount, nNeighbours, initialStates,  ...
				nIter, verbose, SPUDDPolicyName);

			% uncomment to find management prioritisation of islands
% 			find_prioritisation(parameters);	
				
			meanValues = [meanValues meanValue];
			boundArray = [boundArray bounds];
		end

		if verbose >= 1 && length(nNIter) > 1
		% 	plot(meanValues);
			nNIter
			meanValues
			boundArray
			errorbar(nNIter,meanValues,boundArray);
		end
		
	end
	
end	 % loop on islands


if verbose >= 2
	profile viewer;
end

end