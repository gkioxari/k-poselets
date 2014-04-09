function annot=read_img_annotations(img_names,imglist,annot_path)
%% READ_IMG_ANNOTATIONS() returns the annotations of the images
%% INPUT
% img_names     : Nx1 cell of image names
% annot_path     : path to the annotations
%% OUTPUT
% annot         : struct. # of annotations = D
%                 coords : Kpx3xD single of the [x y z] of the Kp keypoints
%                 visible: KpxD binary of the visibility of the keypoints
%                 bounds : Dx4 single of the visible bounding boxes [x y w h]
%            img_flipped : Dx1 logical of whether annotation is flipped
%               img_name : Dx1 cell of the image names
%                 voc_id : Dx1 uint8 of the voc_id 
%               entry_id : Dx1 uint16 of the index


%% 
% Keypoint labels
kps = {'L_Shoulder','L_Elbow','L_Wrist','R_Shoulder','R_Elbow','R_Wrist',...
    'L_Hip','L_Knee','L_Ankle','R_Hip','R_Knee','R_Ankle',...
    'L_Eye','R_Eye','L_Ear','R_Ear','Nose','B_Head'};

flip_kps = [4 5 6 1 2 3 10 11 12 7 8 9 14 13 16 15 17 18];


num_kps = length(kps);

% Initialize annot struct
num=0;
annot.coords=single(nan(numel(kps),3,num));
annot.visible=false(numel(kps),num);
annot.bounds=single(zeros(num,4));
annot.img_flipped = false(zeros,1);
annot.img_name = cell(num,1);
annot.voc_id = uint8(zeros(num,1));
annot.entry_id = uint16(zeros(num,1));

img_names = unique(img_names);
files = dir(annot_path);
for i=1:numel(files)
    files_names{i}=files(i).name;
end


for i=1:length(img_names)

	if(rem(i-1,100)==0) fprintf('Doing %d/%d\n', i, numel(img_names)); end    
    % find the annotations
    img_name = img_names{i};
    kk = strfind(files_names,img_name);
    has_entry = false(numel(kk),1);
    for jj=1:length(kk)
        has_entry(jj)=~isempty(kk{jj});
    end
    ind = find(has_entry);
    
    % read the files
    for jj=1:length(ind)
        num=num+1;
        
        annot.img_name{num,1}=img_name;
        
        fid=fopen([annot_path '/' files(ind(jj)).name],'r');
        
        temp_coords = nan(num_kps,3);
        temp_visible = false(num_kps,1);
        while ~feof(fid)
            tline = fgetl(fid);
            tspace = strfind(tline,' ');
            annot_name = tline(1:tspace(1)-1);
            kp_id=find(strcmp(annot_name,kps));            
            if ~isempty(kp_id) % one of the keypoints
                x = str2num(tline(tspace(1)+1:tspace(2)-1));
                y = str2num(tline(tspace(2)+1:tspace(3)-1));
                z = str2num(tline(tspace(3)+1:tspace(4)-1));
                temp_coords(kp_id,1)=x;
                temp_coords(kp_id,2)=y;
                temp_coords(kp_id,3)=z;
                vis = tline(tspace(5)+1:end);
                if strcmp(vis,'visible')
                    temp_visible(kp_id)=true;
                end            
            elseif strcmp(annot_name,'bounds')
                x = str2num(tline(tspace(1)+1:tspace(2)-1));
                y = str2num(tline(tspace(2)+1:tspace(3)-1));
                w = str2num(tline(tspace(3)+1:tspace(4)-1));
                h = str2num(tline(tspace(4)+1:end));
                annot.bounds(num,:)=[x y w h];
            elseif strcmp(annot_name,'id_in_voc_rec')
                id_in_voc = str2num(tline(tspace(1)+1:end));
                annot.voc_id(num,1)=id_in_voc;
            end
        end
        annot.coords(:,:,num) = temp_coords;
        annot.visible(:,num) = temp_visible;
        annot.entry_id(num,1)=num;
        annot.img_flipped(num,1)=false;
        fclose(fid);
        
    end
    
end

% flip annotations
annot2 = flip_annotations(annot,flip_kps,imglist);
annot = struct_concat(annot,annot2);

annot.kps_labels = kps;


% -------------------------------------------------------------------------
function annot_flipped = flip_annotations(annot,flip_kps,imglist)

annot_flipped = annot;
num = size(annot.coords,3);
for i=1:num 
    img_dims = imglist(strcmp(annot.img_name{i},{imglist.id})).dims;
    w = img_dims(1);
    annot_flipped.coords(:,1,i)=w-annot_flipped.coords(:,1,i)+1;
    annot_flipped.coords(:,:,i) = annot_flipped.coords(flip_kps,:,i);
    annot_flipped.visible(:,i) = annot_flipped.visible(flip_kps,i);
    annot_flipped.img_flipped(i,1)=true;
    x1 = annot.bounds(i,1); y1 = annot.bounds(i,2);
    x2 = annot.bounds(i,1)+annot.bounds(i,3); y2 = annot.bounds(i,2)+annot.bounds(i,4);
    x1 = w-x1+1; x2 = w-x2+1;
    bounds = [min([x1 y1;x2 y2],[],1) max([x1 y1;x2 y2],[],1)-min([x1 y1;x2 y2],[],1)];
    annot_flipped.bounds(i,:)=bounds; clear bounds;
    annot_flipped.entry_id(i,:)=i+num;
end


% -------------------------------------------------------------------------

