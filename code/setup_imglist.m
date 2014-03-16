function imglist=setup_imglist(image_names,img_path)
%% SETUP_IMGLIST() returns information about the images
%% INPUT
% image_names   : Nx1 cell of image_names
% img_path      : path to the image directory
%% OUTPUT
% imglist       : Nx1 struct with information about the images
%                 id : name of image
%                 im : path to the image  
%                 dims : [width height] dimensions of image
%

for i=1:length(image_names)
    imglist(i).id = image_names{i};
    imglist(i).im = fullfile(img_path, [image_names{i} '.jpg']);
    img = imread(imglist(i).im);
    imglist(i).dims=[size(img,2) size(img,1)];
	if(rem(i-1,100)==0) fprintf('Doing %d/%d\n', i, numel(image_names)); end
    clear img;
end

