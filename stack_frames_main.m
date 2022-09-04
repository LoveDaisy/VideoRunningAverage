clear; close all; clc;

data_folder = '.';
video_name = 'IMG_6724.MOV';

figure(1); clf;
stacked_img = stack_frames(data_folder, video_name, ...
    'Scale', 0.25, 'Display', true, 'TimeRange', [1.6, 2.0]);
