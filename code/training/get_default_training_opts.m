function opts=get_default_training_opts(basedir)
if(~exist(basedir, 'file'))
	 error('Could not find: %s', fullfile(pwd,basedir));
end
opts.model_dir=fullfile(basedir, 'tmp', 'models');
opts.log_dir=fullfile(basedir, 'tmp', 'logs');
opts.bootstrap.num_rounds=2;
opts.bootstrap.keep_thresh=-1.05;
opts.bootstrap.svm_thresh=-1;
opts.bootstrap.max_untrained=2000;
opts.disc_training_ov_thresh=0.3;
opts.disc_training_kp_thresh=0.4;

opts.c=0.01;
