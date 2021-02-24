function actions = SPUDD_action(parameters, season, states, nodeLabels, edgeLabels, currentRow)


% find action following SPUDD's output policy tree
% (already transformed to a adjacency matrix)

% Load parameters
nIsland = parameters{1};
% verbose = parameters{49};

label = nodeLabels{currentRow}(1:6);
if strcmp(label, 'action')  % action to implement = tree leaf 
	actions = zeros(1, nIsland);
	for i = 1 : nIsland
		actions(i) = str2num(nodeLabels{currentRow}(6 + i));   % action on island i
	end
% 	if sum(actions-1) ~= 3
% 		actions
% 		waitforbuttonpress
% 	end
else  % go down the tree 
	if strcmp(label, 'mainla')
		labelToFind = 'sus';
	elseif strcmp(label, 'island')
		island = str2num(nodeLabels{currentRow}(7:end));
		if states(island) == 0, labelToFind = 'sus'; else labelToFind = 'inf'; end
	elseif strcmp(label, 'season')
		if season == 1, labelToFind = 'wet'; else labelToFind = 'dry'; end
	else
		error('\nPattern not recognised');
	end
	
	nextRow = 1;
	while (nextRow <= size(edgeLabels, 2))
		if strcmp(edgeLabels{currentRow, nextRow}, labelToFind)
			break;
		end
		nextRow = nextRow + 1;
	end
	if nextRow > size(edgeLabels, 2)
		error('\nedge label not found')
	end	
	actions = SPUDD_action(parameters, season, states, nodeLabels, edgeLabels, nextRow);
		
end









end