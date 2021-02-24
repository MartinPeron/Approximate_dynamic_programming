function recReward(reward, iIsland, nIsland, nNeighbours, fileName)

fileID = fopen(fileName,'a');

% End of tree or tree too big
if iIsland == nIsland + 1 || reward >= nNeighbours
	fprintf(fileID,['(' num2str(reward) ')']);

else   % possible colonisation

% 	fileID = fopen(fileName,'a');
	sIsland = num2str(iIsland);		
	fprintf(fileID,['	(island' sIsland '	(inf ']);
	recReward(reward, iIsland + 1, nIsland, nNeighbours, fileName);
% 		recTransmission(islandTransmissionProba, iIsland, iIsland + 1, nIsland, PNG, fileName);
	fprintf(fileID,')\r\n	');
	fprintf(fileID,'				');		
	for loop = 1:(iIsland - 1)
		fprintf(fileID,'					');			
	end
	fprintf(fileID,'(sus ');
	recReward(reward + 1, iIsland + 1, nIsland, nNeighbours, fileName);
% 		recTransmission(islandTransmissionProba, [islandState 0], iIsland, iIsland + 1, nIsland, PNG, fileName);
	fprintf(fileID,'))');

end			
	
fclose(fileID);
% fclose all;

end


