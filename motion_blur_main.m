clear; close all; clc;

data_folder = '/Volumes/ZJJ-8TB/Photos/22.08.27 Zhuhai Shuiyun Luhuazhou Garden';
video_name = 'IMG_6724.MOV';
len_factor = 45;

figure(1); clf;
reader = ImageSequenceReader(data_folder, video_name);
stacker = MotionBlurStacker(30);

while reader.hasNextFrame()
    fprintf('processing image %d/%d...\n', reader.currentIndex(), reader.totalFrames());
    img = reader.readFrame();
    img = stacker.feedFrame(img);
    
    if reader.currentIndex() < len_factor
        continue;
    end
    
    imwrite(uint16(img * 65535), sprintf('%s/blur frames/%s_%04d.tif', ...
        data_folder, video_name, reader.currentIndex() - len_factor));

    figure(1); clf;
    imshow(img, 'InitialMagnification', 'fit');
    drawnow;
end
