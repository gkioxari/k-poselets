function warped = warppatch(img, boxes, sbin, siz)
% warped = warppos(name, model, pos)
% Warp positive examples to fit model dimensions.
% Used for training root filters from positive bounding boxes.
%siz = maxsize;
%siz = siz(1:2);
pixels = double(siz * sbin);
heights = double(boxes(:,4) - boxes(:,2) + 1);
widths = double(boxes(:,3) - boxes(:,1) + 1);
numpos = size(boxes,1);
cropsize = (siz+2) * sbin;
minsize = prod(pixels);
warped  = [];
for i = 1:numpos
%if(rem(i-1,100)==0) fprintf('.'); end

  padx = sbin * widths(i) / pixels(2);
  pady = sbin * heights(i) / pixels(1);
  x1 = round(double(boxes(i,1))-padx);
  x2 = round(double(boxes(i,3))+padx);
  y1 = round(double(boxes(i,2))-pady);
  y2 = round(double(boxes(i,4))+pady);
%  pos(i).y1
  window = subarray(img, y1, y2, x1, x2, 1);
  warped{end+1} = imresize(window, cropsize, 'bilinear');
end
if numpos == 1,
  assert(~isempty(warped));
end




function B = subarray_old(A, i1, i2, j1, j2, pad)

% B = subarray(A, i1, i2, j1, j2, pad)
% Extract subarray from array
% pad with boundary values if pad = 1
% pad with zeros if pad = 0

dim = size(A);
%i1
%i2
is = i1:i2;
js = j1:j2;

if pad,
  is = max(is,1);
  js = max(js,1);
  is = min(is,dim(1));
  js = min(js,dim(2));
  B  = A(is,js,:);
else
  % todo
end



function B = subarray(A, i1, i2, j1, j2, pad)

% B = subarray(A, i1, i2, j1, j2, pad)
% Extract subarray from array
% pad with boundary values if pad = 1
% pad with zeros if pad = 0

dim = size(A);
%i1
%i2
is = i1:i2;
js = j1:j2;

if pad,
  while(any(is<1 | is>dim(1)))
    is = double(is>=1 & is<=dim(1)).*is + double(is<1).*(1-is)+double(is>dim(1)).*(2*dim(1)-is);%max(is,1);
  end
  while(any(js<1 | js>dim(2)))
     js = double(js>=1 & js<=dim(2)).*js + double(js<1).*(1-js)+double(js>dim(2)).*(2*dim(2)-js);
  end
  %js = max(js,1);
  %is = min(is,dim(1));
  %js = min(js,dim(2));
  B  = A(is,js,:);
else
    B=zeros(numel(is), numel(js), size(A,3));
    if(strcmp(class(A), 'uint8')) B=uint8(B); end
    indi=find(is>=1 & is<=dim(1));
    is=is(is>=1 & is<=dim(1));
    indj=find(js>=1 & js<=dim(2));
    js=js(js>=1 & js<=dim(2));
    B(indi, indj, :)=A(is, js,:);
  % todo
end




