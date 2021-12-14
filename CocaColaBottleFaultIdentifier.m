% =========================================================================
% EE551 Assignment 1
% Production Line Visual Inspection: Coca-Cola Bottling Plant
% =========================================================================
% GEORGINA NELSON - 16332886
% =========================================================================
% 11 Datasts Provided:
% 1 - Underfilled bottles
% 2 - Overfilled bottles
% 3 - Bottles without labels
% 4 - Bottles with label but without label print
% 5 - Bottles with the label not straight
% 6 - Bottles with cap missing
% 7 - Deformed bottles
% Combinations of Faults
% Missing bottle
% Normal bottles
% All images - randomised
% =========================================================================
% Programme flows as follows:
% 	
% =========================================================================

% CLEAR ALL
clearvars; close all; clc;

% SET UP
addpath(genpath(pwd));

% DATA
%dataset = '1-Underfilled';
%dataset = '2-Overfilled';
%dataset = '3-NoLabel';
%dataset = '4-NoLabelPrint';
%dataset = '5-LabelNotStraight';
%dataset = '6-CapMissing';
%dataset = '7-DeformedBottle';
%dataset = 'Combinations';
%dataset = 'MissingBottle';
%dataset = 'Normal';
dataset = "All";

% INITIALIZE
files = dir(fullfile('./',dataset,'/*.jpg'));

correctDetections = 0;
incorrectDetections = {};
falseNegCount = 0;
falsePosCount = 0;
ind = 2;

if dataset == "All"
    [~,~,groundTruth] = xlsread('groundTruth.csv');
end

% =========================================================================
% MAIN PROGRAMME
% =========================================================================
% LOOP OVER IMAGES IN SELECTED DATASET
for i = 1:length(files)
    issues = zeros(1,9);
    % INITIALISE
    faultCount=0;

    % DATA
    imageName = files(i).name;
    output = strcat(imageName,': ');
    img = fullfile(dataset, imageName);
    image = imread(img);
    
    % =====================================================================
    % MISSING BOTTLE CHECK
    if checkBottleMissing(image)
        issues(2) = 1;
        % Ignore if centre bottle not present
        output = strcat(output,' Missing bottle (No faults detected)');  
    else
        % =================================================================
        % FAULT 1 - UNDERFILLED CHECK
        if checkBottleUnderfilled(image)
            issues(3) = 1;
            faultCount = faultCount+1;
			faultStr = ' Bottle under-filled, ';
            output = strcat(output, faultStr); 
        end
        
        % DEFORMED | OVERFILLED
        % =================================================================
        % FAULT 7 - DEFORMED CHECK
        if checkBottleDeformed(image)
            issues(9) = 1;
            faultCount = faultCount+1;
			faultStr = ' Bottle is deformed, ';
            output = strcat(output, faultStr); 
        % FAULT 2 - OVERFILLED CHECK
        elseif checkBottleOverfilled(image) % Don't count overfill if bottle is deformed
            issues(4) = 1;
			faultCount = faultCount+1;
			faultStr = ' Bottle over-filled, ';
            output = strcat(output, faultStr);
        end
        
        % =================================================================
        % FAULT 6 - CAP MISSING CHECK
        if checkCapMissing(image)
            issues(8) = 1;
			faultCount = faultCount+1;
			faultStr = ' Bottle cap is missing, ';
            output = strcat(output, faultStr);
        end
        
        % LABELS: EXISTS | PRINTED | ANGLE
        % =================================================================
        % FAULT 3 - NO LABEL CHECK
        if checkLabelMissing(image)
            issues(5) = 1;
			faultCount = faultCount+1;
			faultStr = ' Label is missing, ';
            output = strcat(output, faultStr); 
        % FAULT 4 - NO LABEL PRINT CHECK
        elseif checkLabelNotPrinted(image) % No need to check if no label
            issues(6) = 1;
			faultCount = faultCount+1;
			faultStr = ' Label printing failed, ';
            output = strcat(output,faultStr); 
        % FAULT 5 - LABEL NOT STRAIGHT CHECK
        elseif checkLabelNotStraight(image) % No need to check if no label
            issues(7) = 1;
            faultCount = faultCount+1;
			faultStr = ' Label is not straight, ';
            output = strcat(output, faultStr); 
        end
     
        % =================================================================
        % NORMAL CHECK
        if faultCount == 0
            issues(1) = 1;
            output = strcat(output,' Normal bottle: Zero faults detected');
            %output = strcat(output, '\n');
        else  
            % OUTPUT FORMATTING
            output = output(1:end-1);
            %output = strcat(output,'\n');
        end
    end
    
    if strcmpi(dataset,'All')
        [predictionResult, underDetecting] = evalPrediction(issues, groundTruth(ind,:));
        if predictionResult == 1
            correctDetections = correctDetections + 1;
        else
            incorrectDetections{end+1} = [imageName];
            if underDetecting == 1
                falseNegCount = falseNegCount+1;
            else
                falsePosCount = falsePosCount+1;
            end
        end
        ind = ind + 1;
    else
        fprintf('%s: %s', dataset, output);
        fprintf('\n');
    end
