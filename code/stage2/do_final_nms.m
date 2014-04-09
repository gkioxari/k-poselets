function idx=do_final_nms(bounds, scores, imids)
boxes=bounds;
boxes(:,3:4)=boxes(:,3:4)+boxes(:,1:2);
uniqimids=unique(imids);
idx=false(size(boxes,1),1);
scores=scores(:);
for i=1:numel(uniqimids)
	ind=find(imids(:)==uniqimids(i) & all(bounds(:,3:4)>0,2));
	[top, pick]=nms_ov([boxes(ind,:) scores(ind)], 0.5);
	idx(ind(pick))=true;
	if(rem(i-1,100)==0) fprintf('Doing %d/%d\n', i, numel(uniqimids)); end
end	
