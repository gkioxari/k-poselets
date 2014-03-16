function [boxes, I]=nms_kposelet(boxes, numparts, thresh)

%sort by scores
[s1, i1]=sort(boxes(:,end), 'descend');
I=[];
boxes2=boxes;

%convert to bounds and compute box areas
bareas=zeros(size(boxes,1), numparts);
for i=1:numparts
	boxes2(:,(i-1)*4+3:i*4)=boxes2(:,(i-1)*4+3:i*4)-boxes2(:,(i-1)*4+1:(i-1)*4+2);
	bareas(:,i)=prod(boxes2(:,(i-1)*4+3:i*4),2);
end

%precompute overlaps
int=zeros(numel(i1), numel(i1), numparts);
uni=zeros(numel(i1), numel(i1), numparts);
ov=zeros(numel(i1), numel(i1), numparts);
for i=1:numparts
	int(:,:,i)=rectint(boxes2(:,(i-1)*4+1:i*4), boxes2(:,(i-1)*4+1:i*4));
	uni(:,:,i)=bsxfun(@plus, bareas(:,i), bareas(:,i)')-int(:,:,i);
	ov(:,:,i)=int(:,:,i)./(uni(:,:,i)+(uni(:,:,i)==0));
end

%do nms
while(~isempty(i1))
	pick=i1(1);
	i1(1)=[];
	bx=boxes2(pick,:);
	

	remove=mean(ov(pick,i1,:),3)>thresh;	
	i1(remove)=[];
	I=[I pick];
end
boxes=boxes(I,:);
	