end

% =========================================================================
% PRINT SYSTEM RESULTS
if strcmpi(dataset, 'All')
    numImages = length(files);
    fprintf('\nIncorrectly Processed images:\n');
    disp(incorrectDetections);

    fprintf('\nCorrect detections: %d', correctDetections);
    fprintf('\nIncorrect detections: %d', length(incorrectDetections));
    fprintf('\n\tFalse Positives: %d', falsePosCount);
    fprintf('\n\tFalse Negatives: %d\n', falseNegCount);

    accuracy = (correctDetections/numImages)*100;

    fprintf('\nTotal Accuracy: %.2f%%\n', accuracy);
end

% =========================================================================
% EVALUATE FAULT DETECTION RESULTS FOR A SINGLE IMAGE
% RETURNS CORRECT/INCORRECT AND IF INCORRECT THEN FALSE POS OR NEG.
function [result, underDetecting] = evalPrediction(issues, truth)
    % INITIAIZE
    underDetecting = 0;
    if sum(issues) ~= sum([truth{2:10}])
        % INCORRECT
        result = 0;
        if sum(issues) < sum([truth{2:10}])
            % FALSE NEGATIVE
            underDetecting = 1;
        end
    else
        % CORRECT
        result = 1;
    end
end


% =========================================================================
% CROP TO REGION OF INTEREST
function regionOfInterest = extractROI(imageIn, x1, y1, x2, y2)
    [h, w, ~] = size(imageIn);

    % DIMENSIONS CHECK
    if x1 == 0 || y1 == 0 || x2 == 0 || y2 == 0 || x1 > w || x2 > w || y1 > h || y2 > h
        warning('[Error cropping image]: Coordinates out of bounds: (%d, %d)\n', w, h);
        return;
    else
       % RETURN CROPPED IMAGE
    regionOfInterest = imageIn(y1:y2, x1:x2, :); 
    end
end

% =========================================================================
% FAULT 0 NO CENTRE BOTTLE
function bottleMissing = checkBottleMissing(image)
	% INITIALIZE
	x1 = 110;	x2 = 240;	y1 = 1;	y2 = 280; % CENTRE OF IMAGE
	pixelThresh = 0.1;
	
    % GRAYSCALE, EXTRACT ROI ADN BINARIZE
    image = rgb2gray(image);
    ROI = extractROI(image, x1, y1,  x2, y2);
    imgBin = imbinarize(ROI, double(150/255));
    
    % BLACK PIXEL RATIO FOR ROI
    blackArea = sum(imgBin(:)==0);
    totalArea = numel(imgBin(:));
    ratio = (blackArea/totalArea);
    
    
    % CENTRE BOTTLE MISSING IF BELOW THRESH
    bottleMissing = ratio < pixelThresh;
end


% =========================================================================
% FAULT 1 BOTTLE UNDERFILLED
function bottleUnderfilled = checkBottleUnderfilled(image)
	% INITIALIZE
	x1 = 140;	x2 = 225;	y1 = 110;	y2 = 160; % CENTRE OF IMAGE
	pixelThresh = 0.1;

    % GRAYSCALE, EXTRACT ROI ADN BINARIZE
    imgGray = rgb2gray(image);
    ROI = extractROI(imgGray,  x1, y1,  x2, y2);
    imgBin = imbinarize(ROI, double(170/255));
    
    % BLACK PIXEL RATIO FOR ROI
    blackArea = sum(imgBin(:)==0);
    totalArea = numel(imgBin(:));
    ratio = (blackArea/totalArea);
	
    % BOTTLE UNDER-FILLED IF BELOW THRESH
    bottleUnderfilled = ratio < pixelThresh;
    
    % DISPLAY INTERMEDIATE IMAGES
