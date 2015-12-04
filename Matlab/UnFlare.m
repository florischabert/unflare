clc; clear;
warning off;

mex detectFlare.cpp MxArray.cpp ../Processing/FlareDetector.cpp CXXFLAGS="$CXXFLAGS -F../" LDFLAGS="$LDFLAGS -F../ -framework opencv2"
mex inpaintFlare.cpp MxArray.cpp ../Processing/FlareInpainter.cpp CXXFLAGS="$CXXFLAGS -F../" LDFLAGS="$LDFLAGS -F../ -framework opencv2"
return;
files = dir('Images/*.jpg');
for f = 1:size(files, 1);
    image = imread(sprintf('Images/%s', files(f).name));
    
    % Detection
    params.minThreshold = 50;
    params.maxThreshold = 255;
    params.thresholdStep = 10;
    params.minDistBetweenBlobs = 50;
    
    params.filterByCircularity = true;
    params.minCircularity = 0.4;
    params.maxCircularity = 1;
    
    params.filterByArea = true;
    params.minArea = 400;
    params.maxArea = 1500;
    
    params.filterByConvexity = true;
    params.minConvexity = 0.8;
    params.maxConvexity = 1;
    
    params.filterByInertia = true;
    params.minInertiaRatio = 0.7;
    params.maxInertiaRatio = 1;
    
    mask = detectFlare(image, params);
    
    % Inpainting
    params.inpaintingType = 1;
%     inpainted = inpaintFlare(image, mask, params);

image = im2double(image) .* repmat(~mask, [1 1 3]);
[maskx, masky] = find(mask);

window = 100;
areax = max(1,min(maskx)-window/2):min(size(image,1),max(maskx)+window/2); 
areay = max(1,min(masky)-window/2):min(size(image,2),max(masky)+window/2); 
area = image(areax,areay,:);
mask = mask(areax,areay);

[max(maskx)-min(maskx), max(masky)-min(masky)]

inpainted = inpainting(area, mask, 9);

image(areax,areay,:) = inpainted;

    figure(f);
    imshow(image);
    
%     return;
end
