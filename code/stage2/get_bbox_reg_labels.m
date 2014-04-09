function [labels, centroids]= get_bbox_labels(gt_bounds, torso_bounds, num_centres, centroids)
y=gt_bounds(:,4)./torso_bounds(:,4);%(gt_bounds(:,4)+gt_bounds(:,2)-torso_bounds(:,2)+torso_bounds(:,4))./torso_bounds(:,4);

if(exist('centroids', 'var'))
	dist=abs(bsxfun(@minus, y, centroids(:)'));
	[m,labels]=min(dist,[],2);
else
	[labels, centroids]=kmeans(y, num_centres);
	
	
end
