function bounds=clipboxes(bounds, boximids,imglist)
dims=cat(1, imglist.dims);
dims=dims(boximids,:);
mx=min(bounds(:,3:4)+bounds(:,1:2), dims);
mn=max(bounds(:,1:2),ones(size(dims)));
bounds=[mn mx-mn];

