function bounds=get_baseline_bounds_predictions(clusters, newscores,boxes, kpids, bboxpred)
% wrapper around predict_keypoints for bounds


unique_kpids=unique(kpids);
bounds=zeros(size(boxes,1), 4);
for i=1:numel(unique_kpids)
	idx=kpids==unique_kpids(i);
	coords=predict_keypoints(boxes(idx,:), bboxpred(unique_kpids(i)));
	min_x=min(coords(:,1,:),[],1);
	min_y=min(coords(:,2,:),[],1);
	max_x=max(coords(:,1,:),[],1);
	max_y=max(coords(:,2,:),[],1);
	bounds(idx,:)=[min_x(:) min_y(:) max_x(:) max_y(:)];
	if(rem(i-1,10)==0) fprintf('Doing %d/%d\n', i, numel(unique_kpids)); end
end
bounds(:,3:4)=bounds(:,3:4)-bounds(:,1:2);

allbounds=bounds;
bounds=zeros(numel(clusters),4);
newscores=newscores(:);
for i=1:numel(clusters)
	bounds(i,:)=newscores(clusters(i).members)'*allbounds(clusters(i).members,:)./(sum(newscores(clusters(i).members))+eps);
end

 
