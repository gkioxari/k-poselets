function [C amp]=amp_selection(max_score,pr,MAX_NUM_DTC)
%% AMP_SELECTION() returns the output of forward selection of detectors 
%% according to average maximum precision (see Endres et al. CVPR 2013)
%% INPUT  
% max_score     :NannotsxNkpids maximum positive score for each instance in 
%               Nannots and every detector in Nkpids
% pr            :Precision,recall,score curves of the detectors
%               [precision_recall_for_klets()]
% MAX_NUM_DTC   :maximum number of detectors to be selected
%% OUTPUT
% C             : set of kposelets selected
% amp           : the average maximum precision for every detector added


%%

Nannots = size(max_score,1); % # of annotations
Nkpids  = size(max_score,2); % # of kposelets

store_amp = [];         % amp values at every step
C = [];                 % set of detectors selected
max_prec = zeros(Nannots,1);

%get prec-rec mapped scores
mapped_scores=max_score;
fprintf('Map scores\n');
for i=1:Nannots
	for kid=1:Nkpids
		if(isinf(max_score(i,kid))) continue; end
		[m mi]=min(abs(pr(kid).scores-max_score(i,kid)));
		mapped_scores(i,kid)=pr(kid).prec(mi);
	end
end


%% main
while length(C)<MAX_NUM_DTC
    
    fprintf('\nNum_dtc=%d \n',length(C));
    rem_dtc = setdiff(1:Nkpids,C);
    prec = repmat(max_prec,[1 length(rem_dtc)]);
    
    for ri=1:length(rem_dtc)
        if mod(ri,300)==1
            fprintf('(%d / %d)',rem_dtc(ri),length(rem_dtc));
        end
        for i=1:Nannots
            sc = mapped_scores(i,rem_dtc(ri));
            if isinf(sc), continue; end
            prec(i,ri) = max(prec(i,ri),sc);
        end
    end
    
    mean_prec = mean(prec,1);
    [m mi] = max(mean_prec);
    
    C = [C rem_dtc(mi)];
    max_prec = prec(:,mi);
    amp = m;
    store_amp = [store_amp amp];
    
end

amp = store_amp;


end
