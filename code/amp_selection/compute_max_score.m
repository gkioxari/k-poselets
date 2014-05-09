function max_score=compute_max_score(detections,index,first_el,last_el)
%% COMPUTE_MAX_SCORE()

Nannots = max(index);
Nkpids  = max(detections.kpids);

if nargin<3
    first_el = 1;
    last_el  = Nannots;
end

max_score = -inf(Nannots,Nkpids);
fprintf('Doing annot ');
for i=first_el:last_el
	if(rem(i-1,10)==0)
    	fprintf('[%d]',i);
	end
    keep = index==i;
    m = accumarray(detections.kpids(keep), double(detections.scores(keep)), [Nkpids 1], @max, -inf);
    max_score(i,:) = m';   
end
