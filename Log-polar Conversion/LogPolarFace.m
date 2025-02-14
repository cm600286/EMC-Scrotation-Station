path = uigetdir(pwd, 'Select a folder to convert');
singleFile = "";
if path ~= 0
    folder = dir(fullfile(path, '*.png'));
    mkdir(path + " - Converted");
else
    [singleFile, path] = uigetfile('*.*', 'Select an image to convert');
    folder = struct('name', singleFile);
end
testGrid = im2double(imread("grid.png"));
[gridImg, colorMap] = imread(fullfile(pwd, "gridConverted - 500.png"));
if size(gridImg, 3) == 1; gridImg = ind2rgb(gridImg, colorMap); end
gridImg = im2double(gridImg);
gridImg = imcomplement(max(gridImg, (gridImg >= 1)));
for fileNum = 1:length(folder)
    file = folder(fileNum).name;
    [img, colorMap] = imread(fullfile(path, file));
    if size(img, 3) == 1; img = ind2rgb(img, colorMap); end
    img = im2double(img);
    imgHeight = size(img, 1);
    imgWidth = size(img, 2);
    if size(img, 3) == 1; img = 1 - img; end
    sampleImg = zeros(imgHeight, imgWidth);

    %testGrid = imresize(testGrid, [height(img), width(img)]);
    %img = max(0, (img - testGrid .* (testGrid > 0)));
    
    %% Cortical area (resultant image dimensions)
    cortWidth = imgWidth; %% width of one hemisphere of brain
    cortHeight = floor(imgHeight/2);
    background = 1; %% 0 (black) - 1 (white) background color where image not drawn
    
    %% toggle whether left and right brain images should be split or stacked
    imgSplit = false;
    newImg = ones(cortHeight * (1 + ~imgSplit), cortWidth * (1 + imgSplit)) * background;
    
    %% expCoef determines how exponential distance is represented in the cortex
    % larger numbers mean greater area on cortex is mapped to the foveal region
    % for small exponents, there will be a region in the middle that could not be converted
    % due to approaching infinity. Coefficients above 500 will show all center pixels
    expCoef = 500;
    
    %% compression refers to how much an image should be scaled down
    % a compression of 2 will mean that a circle with radius of 1800 px
    % occupies a cortical pattern with a width of 900 px. Values < 1 will scale up the image
    compression = imgWidth / cortWidth / 2; % when resize, can match size of original image
    useSigmoid = false; % sharpens image by sigmoid rather than smoothening linear function
    
    %% toggle drawing options
    stepDraw = false;
    embedGrid = true;
    
    for pixel = 1:size(img, 3)
        imgSlice = img(:, :, pixel);
        newImgSlice = ones(cortHeight * (1 + ~imgSplit), cortWidth * (1 + imgSplit)) * background;
        
        for pol = 1: cortHeight
            %% Left side Cortical image = right or bottom
            for dist = 1: cortWidth
                radius = power(expCoef, 1 - dist/cortWidth) / (expCoef - 1);
                radius = radius * cortWidth * 2 * compression;
                % Right side of retinal image: 90 to -90 degrees
                angle = (90 - pol / cortHeight * 180) * pi/180;
                [pixVal, inRange, x, y] = pixelValue(radius, angle, imgSlice, ...
                    imgWidth, imgHeight, useSigmoid);
                if inRange
                    if imgSplit; newImgSlice(pol, cortWidth - dist + 1) = pixVal;
                    else; newImgSlice(cortHeight + pol, cortWidth - dist + 1) = pixVal; end
                    sampleImg(floor(y), floor(x)) = 1;
                end
            end
    
            %% Right side of image = left or top side of cortical image
            for dist = cortWidth + 1: 2 * cortWidth
                radius = power(expCoef, dist/cortWidth - 1) / (expCoef - 1);
                radius = radius * cortWidth * 2 * compression;
                % Left side of retinal image: 90 to 270 degrees
                angle = (90 + pol / cortHeight * 180) * pi/180;
                [pixVal, inRange, x, y] = pixelValue(radius, angle, imgSlice, ...
                    imgWidth, imgHeight, useSigmoid);
                if inRange
                    if imgSplit; newImgSlice(pol, cortWidth * 3 - dist + 1) = pixVal;
                    else; newImgSlice(cortHeight - pol + 1, dist - cortWidth) = pixVal; end
                    sampleImg(floor(y), floor(x)) = 1;
                end
            end
    
            if stepDraw; imshow(newImgSlice); end
        end
        newImg(:, :, pixel) = newImgSlice;
    end

    close all;
    %figure('Name', file)
    %imshow(img);
    converted = figure('Name', file + " - Converted");
    if embedGrid
        grid = imresize(gridImg, [height(newImg), width(newImg)]);
        newImg = max(0, (newImg - grid .* (grid > 0)));
    end
    imshow(newImg);
    if singleFile == ""; saveas(converted, fullfile(path + " - Converted", file)); end
    figure(converted);

    %figure('Name', file + " - Sample Image");
    %imshow(sampleImg);
end