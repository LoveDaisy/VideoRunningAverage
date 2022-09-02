classdef ImageSequenceReader < handle
properties (Access = private)
    folder
    name
    file_list
    curr_idx
    is_video
    video_reader
    time_range
end

methods
    function obj = ImageSequenceReader(folder, name, varargin)
        p = inputParser;
        p.addRequired('folder', @(x) ischar(x) && exist(x, 'dir'));
        p.addRequired('name', @ischar);
        p.addParameter('TimeRange', [0, inf], @(x) isnumeric(x) && isvector(x) && length(x) == 2);
        p.parse(folder, name, varargin{:});

        obj.folder = folder;
        obj.name = name;
        obj.file_list = dir(sprintf('%s/%s', folder, name));
        obj.curr_idx = 1;
        obj.is_video = false;
        obj.video_reader = [];
        obj.time_range = p.Results.TimeRange;

        if isempty(obj.file_list)
            warning('Cannot find file(s): %s/%s', folder, name);
            return;
        end

        if length(obj.file_list) == 1
            tokens = strsplit(obj.file_list(1).name, '.');
            if ~isempty(tokens)
                postfix = tokens{end};
                obj.is_video = strcmpi(postfix, 'mp4') || strcmpi(postfix, 'mov');
            end
        end

        if obj.is_video
            obj.video_reader = VideoReader(sprintf('%s/%s', folder, name));
            obj.time_range(1) = max(obj.time_range(1), 0);
            obj.time_range(2) = min(obj.time_range(2), obj.video_reader.Duration);
        end
        obj.reset();
    end
end

methods (Access = public)
    function res = hasNextFrame(obj)
        if obj.is_video
            res = obj.video_reader.hasFrame() && ...
                obj.video_reader.CurrentTime >= obj.time_range(1) && ...
                obj.video_reader.CurrentTime <= obj.time_range(2);
        else
            res = obj.curr_idx < length(obj.file_list);
        end
    end

    function img = readFrame(obj)
        if ~obj.hasNextFrame()
            img = [];
            return;
        end

        if obj.is_video
            img = obj.video_reader.readFrame();
        else
            img = imread(sprintf('%s/%s', obj.folder, obj.file_list(obj.curr_idx).name));
        end
        obj.curr_idx = obj.curr_idx + 1;
        img = im2double(img);
    end

    function reset(obj)
        obj.curr_idx = 1;
        if obj.is_video
            obj.video_reader.CurrentTime = obj.time_range(1);
        end
    end

    function n = totalFrames(obj)
        if obj.is_video
            n = ceil(diff(obj.time_range) * obj.video_reader.FrameRate);
        else
            n = length(obj.file_list);
        end
    end

    function idx = currentIndex(obj)
        idx = obj.curr_idx;
    end
end
end