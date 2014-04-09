function model = train_kposelet(part, annot, negimglist, imglist, name, kpid, ind_in_part, basedir, kps, training_opts)
%%
torso_ks=[1 4 7 10];
rng(3);
%if training opts are not supplied, initialize with default
if(~exist('training_opts', 'var'))
	training_opts=get_default_training_opts(basedir);
end

%logging dirs
model_dir=fullfile(training_opts.model_dir, name, sprintf('%05d', kpid));
if(~exist(model_dir, 'file'))
	mkdir(model_dir);
end
log_dir=fullfile(training_opts.log_dir, name);
if(~exist(log_dir, 'file'))
	mkdir(log_dir);
end
log_file=fullfile(log_dir, [sprintf('%05d',kpid) '.txt']);

%if model exists, return
if(exist(fullfile(model_dir, 'final_model.mat'), 'file'))
	x=load(fullfile(model_dir, 'final_model.mat'));
	model=x.model;
	model.name=name;
	model.kpid=kpid;



	return;
end



%start logging
diary(log_file);

%get the number of parts in this kposelet and number of examples
K=0;
numex=0;
for i=1:numel(part)
	if(part{i}(ind_in_part).size==0) break; end
	K=i;
	numex=part{i}(ind_in_part).size;
end

%collect boxes and imids
boxes=zeros(numex, K*4);
imids=zeros(numex, 1);
flips=false(numex, 1);
poselet_dims=zeros(K,2);
for i=1:K
	p=part{i}(ind_in_part);
	poselet_dims(i,:)=p.dims;
	for j=1:numex

		%get the bounds
		bounds=poselet_example_bounds(p.img2unit_xforms(:,:,j), p.dims);
		
		%convert to [xmin ymin xmax ymax]
		bounds(3:4)=bounds(3:4)+bounds(1:2);
		boxes(j, (i-1)*4+(1:4))=bounds;

		%get the annotation
		annot_id=find(annot.entry_id==p.dst_entry_ids(j));
		imids(j)=find(strcmp({imglist.id},annot.img_name{annot_id})); 
		flips(j)=annot.img_flipped(annot_id);
	end
end

%initialize model
model=init_model(boxes, poselet_dims, K);

%get upper bound for model
ub_constr=get_ub_constraints(model);

%get positive features
posimids=unique(imids);
posfeats=[];
fprintf('Getting positive features\n');
for k=1:numel(posimids)
	imid=posimids(k);
	img=imread(imglist(imid).im);
	flipimg=img(:,end:-1:1,:);	
	
	boxes1=boxes(imids(:)==imid & flips==0,:);
	if(~isempty(boxes1))
		
		
		[hogfeats,deffeats]=box2features_tree(boxes1, img, model);
		f=[hogfeats; deffeats];
		posfeats=[posfeats f];
	end
	boxes1=boxes(imids(:)==imid & flips==1,:);
	if(~isempty(boxes1))
		[hogfeats,deffeats]=box2features_tree(boxes1, flipimg, model);
		f=[hogfeats; deffeats];
		posfeats=[posfeats f];
	end

	fprintf('.');
end
fprintf('*\n');

%sample random negatives
numneg=2000;
numper=round(numneg/numel(negimglist));
negfeats=[];
fprintf('Sampling negative features\n');
for k=1:numel(negimglist)
	imid=k;
	img=imread(negimglist(imid).im);
	[pyr, img2f, f2img]=featpyramid_plus(img, model);
	negboxes=sample_negatives(pyr, img2f, f2img, model, numper);
	if(isempty(negboxes)) continue; end
	[hogfeats, deffeats]=box2features_pyr_tree(negboxes, pyr, img2f, model);

	f=[hogfeats; deffeats];
	negfeats=[negfeats f];

	if(rem(k-1,10)==0) fprintf('.'); end
end
fprintf('*\n');

% train initial model with contraint
[w, bias] = svm_solver_train_ub([ones(size(posfeats,2),1); -ones(size(negfeats,2),1)], [posfeats negfeats], training_opts.c,ub_constr);
m1.w = w';
m1.w(end+1)=bias;
model=update_model(model,m1.w);
weights=m1.w;

save(fullfile(model_dir, 'initial_model.mat'), 'model');

