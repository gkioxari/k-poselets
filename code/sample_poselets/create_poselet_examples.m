function [part,examples_info]=create_poselet_examples(unit_dims, src_annot, src_patch, a, imglist, disable_rotation, stayInImage, maxZoomThresh, errThresh, minRotThresh)
%% CREATE_POSELET_EXAMPLES() creates poselet examples given a seed patch from a given annotation.
%% INPUT
% unit_dims         : normalized dimensions of the poselet [h w]
% src_patch         : location of the seed patch in the seed annotation [x_ctr y_ctr width height rotation] 
%                     The seed patch is 0-indexed, i.e. the first image pixel is (0,0) not (1,1)
% src_annot         : the seed annotation 
% a                 : the annotations to draw training examples from 
% disable_rotation  : when present and true disables rotation when matching 
%
%%% OPTIONAL PARAMETERS:
% maxZoomThresh     : excludes examples with higher zoom than this (default 4)       
% errThresh         : excludes examples with residual error higher than this (default 0.7)
% minRotThresh      : excludes examples with rotation larger than this (default 3?/4)    
% stayInImage       : excludes examples whose patch partially spans outside the image (defaul true)
%
%% OUTPUT
%   part      -- the constructed poselet

%%
if ~exist('maxZoomThresh','var') || isempty(maxZoomThresh)
   maxZoomThresh = 4; 
end

if ~exist('errThresh','var') || isempty(errThresh)
   errThresh = 0.7; 
end

if ~exist('minRotThresh','var') || isempty(minRotThresh)
   minRotThresh = pi*3/4; 
end

if ~exist('stayInImage','var') || isempty(stayInImage)
   stayInImage = true; 
end

[p1,examples_info]=create_poselet_procrustes_dist(unit_dims, src_annot, src_patch, a, imglist, disable_rotation);
maxScale = maxZoomThresh/min(unit_dims);
part = p1.select(examples_info.scale<=maxScale & p1.errs'<=errThresh & ...
    (~stayInImage | ~examples_info.out_of_image) & ...
    ~examples_info.out_of_instance & ...
    (examples_info.rot<=pi-minRotThresh & examples_info.rot>=-pi+minRotThresh));
