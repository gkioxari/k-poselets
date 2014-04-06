function sout = struct_select(s,sel)

names = fieldnames(s);
sout = struct;

for i=1:length(names)
    v = getfield(s,names{i});
    if strcmp(names{i},'bounds')
        v = v(sel,:);
    elseif strcmp(names{i},'coords')
        v = v(:,:,sel);
    elseif strcmp(names{i},'visible')
        v = v(:,sel);
    elseif strcmp(names{i},'kps_labels') || strcmp(names{i},'class');
        v = v;
    else
        v = v(sel,:);
    end
    
    sout = setfield(sout,names{i},v);
end

end