%bootstrap
num_rounds=training_opts.bootstrap.num_rounds;
keep_thresh=training_opts.bootstrap.keep_thresh;
svm_thresh=training_opts.bootstrap.svm_thresh;
max_untrained=training_opts.bootstrap.max_untrained;

%Discard negative feats that are below the threshold
scores=weights(1:end-1)*negfeats + weights(end);
to_keep=find(scores>=keep_thresh);
negfeats=negfeats(:,to_keep);

%initialize for bootstrapping
hardfeats=zeros(size(posfeats,1), max_untrained);
count_hard=0;

%use as negative set the positives also
posimglist=imglist(ismember({imglist.id}, annot.img_name));
negimglist=[negimglist(1:200) posimglist(1:200)]; 


num_svm_calls=0;
for k=1:num_rounds
	fprintf('Bootstrapping round:%d\n', k);
	for l=1:numel(negimglist)
		fprintf('Doing :%d\n',l);
		
		%detect on negative image
		img=imread(negimglist(l).im);
		[pyr, img2f, f2img]=featpyramid_plus(img, model);
		boxes=run_kposelet_tree_dt(pyr, img2f, f2img, model, model.thresh+svm_thresh);
		if(isempty(boxes)) continue; end
		fprintf('Found %d boxes\n', size(boxes,1));		

		%check if there are people in this image
		annotidx=find(~annot.img_flipped & strcmp(annot.img_name, negimglist(l).id));
		if(~isempty(annotidx))
		
			%people here

			%get pred torsos
			torsos = get_torso_predictions(boxes, kpid*ones(size(boxes,1),1), kps);
			tt=annot.coords(torso_ks, 1:2, annotidx);
			gt_bounds = [min(tt,[],1) max(tt,[],1)-min(tt,[],1)]; clear tt;
			gt_bounds = permute(gt_bounds,[3 2 1]);
	
			%
			iou=inters_union(gt_bounds, torsos);
			max_iou=max(iou,[],1);
			boxes=boxes(max_iou<training_opts.disc_training_ov_thresh,:);

		end
		%get feats corresponding to the detection
		[hogfeats, deffeats]=box2features_pyr_tree(boxes, pyr, img2f, model);
		f=[hogfeats; deffeats];
		hardfeats(:,count_hard+1:count_hard+size(f,2))=f;	
		count_hard=count_hard+size(f,2);
		%if enough, bootstrap
		if(count_hard>=max_untrained)
			hardfeats=hardfeats(:,1:count_hard);
			fprintf('Retraining\n');
			feats=[posfeats negfeats hardfeats];
			labels=[ones(size(posfeats,2),1); -ones(size(negfeats,2)+size(hardfeats,2),1)];
            
	        [w, bias] = svm_solver_train_ub(labels, feats, training_opts.c,ub_constr,weights');
	        m1.w = w';
	        m1.w(end+1)=bias;
	        model=update_model(model,m1.w);
	        weights=m1.w;
            
			
			%see which negatives to keep
			negfeats=[negfeats hardfeats];
			scores=weights(1:end-1)*negfeats + weights(end);
			to_keep=find(scores>=keep_thresh);
			negfeats=negfeats(:,to_keep);
			%negfeats=[negfeats hardfeats(:,to_keep)];
			size(negfeats)
			count_hard=0;

		end
	end
		
	fprintf('[done]\n');
end
hardfeats=hardfeats(:,1:count_hard);
fprintf('*');
save(fullfile(model_dir, 'final_model.mat'), 'model');
diary off;
%set kpid and name
model.name=name;
model.kpid=kpid;


function model=update_model(model,wts)
numparts=size(model.sizes,1);
cnt=0;
for i=1:numparts
	w1=wts(cnt+1:cnt+prod(model.sizes(i,:))*32);
	cnt=cnt+prod(model.sizes(i,:))*32;
	model.w{i}=reshape(w1, [model.sizes(i,:) 32]);
end
for i=2:numparts
	w1=wts(cnt+1:cnt+4);
	cnt=cnt+4;
	model.defw{i}=w1;
end
model.thresh=-wts(end);


function iou = inters_union(bounds1,bounds2)

inters = rectint(bounds1,bounds2);
ar1 = bounds1(:,3).*bounds1(:,4);
ar2 = bounds2(:,3).*bounds2(:,4);
union = bsxfun(@plus,ar1,ar2')-inters;

iou = inters./(union+0.001);




