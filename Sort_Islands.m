function [sortedAllIsland] = Sort_Islands(allIsland)

% We sort the islands by decreasing 'transmission to mainland' (one of the rules of thumb) to
% consider first the islands that will likely affect the result significantly. The 'dangerosity' of an
% island is the probability that the mosquito colonises the mainland from this island in one
% timestep.

% We then update the transmission matrix accordingly.

nTotalIsland = length(allIsland);
transmissionMatrix = zeros(nTotalIsland, nTotalIsland + 2);
dangerosity = zeros(1, nTotalIsland);

% Caculate the dangerosity of every island.
for i = 1 : nTotalIsland
	transmissionMatrix(i, :) = allIsland(i).distance;
	shape = 5 * 10 ^ 4;
	dangerosity(1,i) = allIsland(i).population / ...
		(1 + (allIsland(i).distance(1) / shape) ^ 2);
end
% Rank the highest dangerosities first.
[~, ranks] = sort(dangerosity);
ranks = fliplr(ranks);   % Decreasing order instead of increasing.
format short g
% Rearrange rows and columns with the array "ranks". As Australia and PNG have their own columns,
% special care is given to the first and last columns.
sortedTransmissionMatrix = transmissionMatrix(ranks, [1 (ranks + 1) (nTotalIsland + 2)]);

% Build the sorted allIsland file.
for i = 1 : nTotalIsland
	formerRank = ranks(i);
	ithIsland = allIsland(formerRank); % select the ith island.
	ithIsland.distance = sortedTransmissionMatrix(i, :); % update the distance array for each island
	sortedAllIsland(i) = ithIsland; %#ok<*AGROW>
end

end
