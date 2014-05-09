function pr = precision_recall_for_klets(detections,labels)
%% PRECISION_RECALL_FOR_KLETS() returns precision recall curves for each 
%% kposelet
%% INPUT
% detections    : activations of kposelets
% labels        : true/false labels of activations
%% OUTPUT
% pr            : ap-rec-prec-scores for each kposelet

%%
Nkpids = max(detections.kpids);

fprintf('Doing kid ');
for kid=1:Nkpids
	if(rem(kid,10)==0)
    	fprintf('[%d]',kid);
	end
    keep = detections.kpids==kid;
    lbls = labels(keep);
    scrs = detections.scores(keep);
    
    [ap,rec,prec,scores] = get_precision_recall(scrs,lbls,'max',[]);
    pr(kid).ap = ap;
    pr(kid).rec = rec;
    pr(kid).prec = prec;
    pr(kid).scores = scores;
    
end

end
