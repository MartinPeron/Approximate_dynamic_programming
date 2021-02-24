classdef  Island < handle    
% Class island

    properties
        name 
        engName
        initialData
		  initialAccurateData
		  feature
        finalData
        management
        annualInfestationProb
        totalInfestationProb
        infected
        population
        distance
		  location
        sensToFind
    end
    methods        
    	function new = Island(dataName, dataEngName, dataFeature, ...
                dataAccurateFeature, dataPopulation, ...
					 dataDistance, dataLocation)
            new.name = dataName;
            new.engName = dataEngName;
            new.initialData = dataFeature;
				new.initialAccurateData = dataAccurateFeature;
            new.infected = 1; 
            new.population = dataPopulation;
            new.distance = dataDistance;
				new.location = dataLocation;
        end            
        function [obj,idx]=sort(obj,varargin)
        %sort object array with respect to 'Infected'
         [~,idx]=sort([obj.infected],varargin{:}); obj=obj(idx);
        end        
    end    
end

