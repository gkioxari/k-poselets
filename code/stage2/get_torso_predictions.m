function [torsos, torso_k_coordsx, torso_k_coordsy]=get_torso_predictions(boxes, kpids, kps)
% wrapper around predict_keypoints for torsos

%torso keypoints
torso_ks=[1 4 7 10];
torso_k_coordsx=zeros(size(boxes,1), 4);
torso_k_coordsy =zeros(size(boxes,1),4);
unique_kpids=unique(kpids);
torsos=zeros(size(boxes,1), 4);
for i=1:numel(unique_kpids)
	idx=kpids==unique_kpids(i);
	coords=predict_keypoints(boxes(idx,:), kps(unique_kpids(i)));
	torso_k_coords=coords(torso_ks,:,:);
	torso_k_coordsx(idx,:)=squeeze(torso_k_coords(:,1,:))';
	torso_k_coordsy(idx,:)=squeeze(torso_k_coords(:,2,:))';

	min_x=min(torso_k_coords(:,1,:),[],1);
	min_y=min(torso_k_coords(:,2,:),[],1);
	max_x=max(torso_k_coords(:,1,:),[],1);
	max_y=max(torso_k_coords(:,2,:),[],1);
	torsos(idx,:)=[min_x(:) min_y(:) max_x(:) max_y(:)];
	if(rem(i-1,10)==0) fprintf('Doing %d/%d\n', i, numel(unique_kpids)); end
end
torsos(:,3:4)=torsos(:,3:4)-torsos(:,1:2);




 
