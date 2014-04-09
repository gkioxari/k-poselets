function leaders=get_cluster_leader(clusters, scores)
%get the index of the leader for each cluster
% assumes the scores are already mapped using precision recall
leaders=zeros(numel(clusters),1);
for i=1:numel(clusters)
	cluster_scr = scores(clusters(i).members);
	[m1, i1]=max(cluster_scr);
	leaders(i)=clusters(i).members(i1);
	if(rem(i-1, 10000)==0) fprintf('Doing %d/%d\n', i, numel(clusters)); end
end
