function models=load_models(basedir, name, kpids)
training_opts=get_default_training_opts(basedir);
for kpid=kpids(:)'
	fprintf('Loading %d', kpid);
	model_dir=fullfile(training_opts.model_dir, name, sprintf('%05d', kpid));
	if(~exist(fullfile(model_dir, 'final_model.mat'), 'file'))
		error('Could not find file %s', fullfile(model_dir, 'final_model.mat'));
	end
	tmp=load(fullfile(model_dir, 'final_model.mat'), 'model');
	tmp.model.name=name;
	tmp.model.kpid=kpid;
	if(~isfield(tmp.model, 'anchor'))
		tmp.model.anchor=[];
		tmp.model.scaleanchor=[];
		tmp.model.defw=[];
	end
	models(kpid)=orderfields(tmp.model);
	fprintf('\n');
end
		
