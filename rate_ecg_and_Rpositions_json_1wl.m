clc;clear all; close all;


% path = 'D:\Flickering_Test';
% save_path = 'D:\Flickering_Test_Rpos';

% path = '../Sada_02';
% save_path = '../results_vo_rate_Rpos';

path = '../../Sada03';
save_path = '../../Sada03_results_vo_rate_Rpos';


rng(42)
pauza = 0.5;

data_names = subdir([path '/*.txt']);
data_names = {data_names.name};


before = [];
during = [];
after = [];

for file_num = 1:length(data_names)


    signal_file_name = data_names{file_num};
    video_file_name = replace(signal_file_name,'.txt','.avi');
    flicker_file_name = replace(signal_file_name,'.txt','_flicker.json');



    disp(file_num)
    disp(video_file_name)
    
    vidObj = VideoReader(video_file_name);

    video_num_frames = vidObj.NumFrames;
    fps = vidObj.FrameRate;

    flicker = jsondecode(fileread(flicker_file_name));


    data = readtable(signal_file_name,'Delimiter',';');


    [~, tmp] = min(abs(data.Var1 - duration(flicker.flicker_start(1))));
    flicker.flicker_start_signal_idx = tmp;
    [~, tmp] = min(abs(data.Var1 - duration(flicker.flicker_end)));
    flicker.flicker_end_signal_idx = tmp;

    triger = data.Var5;

    triger(1:1200) = triger(1200);

    [~,frame_positions_idx] = findpeaks( diff(triger),'MinPeakHeight',10000,'MinPeakDistance', (1000/fps)*0.6 );
    frame_positions_idx(frame_positions_idx < 500) = [];

    if strcmp(signal_file_name, '..\..\Sada03\Gacr_03_002_01\Gacr_03_002_01.txt')

        frame_positions_idx = [frame_positions_idx(1) - (frame_positions_idx(2) - frame_positions_idx(1)); frame_positions_idx];
    end
    

    plot(triger);
    hold on
    plot(frame_positions_idx,32820*ones(1,length(frame_positions_idx)),'*');
    hold off
        
    % fdgfdgd


    if length(frame_positions_idx) ~= video_num_frames
        error("spatny pocet")
    end


    frame_idx_signal = nan(1,length(triger));
    frame_idx_signal(frame_positions_idx) = 1:length(frame_positions_idx);
    frame_idx_signal = fillmissing(frame_idx_signal,'linear','EndValues','none');

    flicker.flicker_start_frame_idx= frame_idx_signal(flicker.flicker_start_signal_idx);
    flicker.flicker_end_frame_idx= frame_idx_signal(flicker.flicker_end_signal_idx);


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
    max_rate = 125;

    if strcmp(signal_file_name, '..\..\Sada03\Gacr_03_014_01\Gacr_03_014_01.txt')
        threshold = threshold/1.5;
        prominence = prominence/1.5;
    end
    if strcmp(signal_file_name, '..\..\Sada03\Gacr_03_024_01\Gacr_03_024_01.txt')
        threshold = threshold/1.5;
        prominence = prominence/1.5;
    end
    if strcmp(signal_file_name, '..\..\Sada03\Gacr_03_024_02\Gacr_03_024_02.txt')
        threshold = threshold/1.8;
        prominence = prominence/1.8;
    end
    if strcmp(signal_file_name, '..\Sada_02\Gacr_02_020_001_dual_m\Gacr_02_020_001_dual_m.txt')
        threshold = threshold/1.5;
        prominence = prominence/1.5;
    end
    if strcmp(signal_file_name, '..\Sada_02\Gacr_02_021_001_dual_m\Gacr_02_021_001_dual_m.txt')
        threshold = threshold/1.2;
        prominence = prominence/1.2;
        max_rate = 90;
    end

    
    [~,detected_qrs_position] = findpeaks( for_detection,'MinPeakHeight',threshold,'MinPeakProminence',prominence,'MinPeakDistance', 1000*(1/(max_rate/60)) );


    heart_rate = (1 / ((detected_qrs_position(end) - detected_qrs_position(1)) / (1000 * length(detected_qrs_position))) )* 60;


    tmp = detected_qrs_position(detected_qrs_position < flicker.flicker_start_signal_idx);
    heart_rate_before_flicker = (1 / ((tmp(end) - tmp(1)) / (1000 * length(tmp))) )* 60;
    tmp = detected_qrs_position((detected_qrs_position > flicker.flicker_start_signal_idx) & (detected_qrs_position < flicker.flicker_end_signal_idx));
    heart_rate_during_flicker = (1 / ((tmp(end) - tmp(1)) / (1000 * length(tmp))) )* 60;
    tmp = detected_qrs_position(detected_qrs_position > flicker.flicker_end_signal_idx);
    heart_rate_after_flicker = (1 / ((tmp(end) - tmp(1)) / (1000 * length(tmp))) )* 60;


    before = [before,heart_rate_before_flicker];
    during = [during,heart_rate_during_flicker];
    after = [after,heart_rate_after_flicker];

    trigger_positions = frame_positions_idx;


    R_positions_frame_idx = frame_idx_signal(detected_qrs_position);
    R_positions_signal_idx_all = detected_qrs_position;
    R_positions_signal_idx = detected_qrs_position(~isnan(R_positions_frame_idx));
    R_positions_frame_idx = R_positions_frame_idx(~isnan(R_positions_frame_idx))';




    hold off
    plot(for_detection)
    hold on
    plot(detected_qrs_position,threshold*ones(1,length(detected_qrs_position)),'*');

    [~,tmp,~] = fileparts(signal_file_name);
    title([num2str(heart_rate)  '   ' num2str(file_num) '  ' replace(tmp,'_','-')])
