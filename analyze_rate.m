clc;clear all; close all;


path = 'D:\data_vo_rate';


rng(42)

data_names = subdir([path '/*.txt']);
data_names = {data_names.name};




for file_num = 1:length(data_names)


    signal_file_name = data_names{file_num};


    data = readtable(signal_file_name,'Delimiter',';');

    ecg = data.Var3;


    ecg_filtered = medfilt1(ecg,10,'truncate');
    ecg_filtered = gaussfilt_signal(ecg_filtered,10);
    ecg_filtered = ecg_filtered - gaussfilt_signal(ecg_filtered,200);


%     plot(ecg_filtered)
%     title([num2str(file_num)])
%     pause(2);

%     num_filters = 10;
% 
%     all_matched = zeros(10,length(ecg_filtered));
%     for filter_num = 1:num_filters
%         beat = load(['selected_beats/' num2str(filter_num) '.mat']);
%         beat = beat.beat;
% 
% 
%         beat = (beat - mean(beat(:))) / std(beat(:));
%         beat = beat(end:-1:1);
% 
%         filter_size = length(beat) ;
%         matched = padarray(ecg,[floor(filter_size/2) 0],'symmetric','both');
%         matched = conv(matched,beat,'valid');
%     
%         all_matched(filter_num,:) = matched;
%     end
%     matched_max = mean(all_matched,1);

    matched_max = ecg_filtered - gaussfilt_signal(ecg_filtered,20);
    matched_max = -matched_max;

    v_max = max(matched_max(:)) ;
    v_min = min(matched_max(:)) ;
    range = v_max - v_min;

%     threshold = v_min + (range/ 2);
%     prominence = range/ 3;


    threshold = v_max / 3;
    prominence = range / 2;


    max_rate = 120;
    [~,frame_positions_idx] = findpeaks( matched_max,'MinPeakHeight',threshold,'MinPeakProminence',prominence,'MinPeakDistance', 1000*(1/(max_rate/60)) );


    rate = (1 / ((frame_positions_idx(end) - frame_positions_idx(1)) / (1000 * length(frame_positions_idx))) )* 60;


    hold off
    plot(matched_max)
    hold on
    plot(frame_positions_idx,threshold*ones(1,length(frame_positions_idx)),'*');
    title([num2str(rate)  '   ' num2str(file_num)])
    pause(1)


end