%     subplot(1,4,1);
%     imshow(image);
%     title('Original Image');
%     drawnow;
%     
%     subplot(1,4,2);
%     imshow(imgGray);
%     title('Greyscale Image');
%     drawnow;
%     
%     subplot(1,4,3);
%     imshow(ROI);
%     title('ROI');
%     drawnow;
%     
%     subplot(1,4,4);
%     imshow(imgBin);
%     title('Binarized Image');
%     drawnow;
    
end


% =========================================================================
% FAULT 2 BOTTLE OVER-FILLED
function bottleOverfilled = checkBottleOverfilled(image)
	% INITIALIZE
	x1 = 145;	x2 = 215;	y1 = 110;	y2 = 142;
	overThresh = 0.45;

    % GRAYSCALE, EXTRACT ROI ADN BINARIZE
    imgGray = rgb2gray(image);
    ROI = extractROI(imgGray, x1, y1,  x2, y2);
    imgBin = imbinarize(ROI, double(160/255));
    
    % BLACK PIXEL RATIO FOR ROI
    blackArea = sum(imgBin(:)==0);
    totalArea = numel(imgBin(:));
    ratio = (blackArea/totalArea);
    
    % BOTTLE OVER-FILLED IF ABOVE THRESH
    bottleOverfilled = ratio > overThresh;
end


% =========================================================================
% FAULT 3 LABEL MISSING
function labelMissing = checkLabelMissing(image)
	% INITIALIZE
	x1 = 115;	x2 = 240;	y1 = 175;	y2 = 280;
	pixelThresh = 0.5;
	
	% GRAYSCALE, EXTRACT ROI ADN BINARIZE
    imgGray = rgb2gray(image);
    ROI = extractROI(imgGray, x1, y1,  x2, y2);
    imgBin = imbinarize(ROI, double(55/255));
	    
    % BLACK PIXEL RATIO FOR ROI
    blackArea = sum(imgBin(:)==0);
    totalArea = numel(imgBin(:));
    ratio = (blackArea/totalArea);
    
    % LABEL MISSING IF BELOW THRESH
    labelMissing = ratio > pixelThresh;
end


% =========================================================================
% FAULT 4 LABEL NOT PRINTED
function labelNotPrinted = checkLabelNotPrinted(image)
	% INITIALIZE
	x1 = 115;	x2 = 240;	y1 = 175;	y2 = 280;
	pixelThresh = 0.5;
	
	% GRAYSCALE, EXTRACT ROI ADN BINARIZE
    imgGray = rgb2gray(image);
    ROI = extractROI(imgGray, x1, y1,  x2, y2);
    imgBin = imbinarize(ROI, double(150/255));
	    
    % BLACK PIXEL RATIO FOR ROI
    blackArea = sum(imgBin(:)==0);
    totalArea = numel(imgBin(:));
    ratio = (blackArea/totalArea);
    
    % LABEL MISSING IF BELOW THRESH
    labelNotPrinted = ratio < pixelThresh;
end


% =========================================================================
% FAULT 5 LABEL NOT STRAIGHT
function labelNotStraight = checkLabelNotStraight(image)
	% INITIALIZE FOR TEST 1
	x1 = 110;	x2 = 250;	y1 = 180;	y2 = 230;
	pixelThresh = 0.13;
	
	% GRAYSCALE, EXTRACT ROI ADN BINARIZE
    imgGray = rgb2gray(image);
    ROI = extractROI(imgGray, x1, y1,  x2, y2);
    imgBin = imbinarize(ROI, double(50/256));

    % BLACK PIXEL RATIO FOR ROI
    blackArea = sum(imgBin(:)==0);
    totalArea = numel(imgBin(:));
    ratio = (blackArea/totalArea);
    
    % COMPARE TO THRESH
    thresholdResult = ratio >= pixelThresh;

	% ====================================================================
	% INITIALIZE FOR TEST 2
	x1 = 110;	x2 = 250;	y1 = 170;	y2 = 195;
	maxBBW = 0; maxBBH = 0;	threshBBW = 100;	threshBBH = 14;

	% GRAYSCALE, EXTRACT ROI, GET EDGES AND ATTRS
    imgGray = rgb2gray(image);
    ROI = extractROI(imgGray, x1, y1,  x2, y2);
	edges = edge(ROI, 'Canny');
    connectedComp = bwconncomp(edges);
    attrs = regionprops(connectedComp, 'BoundingBox'); 
   
    % LOOP OVER BOUNDING BOXES
    for i = 1 : length(attrs)
        boundingBox = attrs(i).BoundingBox;
        
		% FIND BB W/ LARGEST DIMS (H, W)
        if boundingBox(3) > maxBBW
            maxBBW = boundingBox(3);
        end
        if boundingBox(4) > maxBBH
            maxBBH = boundingBox(4);
        end
    end
    
    edgeResult = maxBBW <= threshBBW || maxBBH >= threshBBH;
    
    % LABEL NOT STRAIGHT IF EITHER THRESH NOT PASSED
    labelNotStraight = thresholdResult && edgeResult;
