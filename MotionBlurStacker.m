classdef MotionBlurStacker < handle
properties (Access = private)
    len_factor
    align
    last_points
    last_features
    last_frame
end

methods
    function obj = MotionBlurStacker(len_factor, varargin)
        p = inputParser;
        p.addRequired('len_factor', @(x) isnumeric(x) && isscalar(x));
        p.addParameter('Align', true, @islogical);
        p.parse(len_factor, varargin{:});

        obj.len_factor = len_factor;
        obj.align = p.Results.Align;
        obj.last_features = [];
        obj.last_points = [];
        obj.last_frame = [];
    end
end

methods (Access = public)
    function blur_img = feedFrame(obj, img)
        img_gray = rgb2gray(img);

        if isempty(obj.last_frame)
            points = detectSURFFeatures(img_gray);
            [features, points] = extractFeatures(img_gray, points);

            obj.last_frame = img;
            obj.last_features = features;
            obj.last_points = points;

            blur_img = img;
            return;
        end

        if obj.align
            out_view = imref2d(size(img_gray));
            points = detectSURFFeatures(img_gray);
            [features, points] = extractFeatures(img_gray, points);
            index_pairs = matchFeatures(obj.last_features, features, 'Unique', true);
            matched_points_last = obj.last_points(index_pairs(:,1), :);
            matched_points = points(index_pairs(:,2), :);
            
            tf = estimateGeometricTransform(matched_points_last, matched_points,...
                'projective', 'Confidence', 99.9, 'MaxNumTrials', 2000);
            img_warp = imwarp(obj.last_frame, tf, 'outputview', out_view);
            
            obj.last_features = features;
            obj.last_points = points;
        else
            img_warp = obj.last_frame;
        end

        alpha = exp(log(0.1) / obj.len_factor);
        blur_img = img_warp * alpha + img * (1 - alpha);
        obj.last_frame = blur_img;
    end

    function reset(obj)
        obj.last_features = [];
        obj.last_points = [];
        obj.last_frame = [];
    end
end
end