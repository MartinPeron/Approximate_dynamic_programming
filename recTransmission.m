function recTransmission(islandTransmissionProba, islandState, ...
	iIsland, jIsland, nIsland, PNG, fileName)
fileID = fopen(fileName,'a');
if fileID > 21
	assert(1==0);
end
	% Transmission from j to i
	if jIsland == 1 + nIsland
		
		if iIsland == 0							% code for mainland
			str = '	(mainland';
			infestationProba = 1 - prod(1 - [islandState] .* islandTransmissionProba);
		else												% all other islands
			str = ['	(island' num2str(iIsland)];
			infestationProba = 1 - prod(1 - [islandState 1] .* islandTransmissionProba);
		end		
		fprintf(fileID,[str '''' '	(inf (' num2str(approx(infestationProba)) '))']);
		if length(num2str(infestationProba)) < 8, fprintf(fileID,'	'); end
		fprintf(fileID,['	(sus (' num2str(1-approx(infestationProba)) ')))']);
% 		fclose(fileID);
		
	elseif iIsland == jIsland || islandTransmissionProba(jIsland) == 0  % no possible transmission
		recTransmission(islandTransmissionProba, [islandState 0], iIsland, jIsland + 1, nIsland, PNG, fileName);
		
	else   % possible colonisation
		
% 		fileID = fopen(fileName,'a');
		sIsland = num2str(jIsland);		
		fprintf(fileID,['	(island' sIsland '	(inf ']);
		recTransmission(islandTransmissionProba, [islandState 1], iIsland, jIsland + 1, nIsland, PNG, fileName);
		fprintf(fileID,')\r\n	');
		fprintf(fileID,'								');		
		for loop = 1:sum(islandTransmissionProba(1:(jIsland-1))>0)
			fprintf(fileID,'					');			
		end
		fprintf(fileID,'(sus ');
		recTransmission(islandTransmissionProba, [islandState 0], iIsland, jIsland + 1, nIsland, PNG, fileName);
		fprintf(fileID,'))');
		
	end
	
	fclose(fileID);
			

end


