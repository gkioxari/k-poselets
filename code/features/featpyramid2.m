function pyra = featpyramid(im, model)
% pyra = featpyramid(im, model, padx, pady);
% Compute feature pyramid.
%
% pyra.feat{i} is the i-th level of the feature pyramid.
% pyra.scales{i} is the scaling factor used for the i-th level.
% pyra.feat{i+interval} is computed at exactly half the resolution of feat{i}.
% first octave halucinates higher resolution data.
interval  = model.interval;
sbin = model.sbin;

% Select padding, allowing for one cell in model to be visible
% Even padding allows for consistent spatial relations across 2X scales
padx = max(model.maxsize(2)-1-1,0);
pady = max(model.maxsize(1)-1-1,0);
%padx = model.maxsize(2);
%pady = model.maxsize(1);
padx = ceil(padx/2)*2;
pady = ceil(pady/2)*2;




sc = 2 ^(1/interval);
imsize = [size(im, 1) size(im, 2)];
max_scale = 1 + floor(log(min(double(imsize))/(double(5*sbin)))/log(sc));
pyra.feat  = cell(max_scale + interval, 1);
pyra.scale = zeros(max_scale + interval, 1);
% our resize function wants floating point values
im = double(im);
for i = 1:interval
  scaled = resize(im, 1/sc^(i-1));
  %pad image with mirroring
  %compute feature on unpadded image
  f1=features(scaled, sbin/2);
  f2=features(scaled, sbin);
 
  %find the size of image required
  sz1=size(f1); sz1=sz1(1:2);
  currpadx1=(sz1(2)+(padx+1)*2)*sbin/2 +sbin - size(scaled,2);   
  currpady1=(sz1(1)+(pady+1)*2)*sbin/2 +sbin- size(scaled,1); 
  sz2=size(f2); sz2=sz2(1:2);
  currpadx2=(sz2(2)+(padx+1)*2)*sbin+2*sbin - size(scaled,2);
   currpady2=(sz2(1)+(pady+1)*2)*sbin+2*sbin - size(scaled,1);

  scaled1=pad_image_with_mirror(scaled, currpadx1, currpady1);
  scaled2=pad_image_with_mirror(scaled, currpadx2, currpady2);
  %keyboard
  

  % "first" 2x interval
  pyra.feat{i} = features(scaled1, sbin/2);
  pyra.scale(i) = 2/sc^(i-1);
  % "second" 2x interval
  pyra.feat{i+interval} = features(scaled2, sbin);
  pyra.scale(i+interval) = 1/sc^(i-1);
  % remaining interals
for j = i+interval:interval:max_scale
    scaled = reduce(scaled);
	f2=features(scaled, sbin);
	sz2=size(f2); sz2=sz2(1:2);
    currpadx2=(sz2(2)+(padx+1)*2)*sbin+2*sbin - size(scaled,2);
    currpady2=(sz2(1)+(pady+1)*2)*sbin+2*sbin - size(scaled,1);
	scaled2=pad_image_with_mirror(scaled, currpadx2, currpady2);
	



    pyra.feat{j+interval} = features(scaled2, sbin);
    pyra.scale(j+interval) = 0.5 * pyra.scale(j);
  end
end
pyra.scale    = model.sbin./pyra.scale;
pyra.interval = interval;
pyra.imy = imsize(1);
pyra.imx = imsize(2);
pyra.pady = pady;
pyra.padx = padx;

function newf=mypadarray(f, amt, val)
newsize=size(f)+2*amt;
startpos=amt+1;
endpos=startpos+size(f)-1;
newf=val*ones(newsize);
newf(startpos(1):endpos(1), startpos(2):endpos(2), startpos(3):endpos(3))=f;


function im2=pad_image_with_mirror(img, padx, pady)
padx1=floor(padx/2);
pady1=floor(pady/2);
padx2=padx-padx1;
pady2=pady-pady1;

im2=subarray(img, -pady1, size(img,1)+pady2, -padx1, size(img,2)+padx2,1);



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




