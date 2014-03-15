function a = struct_concat(a1,a2)

if ~isstruct(a1) || ~isstruct(a2)
    error('Inputs have to be structs');
end
a = a1;

fields = fieldnames(a1);
for i=1:numel(fields)
    value1 = getfield(a1, fields{i});
    value2 = getfield(a2, fields{i});
    if strcmp(fields{i},'coords')
        value = cat(3,value1,value2);
    elseif strcmp(fields{i},'visible')
        value = [value1 value2];
    else
        value = [value1;value2];
    end
    a = setfield(a,fields{i},value);
end
a.entry_id=uint16([1:size(a.coords,3)])';

