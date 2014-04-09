function feats=fv_for_rescoring(clusters, detections, newscores, imglist, chosen_pids)
% create feature vectors for rescoring


%first set of features will be scale, expressed as area of first box
areas=prod(detections.boxes(:,3:4)-detections.boxes(:,1:2),2);

%next set of features is the minimum fraction of the detection inside the image


dims=cat(1,imglist.dims);
dims=dims(detections.imids,:);
maxnumparts=round(size(detections.boxes,2)/4);
ov=inf(numel(detections.scores),1);
for i=1:maxnumparts
	bx=detections.boxes(:,(i-1)*4+(1:4));	
	mx=min(bx(:,3:4), dims);
	mn=max(bx(:,1:2), ones(size(dims)));
	inimageareas=prod(max(mx-mn,0),2);
	totalareas=prod(bx(:,3:4)-bx(:,1:2),2);
	ovtmp=inimageareas./totalareas;
	ov(~isnan(ovtmp))=min(ov(~isnan(ovtmp)), ovtmp(~isnan(ovtmp)));
end




feats=zeros(numel(chosen_pids)*3,numel(clusters));
for k=1:numel(clusters)

	%get the leader per kpid in each cluster and use its features
	ids=clusters(k).members;
	kpids=detections.kpids(ids);
	[tochoose, loc]=ismember(kpids, chosen_pids);
    uniqloc=unique(loc);
	%for i=1:numel(uniqloc)
	%	l=uniqloc(i);
	%	j=find(loc==l);
	%	[m1,i1]=max(newscores(ids(j)));
	%	feats(l,k)=detections.scores(ids(j(i1)));%m1;
	%	feats(numel(chosen_pids)+l,k)=ov(ids(j(i1)));
	%	feats(2*numel(chosen_pids)+l,k)=areas(ids(j(i1)));
	%end
	feats(1:numel(chosen_pids),k)=accumarray(loc(tochoose),newscores(ids(tochoose)), [numel(chosen_pids) 1],@max);
	feats(numel(chosen_pids)+1:2*numel(chosen_pids),k)=accumarray(loc(tochoose),ov(ids(tochoose)), [numel(chosen_pids) 1],@max);
	feats(2*numel(chosen_pids)+1:3*numel(chosen_pids),k) = accumarray(loc(tochoose),areas(ids(tochoose)), [numel(chosen_pids) 1],@max);

	if(rem(k-1,10000)==0) fprintf('.'); end
end
fprintf('\n');
