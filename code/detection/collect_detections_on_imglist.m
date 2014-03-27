function detections = collect_detections_on_imglist(imglist, models, maxnumparts, start_id, end_id)

detections=[];
for i=start_id:end_id
	fprintf('Doing %d\n',i);
	img=imread(imglist(i).im);
	detections_img=detect_kposelets_all(img, models, maxnumparts);
	detections_img.imids(:)=i;
	if(isempty(detections))
		detections=detections_img;
	else
		detections=concat_detections(detections, detections_img);
	end
end
	
