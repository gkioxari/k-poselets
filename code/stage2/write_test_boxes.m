function write_test_boxes(filename,bounds, scores, imids, imglist)
fid=fopen(filename, 'w');
boxes=bounds;
boxes(:,3:4)=boxes(:,3:4)+boxes(:,1:2);
for i=1:size(boxes,1)
	fprintf(fid, '%s %f %f %f %f %f\n', imglist(imids(i)).id, scores(i), boxes(i,1), boxes(i,2), boxes(i,3), boxes(i,4));
	if(rem(i-1, 100000)==0) fprintf('Printed : %d/%d\n', i, size(boxes,1)); end
end
fclose(fid);
