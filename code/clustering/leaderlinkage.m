function Z=leaderlinkage(Y, scores)
%Z=leaderlinkage(Y, scores)
%Y is in the format that pdist returns and linkage understands
%Z is in the format that cluster understands

%compute into square form
%D=squareform(Y);
D=Y;
%set diagonal to infinity so that things don't combine with themselves
for i=1:size(D,1)
	D(i,i)=inf;
end

[sorted_dist, sorted_ind]=sort(D(:), 'ascend');
[sorted_i, sorted_j]=fast_ind2sub(size(D),sorted_ind);


leaderscores=scores;
leaders=[[1:numel(scores)] zeros(1, numel(scores))];
numclusterstotal=numel(scores);

%fringe: the extant clusters so far
fringe=[1:numel(scores)];

Z=[];


curr_min=0;
tmp=false(numel(scores),1);
while(numel(fringe)>1)
	currleaders=leaders(fringe);
	tmp(:)=false;
	tmp(currleaders)=true;
	curr_min=curr_min+1;
	while(~tmp(sorted_i(curr_min)) | ~tmp(sorted_j(curr_min)))
		curr_min=curr_min+1;
	end
	i1=find(leaders(fringe)==sorted_i(curr_min));
	j1=find(leaders(fringe)==sorted_j(curr_min));
	i=max(i1,j1);
	j=min(i1,j1);
	I=fringe(i);
	J=fringe(j);
	m=sorted_dist(curr_min);
	%collapse to form new cluster
	Z=[Z; [I, J, m]];

	fringe(i)=[];
	fringe(j)=[];
	
	fringe(end+1)=numclusterstotal+1;
	assert(~any(fringe==I));
	assert(~any(fringe==J));
	%find the leader
	if(scores(leaders(I))>scores(leaders(J)))
		leaders(numclusterstotal+1)=leaders(I);
	else
		leaders(numclusterstotal+1)=leaders(J);
	end
	numclusterstotal=numclusterstotal+1;
end
	
function [r,c]=fast_ind2sub(sz, idx)
r = rem(idx-1,sz(1))+1;
c = (idx-r)/sz(2) + 1;
