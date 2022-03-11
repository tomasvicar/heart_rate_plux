clc;clear all; close all;


path = 'D:\data_vo_rate';


rng(42)

data_names = subdir([path '/*.txt']);
data_names = {data_names.name};


heart_rates = [];

for file_num = 1:length(data_names)


    signal_file_name = data_names{file_num}



    data = readtable(signal_file_name,'Delimiter',';');

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

    heart_rates = [heart_rates,heart_rate];

    hold off
    plot(for_detection)
    hold on
    plot(detected_qrs_position,threshold*ones(1,length(detected_qrs_position)),'*');
    title([num2str(heart_rate)  '   ' num2str(file_num)])
    pause(3)


end


filename = {};
for file_num = 1:length(data_names)


    signal_file_name = data_names{file_num};

    [~,tmp,~] = fileparts(signal_file_name);

    filename = [filename,tmp];


end


[filename,ind] = sort(filename);
heart_rate = heart_rates(ind);

filename = filename';
heart_rate = heart_rate';

T = table(filename,heart_rate);


writetable(T ,[path '/heart_rate_ecg.xlsx'])



