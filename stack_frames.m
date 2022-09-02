function stacked_img = stack_frames(folder, name, varargin)
% DESCRIPTINO
%   It reads images and stack them to get a high S/N image.
% SYNTAX
%   stacked_img = stack_frames(folder, name)
%   stacked_img = stack_frames(__, Name, Value...)
% INPUT
%   folder:         A string
%   name:           A string of video filename, or a pattern for bracket of images.
% OPTION
%   'Align':        true | false. Default is true.
%   'Scale':        A scalar. Default is 1.0.
%   'Display':      true | false. Default is false.
%   'TimeRange':    2-vector. Default is [0, inf].

p = inputParser;
p.addRequired('folder', @(x) ischar(x) && exist(x, 'dir'));
p.addRequired('name', @ischar);
p.addParameter('Align', true, @islogical);
p.addParameter('Scale', 1.0, @isnumeric);
p.addParameter('Display', false, @islogical);
p.addParameter('TimeRange', [0, inf], @(x) isnumeric(x) && isvector(x) && length(x) == 2);
p.parse(folder, name, varargin{:});

reader = ImageSequenceReader(folder, name, 'TimeRange', p.Results.TimeRange);
ref_img_gray = [];
stacked_img = 0;
img_cnt = 0;
total_img_num = reader.totalFrames();
while reader.hasNextFrame()
    img = reader.readFrame();
    if abs(p.Results.Scale - 1) > 1e-4
        img = imresize(img, p.Results.Scale);
    end
    img_cnt = img_cnt + 1;
    fprintf('processing image %d/%d...\n', img_cnt, total_img_num);

    img_gray = rgb2gray(img);
    if isempty(ref_img_gray)
        ref_img_gray = img_gray;
        if p.Results.Align
            points_ref = detectSURFFeatures(ref_img_gray);
            [features_ref, points_ref] = extractFeatures(ref_img_gray, points_ref);
            out_view = imref2d(size(ref_img_gray));
        end
        img_aligned = img;
    else
        if p.Results.Align
            points = detectSURFFeatures(img_gray);
            [features, points] = extractFeatures(img_gray, points);
            index_pairs = matchFeatures(features, features_ref, 'Unique', true);
            matched_points = points(index_pairs(:,1), :);
            matched_points_ref = points_ref(index_pairs(:,2), :);
            
            tf = estimateGeometricTransform(matched_points, matched_points_ref,...
                'projective', 'Confidence', 99.9, 'MaxNumTrials', 2000);
            img_aligned = imwarp(img, tf, 'outputview', out_view);
        else
            img_aligned = img;
        end
    end

    stacked_img = stacked_img + img_aligned;
    if p.Results.Display
        imshow(stacked_img / img_cnt, 'InitialMagnification', 'fit');
        drawnow;
    end
end
stacked_img = stacked_img / img_cnt;
end