end


% =========================================================================
% FAULT 6 BOTTLE CAP MISSING
function capMissing = checkCapMissing(image)
	% INITIALIZE
	x1 = 150;	x2 = 230;	y1 = 1;	y2 = 60;
	pixelThresh = 0.1;
	
    % GRAYSCALE, EXTRACT ROI ADN BINARIZE
    imgGray = rgb2gray(image);
    ROI = extractROI(imgGray, x1, y1,  x2, y2);
    imgBin = imbinarize(ROI, double(130/255));
    
    % BLACK PIXEL RATIO FOR ROI
    blackArea = sum(imgBin(:)==0);
    totalArea = numel(imgBin(:));
    ratio = (blackArea/totalArea);
    
    % CAP MISSING IF BELOW THRESH
    capMissing = ratio < pixelThresh;
end


% =========================================================================
% FAULT 7 BOTTLE DEFORMED CHECK
function bottleDeformed = checkBottleDeformed(image)
    % INITIALIZE
    x1 = 100;    x2 = 260;    y1 = 190;    y2 = 280;
    ratioThresh = 0.8;
    maxArea = 0;    boudingBoxW = 0;   boudingBoxH = 0;
	maxAreaThreshLwr = 9800;	maxAreaThreshUpr = 12000;
	boxWThreshLwr = 110;	boxWThreshUpr = 130;
    boxHThreshLwr = 80;	boxHThreshUpr = 100;

    % CROP TO REGION OF INTEREST, EXTRACT RED AND BINARIZE
    ROI = extractROI(image, x1, y1, x2, y2);
    imgRed = ROI(:, :, 1);
    imgBinR = imbinarize(imgRed, double(200/256));
    
    % BLACK PIXEL RATIO
    blackPixels = sum(imgBinR(:)==0);
    totalPixels = numel(imgBinR(:));
    ratio = (blackPixels/totalPixels);
    
    % COMPARE TO THRESHOLD
    if ratio > ratioThresh
		% NO LEABEL: GREYSCALE
        imgGray = rgb2gray(ROI);
        binImg = imbinarize(imgGray, double(5/256));
        connectedComp = bwconncomp(binImg, 4);
    else
		% LABEL: RED CHANNEL
        connectedComp = bwconncomp(imgBinR, 4);
    end

	% GET BOUNDING BOX FOR ROI
    attrs = regionprops(connectedComp, 'BoundingBox');
    
    % LOOP OVER BOUDING BOXES
    for i = 1 : length(attrs)
        boundingBox = attrs(i).BoundingBox;
        boudingBoxArea = boundingBox(3)*boundingBox(4);
            
         % DISPLAY INTERMEDIATE IMAGES
%          ROIbb = extractROI(ROI, boundingBox(1), boundingBox(2), boundingBox(1)+boundingBox(3), boundingBox(2)+boundingBox(4)); 
%          subplot(2,5,i);
%          imshow(ROIbb);
%          title('Bounding Box');
%          drawnow;

        % GET LARGEST BOX (H, W)
        if boudingBoxArea > maxArea
            maxArea = boudingBoxArea;
            boudingBoxW = boundingBox(3);
            boudingBoxH = boundingBox(4);
        end
    end
    
	% COMPARE TO THRESHOLDS
    maxAreaRes = (maxArea >= maxAreaThreshLwr) && (maxArea <= maxAreaThreshUpr);
    maxBBW = (boudingBoxW >= boxWThreshLwr) && (boudingBoxW <= boxWThreshUpr);
    maxBBH = (boudingBoxH >= boxHThreshLwr) && (boudingBoxH <= boxHThreshUpr);
      
    % IF NOT ALL REQS MET THEN BOTTLE IS DEFORMED
    bottleDeformed = ~(maxAreaRes && maxBBW && maxBBH);
    
end
