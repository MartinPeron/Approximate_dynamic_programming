function [nextStates] = draw_next_state(parameters, states, actions)

% draw next state with probabilities depending on the current 'states' variable and action. 

% Load parameters
nIsland = parameters{1};
infestationProba = parameters{36};
transmissionProba = parameters{40};

nextStates = zeros(1, nIsland);

% %% proba of colonising the mainland within the next time step
% mainlandColonised = 1 - prod(1 - states .* transmissionToMainland);

%% susceptible islands
% Proba of colonisation given current state ('1' is for infested PNG).
currentTransmission = 1 - transmissionProba(:, logical([states 1]));

% switchProba is the probability of switching state. Here, from sus to inf:
infestedProba = (1 - prod(currentTransmission,2))';


%% infested islands cannot be reinfested but can be successfully managed
for i = 1 : nIsland
	if states(i) == 1 
		infestedProba(i) = infestationProba(i, actions(i));  
	end
end


%% draw state for each island.
nextStates(rand(1, nIsland) < infestedProba) = 1;


end
