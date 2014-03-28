function detections=select_detections(detections, idx)
detections.boxes=detections.boxes(idx,:);
detections.scales=detections.scales(idx,:);
detections.scores=detections.scores(idx);
detections.kpids=detections.kpids(idx);
detections.imids=detections.imids(idx);
