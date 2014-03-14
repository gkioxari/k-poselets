function a=struct_select(a,sel)

if ~isstruct(a)
    error('Input 1 has to be a struct');
end

fields = fieldnames(a);
for i=1:numel(fields)
    value = getfield(a, fields{i});
    if strcmp(fields{i},'coords')
        value = value(:,:,sel);
    elseif strcmp(fields{i},'visible')
        value = value(:,sel);
    elseif strcmp(fields{i},'bounds')
        value = value(sel,:);
    elseif strcmp(fields{i},'img_size')
        value = value(sel,:);
    else
        value = value(sel);
    end
    a = setfield(a,fields{i},value);
end

end