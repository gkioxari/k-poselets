function a=select_annotations(a,sel)

a.coords = a.coords(:,:,sel);
a.visible = a.visible(:,sel);
a.bounds = a.bounds(sel,:);
a.img_flipped = a.img_flipped(sel);
a.img_name = a.img_name(sel);
a.voc_id = a.voc_id(sel);
a.entry_id = a.entry_id(sel);

end