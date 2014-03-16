function ubconstr=get_ub_contraints(model)
hogsize=0;
ubconstrdef=[];
for i=1:numel(model.w)
	hogsize=hogsize+numel(model.w{i});
	ubconstrdef=[ubconstrdef; inf(2,1); -0.01*ones(2,1)];
end
ubconstr=[inf(hogsize,1); ubconstrdef];
 
