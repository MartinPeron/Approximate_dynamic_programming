function proba = approx(proba)

nDigit = 4;
proba = floor(proba*10^nDigit)/10^nDigit;


end