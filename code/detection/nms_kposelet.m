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
%do nms
while(~isempty(i1))
	pick=i1(1);
	i1(1)=[];
	bx=boxes2(pick,:);
	I=[I pick];

	
	if(isempty(i1)) break; end
	
	int=zeros(1, numel(i1), numparts);
	uni=zeros(1, numel(i1), numparts);
	for i=1:numparts
		int(:,:,i)=rectint(bx((i-1)*4+(1:4)),boxes2(i1,(i-1)*4+(1:4)));
		uni(:,:,i)=bareas(i1,i)' + bareas(pick,i)-int(:,:,i);
	end
	ov=int./uni; 

	remove=find(mean(ov,3)>thresh);
	%ismember(104,i1)
    %ov(1,find(i1==104),:)
	%pause;
	i1(remove)=[];
end
boxes=boxes(I,:);
	
