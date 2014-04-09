function detections=concat_detections(detections_arr)
cnt=0;
for i=1:numel(detections_arr)
	cnt=cnt+numel(detections_arr(i).scores);
end
detections.boxes=zeros(cnt,size(detections_arr(1).boxes,2));
detections.scales=zeros(cnt, size(detections_arr(1).scales,2));
detections.scores=zeros(cnt,1);
detections.imids=zeros(cnt,1);
detections.kpids=zeros(cnt,1);
cnt=0;
for i=1:numel(detections_arr)
	num=numel(detections_arr(i).scores);
	detections.boxes(cnt+(1:num),:)=detections_arr(i).boxes;
	detections.scales(cnt+(1:num),:)=detections_arr(i).scales;
	detections.scores(cnt+(1:num))=detections_arr(i).scores;
	detections.imids(cnt+(1:num))=detections_arr(i).imids;
	detections.kpids(cnt+(1:num))=detections_arr(i).kpids;
	cnt=cnt+num;
end

