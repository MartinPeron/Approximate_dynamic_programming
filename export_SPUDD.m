function export_SPUDD(parameters)

% Exporting factored MDP for symbolic perseus. 

% Load parameters
nIsland = parameters{1};
nNeighbours = parameters{2};
nNeighboursMainland = nNeighbours;
discount = parameters{3};
budget = parameters{6};
nSubActions = parameters{8};
subActionCosts = parameters{12};
infProba = parameters{36};
transProba = parameters{40};
transMainland = parameters{41};
% PNG = parameters{43};
verbose = parameters{49};
low = parameters{59};
objective = parameters{60};

%% reduce SPUDD input file size for tractability. 
if nNeighbours >= 1
	% 1) transmissions from a few islands only (highest probabilities):
	transProba = transProba';
	[~, M] = sort(transProba);
	indiceToDelete = M(1:max(0,nIsland+1-nNeighbours), :);
	for iIsland = 1 : nIsland
		transProba(indiceToDelete(:, iIsland), iIsland) = 0;
	end
	transProba = transProba';
	% same for mainland
	[~, M] = sort(transMainland);
	indiceToDelete = M(1:max(0,nIsland-nNeighboursMainland));
	transMainland(indiceToDelete) = 0;
else
	% 2) trim the probas under a certain threshold - defined as "nNeighbours":
	transProba(transProba < nNeighbours) = 0;
	transMainland(transMainland < nNeighbours) = 0;
end

%% process doable actions
% allConstantTransmission = 0; factorLow = 0.666; factorHigh = 1.5; 
% format('short');
feasibleActions = generate_actions(nSubActions, ...
	subActionCosts, [], nIsland, budget, []);
nAction = size(feasibleActions, 1); % number of feasible actions
% Name of the exported file.
% fileName = ['Mosquitoes' filesep num2str(nIsland) '_'  num2str(nNeighbours)];
fileName = ['Mosquitoes' filesep 'SPUDD_' num2str(nIsland) '_' ...
			num2str(nNeighbours) '_' num2str(objective) '_' num2str(low)]; 
% if objective == 0, fileName = [fileName '_contain'];
% else fileName = [fileName '_eradic']; end
% if low == 1, fileName = [fileName '_low'];
% elseif low == 0 fileName = [fileName '_high']; 
% else fileName = [fileName '_rand']; end %#ok<*SEPEX>
% uncomment following line if nNeighbours < 1 but potential problem in HPC
% fileName(fileName == '.') = ',';   
fileID = fopen(fileName,'w');
% fclose(fileID);
fclose all;
fileID = fopen(fileName,'a');

% First statements in the exported file.
fprintf(fileID,'(variables \r\n');
fprintf(fileID,'    (season dry wet)');
if objective == 0, fprintf(fileID,'\r\n    (mainland sus inf)'); end
for iIsland = 1:nIsland
	fprintf(fileID,['\r\n    (island' num2str(iIsland) ' sus inf)']);
end
fprintf(fileID,')\r\n\r\n');
fprintf(fileID,'dd defaultseason\r\n');
% fprintf(fileID,'	(season	(dry	(0 1))	(wet	(1 0)))\r\n');
fprintf(fileID,'	(season	(dry	(seasonwet))	(wet	(seasondry)))\r\n');
fprintf(fileID,'enddd\r\n');

%% Decision diagrams on each island for each action
for iIsland = 1 : nIsland
	for nodeAction = 0 : 2
		sIsland = num2str(iIsland);
		sAction = num2str(nodeAction + 1);
		
		fprintf(fileID,['\r\ndd island' sIsland 'action' sAction '\r\n']);
		fprintf(fileID,['	(island' sIsland]);		
				
		% Dry season is 0, wet is 1.
		fprintf(fileID,'	(inf');
		if nodeAction == 0    % no action, depends on the season
			fprintf(fileID,'	(season');			
			fprintf(fileID,['	(wet	(island' sIsland '''' '	(inf (' num2str(approx(infProba(iIsland, 2))) ...
				 '))	(sus (' num2str(1-approx(infProba(iIsland, 2))) '))))\r\n']);
			fprintf(fileID,['								(dry	(island' sIsland '''' '	(inf (' ...
				num2str(approx(infProba(iIsland, 1))) '))	(sus (' num2str(1-approx(infProba(iIsland, 1))) '))))))']);
			
		else  % light or strong management, independant of season
			fprintf(fileID,['	(island' sIsland '''' '	(inf (' num2str(approx(infProba(iIsland, nodeAction+2))) ...
				 '))	(sus (' num2str(1-approx(infProba(iIsland, nodeAction+2))) '))))']);				
		end
		
		fprintf(fileID,'\r\n				(sus'); % susceptible island
			% recursive function to export the influence of each island on 'iIsland'.
			recTransmission(transProba(iIsland, :), [], iIsland, 1, nIsland, 1, fileName);
		fprintf(fileID,'))\r\nenddd');
	end
end

if objective == 0  
	% containment out of mainland
	fprintf(fileID,'\r\ndd mainlanddd\r\n	(mainland');		
	fprintf(fileID,'	(inf	(mainlandinf))\r\n');		% infested mainland
	fprintf(fileID,'\r\n				(sus'); % susceptible mainland 
	recTransmission(transMainland, [], 0, 1, nIsland, 0, fileName);
	fprintf(fileID,'))\r\nenddd');		
end


%% transition probabilities
for iAction = 1 : nAction
	islandAction = feasibleActions(iAction,:);
	actionString = num2str(islandAction);
	actionString = actionString(~isspace(actionString)); 
	fprintf(fileID,['\r\naction action' actionString]);
	fprintf(fileID,'\r\n	season (defaultseason)');
	if objective == 0
		fprintf(fileID,'\r\n	mainland (mainlanddd)');
	end

	for iIsland = 1 : nIsland

		action = islandAction(iIsland);
		sIsland = num2str(iIsland);
		sAction = num2str(action);
		ddname = ['	(island' sIsland 'action' sAction ')'];

		fprintf(fileID,['\r\n	island' sIsland ddname]);
	end
	
	fprintf(fileID,'\r\nendaction');
	
end

%% last lines & export
if objective == 0
	fprintf(fileID,'\r\n\r\nreward (mainland (sus (0.5)) (inf (0.0)))');
	fprintf(fileID,'\r\ndiscount 0.99');
else
	fprintf(fileID,'\r\n\r\nreward');	
	if nNeighbours < 1, nNeighbours = 5; end	
	recReward(0, 1, nIsland, nNeighbours, fileName);
	fprintf(fileID,['\r\ndiscount ' num2str(discount)]);
end
fprintf(fileID,'\r\ntolerance 0.01');
fclose(fileID);
if verbose >= 1
	text = ['start notepad ' fileName];
	dos(text); % open generated text file.
end
end