%     pause(pauza)


%     if contains(tmp,'Gacr_02_021_001_dual_m')
%         R_positions_frame_idx = 'error - noisy ECG';
%         R_positions_signal_idx = 'error - noisy ECG';
%         R_positions_frame_idx_wl1 = 'error - noisy ECG';
%         R_positions_frame_idx_wl2 = 'error - noisy ECG';
%         heart_rate = 'error - noisy ECG';
%     end

    s = struct();
    s.R_positions_frame_idx = R_positions_frame_idx;
    s.R_positions_signal_idx = R_positions_signal_idx;
    s.R_positions_signal_idx_all = R_positions_signal_idx_all;
    s.note = 'index start from 1 (matlab notation); R_positions_frame_idxs are positions of R-wave in video frame units, R_positions_frame_idx_wl1 and wl2 are poistions of R-wave in video frame units of video wl1 or wl2, R_positions_signal_idx is in signal index units, R_positions_signal_idx_all is not croped to video part only';

    json_data = jsonencode(s);

    [~,tmp,~] = fileparts(signal_file_name);
    tmp = replace(tmp,'.txt','');
    fname = [save_path '/' tmp '/BiosignalAnalysis' '/' tmp  '_R_positions.json'];
    
    disp(tmp)

    mkdir(fileparts(fname))

    fileID = fopen(fname,'w');
    fprintf(fileID, json_data);
    fclose(fileID);



    s = struct();
    s.heart_rate = heart_rate;
    s.heart_rate_before_flicker = heart_rate_before_flicker;
    s.heart_rate_during_flicker = heart_rate_during_flicker;
    s.heart_rate_after_flicker = heart_rate_after_flicker;
    s.note = 'beats per minute measured from ecg';
    json_data = jsonencode(s);

    [~,tmp,~] = fileparts(signal_file_name);
    tmp = replace(tmp,'.txt','');
    fname = [save_path '/' tmp '/BiosignalAnalysis' '/' tmp  '_heart_rate.json'];
    
%     disp(tmp)

    mkdir(fileparts(fname))

    fileID = fopen(fname,'w');
    fprintf(fileID, json_data);
    fclose(fileID);



    s = struct();
    s.trigger_positions = trigger_positions;
    % s.trigger_positions_wl1 = trigger_positions_wl1;
    % s.trigger_positions_wl2 = trigger_positions_wl2;
    s.note = 'index start from 1 (matlab notation), detected trigger positions';
    json_data = jsonencode(s);

    [~,tmp,~] = fileparts(signal_file_name);
    tmp = replace(tmp,'.txt','');
    fname = [save_path '/' tmp '/BiosignalAnalysis' '/' tmp  '_trigger_positions.json'];
    
%     disp(tmp)

    mkdir(fileparts(fname))

    fileID = fopen(fname,'w');
    fprintf(fileID, json_data);
    fclose(fileID);




    s = flicker;
    s.note = 'index start from 1 (matlab notation), position of flicker is saved as time/index in signal/index of frame';
    json_data = jsonencode(s);

    [~,tmp,~] = fileparts(signal_file_name);
    tmp = replace(tmp,'.txt','');
    fname = [save_path '/' tmp '/BiosignalAnalysis' '/' tmp  '_flicker_strat_end.json'];
    
%     disp(tmp)

    mkdir(fileparts(fname))

    fileID = fopen(fname,'w');
    fprintf(fileID, json_data);
    fclose(fileID);


end


x = [before; during; after];

boxplot(x')


