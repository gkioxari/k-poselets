function ubconstr=get_ub_contraints(model)
hogsize=0;
ubconstrdef=[];
for i=1:numel(model.w)
	hogsize=hogsize+prod(model.sizes(i,:))*model.hogsize;
	if(i>1) ubconstrdef=[ubconstrdef; inf(2,1); -0.01*ones(2,1)]; end
end
ubconstr=[inf(hogsize,1); ubconstrdef];
 
