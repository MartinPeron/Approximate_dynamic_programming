function showProgress(iSimu, nSimu, verbose)

if verbose >= 2
	n = 4;
	percentage = floor(100 * (1 : n) / n);
	milestone = (iSimu >= nSimu * (1:n)/n & ...
		iSimu - 1 < nSimu * (1:n)/n);
	if any(milestone)
		progress = percentage(milestone);
		fprintf(' %i%% |', progress(1));
	end
end
	
	
end