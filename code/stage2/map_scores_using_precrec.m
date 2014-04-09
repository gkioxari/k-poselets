function newscores = map_scores_using_precrec(oldscores, kpids, precrec_mapping)
newscores = oldscores;
unique_kpids = unique(kpids);
for i=1:numel(unique_kpids)
	idx=(kpids==unique_kpids(i));
	scr=oldscores(idx);
    mapping_scr=precrec_mapping(unique_kpids(i)).scores;
	prec=precrec_mapping(unique_kpids(i)).prec;
	
	%check if can fit into memory
	if(numel(scr)*numel(mapping_scr)<1e7)
	dist=bsxfun(@minus, scr(:), mapping_scr(:)');
	dist=abs(dist);
	[m2, i2]=min(dist, [], 2);
	else
	i2=zeros(numel(scr),1);
	for j=1:numel(scr)
		dist=abs(scr(j)-mapping_scr(:));
		[m22, i22]=min(dist, [], 1);
		i2(j)=i22;
	end



	end
	newscores(idx)=prec(i2);

	if(rem(i-1,10)==0) fprintf('Doing %d/%d\n', i, numel(unique_kpids)); end
end
