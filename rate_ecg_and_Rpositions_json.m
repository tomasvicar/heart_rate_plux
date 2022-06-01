clc;clear all; close all;


path = 'D:\Sada_01';
save_path = 'D:\results_vo_rate';



rng(42)
pauza = 0.5;

data_names = subdir([path '/*.txt']);
data_names = {data_names.name};



% heart_rates_ecg = [];
% R_positions_frame_idxs = {};
% R_positions_signal_idxs = {};

for file_num = 1:length(data_names)
    if file_num < 79
        continue
    end

    signal_file_name = data_names{file_num};
    video_file_name = replace(signal_file_name,'.txt','.avi');

    vidObj = VideoReader(video_file_name);

    video_num_frames = vidObj.NumFrames;


    data = readtable(signal_file_name,'Delimiter',';');

    triger = data.Var5;

    [~,frame_positions_time] = findpeaks( diff(triger),'MinPeakHeight',10000,'MinPeakDistance', (1000/25)*0.6 );

%     plot(triger);
%     hold on
%     plot(frame_positions_time,32820*ones(1,length(frame_positions_time)),'*');
%     hold off

    if (length(frame_positions_time) - video_num_frames) == 1
        frame_positions_time = frame_positions_time(1:end-1);
    end
    if (length(frame_positions_time) - video_num_frames) == -1
        frame_positions_time(end+1) = frame_positions_time(end) + (frame_positions_time(end) - frame_positions_time(end-1));
        disp('divný - video má frame navíc :(')
        disp(signal_file_name)
    end



    if (length(frame_positions_time) - video_num_frames) ~= 0
        error("spatny pocet")
    end

    frame_idx_signal = nan(1,length(triger));
    frame_idx_signal(frame_positions_time) = 1:length(frame_positions_time);
    frame_idx_signal = fillmissing(frame_idx_signal,'linear','EndValues','none');

%     plot(frame_idx_signal)


    ecg = data.Var3;


    ecg_filtered = medfilt1(ecg,10,'truncate');
    ecg_filtered = gaussfilt_signal(ecg_filtered,10);
    ecg_filtered = ecg_filtered - gaussfilt_signal(ecg_filtered,200);




    for_detection = ecg_filtered - gaussfilt_signal(ecg_filtered,5);
    for_detection = -for_detection;


    v_max = max(for_detection(:)) ;
    v_min = min(for_detection(:)) ;

    if v_max < -v_min

        for_detection = -for_detection;
    end


    v_max = max(for_detection(:)) ;
    v_min = min(for_detection(:)) ;
    range = v_max - v_min;

    threshold = v_max / 4;
    prominence = range / 2;


    max_rate = 110;
    [~,detected_qrs_position] = findpeaks( for_detection,'MinPeakHeight',threshold,'MinPeakProminence',prominence,'MinPeakDistance', 1000*(1/(max_rate/60)) );


    heart_rate = (1 / ((detected_qrs_position(end) - detected_qrs_position(1)) / (1000 * length(detected_qrs_position))) )* 60;



%     heart_rates_ecg = [heart_rates_ecg,heart_rate];


    R_positions_frame_idx = frame_idx_signal(detected_qrs_position);
    R_positions_signal_idx = detected_qrs_position(~isnan(R_positions_frame_idx));

    R_positions_frame_idx = R_positions_frame_idx(~isnan(R_positions_frame_idx))';

    


%     R_positions_frame_idxs = [R_positions_frame_idxs,num2str(R_positions_frame_idx')];
%     R_positions_signal_idxs = [R_positions_signal_idxs,num2str(R_positions_signal_idx')];

    hold off
    plot(for_detection)
    hold on
    plot(detected_qrs_position,threshold*ones(1,length(detected_qrs_position)),'*');

    [~,tmp,~] = fileparts(signal_file_name);
    title([num2str(heart_rate)  '   ' num2str(file_num) '  ' replace(tmp,'_','-')])
%     pause()


    if contains(tmp,'Gacr_01_014')
        R_positions_frame_idx = 'error - noisy ECG';
        R_positions_signal_idx = 'error - noisy ECG';
        heart_rate = 'error - noisy ECG';
    end

    s = struct();
    s.R_positions_frame_idx = R_positions_frame_idx;
    s.R_positions_signal_idx = R_positions_signal_idx;
    s.note = 'index start from 1 (matlab notation); R_positions_frame_idxs are positions of R-wave in video frame units, R_positions_signal_idx is in signal index units';

    json_data = jsonencode(s);

    [~,tmp,~] = fileparts(signal_file_name);
    tmp = tmp(1:20);
    fname = [save_path '/' tmp '/BiosignalAnalysis' '/' tmp  '_R_positions.json'];
    
    disp(tmp)

    mkdir(fileparts(fname))

    fileID = fopen(fname,'w');
    fprintf(fileID, json_data);
    fclose(fileID);



    s = struct();
    s.heart_rate = heart_rate;
    s.note = 'beats per minute measured from ecg';
    json_data = jsonencode(s);

    [~,tmp,~] = fileparts(signal_file_name);
    tmp = tmp(1:20);
    fname = [save_path '/' tmp '/BiosignalAnalysis' '/' tmp  '_heart_rate.json'];
    
%     disp(tmp)

    mkdir(fileparts(fname))

    fileID = fopen(fname,'w');
    fprintf(fileID, json_data);
    fclose(fileID);

end






% 
% 
% filename = {};
% for file_num = 1:length(data_names)
% 
% 
%     signal_file_name = data_names{file_num};
% 
%     [~,tmp,~] = fileparts(signal_file_name);
% 
%     filename = [filename,tmp];
% 
% 
% end





% [filename,ind] = sort(filename);
% R_positions_frame_idxs = R_positions_frame_idxs(ind);
% R_positions_signal_idxs = R_positions_signal_idxs(ind);
% 
% filename = filename';
% R_positions_frame_idxs = R_positions_frame_idxs';
% R_positions_signal_idxs = R_positions_signal_idxs';
% 
% 
% T = table(filename,R_positions_frame_idxs,R_positions_signal_idxs);
% 
% writetable(T ,[path '/R_positions_06_04_2022.xlsx'])


% 
% filename = filename';
% heart_rates_ecg = heart_rates_ecg';
% heart_rates_oxi1 = heart_rates_oxi1';
% heart_rates_oxi2 = heart_rates_oxi2';
% 
% hear_rates_median = median([heart_rates_ecg,heart_rates_oxi1,heart_rates_oxi2],2);
% 
% check = [heart_rates_ecg,heart_rates_oxi1,heart_rates_oxi2];
% max_minus_min = max(check,[],2) - min(check,[],2);
% 
% 
% 
% 
% 
% 
% T = table(filename,heart_rates_ecg,heart_rates_oxi1,heart_rates_oxi2,max_minus_min,hear_rates_median);
% 
% T{:,2:end} = round(T{:,2:end},1);
% 
% writetable(T ,[path '/heart_rates_11_03_2022.xlsx'])




