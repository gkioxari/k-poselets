function data=precision_recall_for_klets(boxes,labels)


for kid=1:max(boxes(:,end-1))
    fprintf('Klet %d \n',kid);
    keep = boxes(:,end-1)==kid;
    lbls = labels(keep);
    scores = boxes(keep,end-2);
    
    [ap,rec,prec,scores] = get_precision_recall(scores,lbls,'max',[]);
    data(kid).ap = ap;
    data(kid).rec = rec;
    data(kid).prec = prec;
    data(kid).scores = scores;
    
end

end