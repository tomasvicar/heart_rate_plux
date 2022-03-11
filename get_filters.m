clc;clear all; close all;


path = 'D:\data_vo_rate';


rng(42)

data_names = subdir([path '/*.txt']);
data_names = {data_names.name};



beats = {};

perm = randperm(length(data_names));

for filter_num = 1:10

    signal_file_name = data_names{perm(filter_num)};


    data = readtable(signal_file_name,'Delimiter',';');

    ecg = data.Var3;


    ecg_filtered = medfilt1(ecg,10,'truncate');
    ecg_filtered = gaussfilt_signal(ecg_filtered,10);


    
    ecg_filtered = ecg_filtered(1:4000);

    plot(ecg_filtered)
    [x,y] = ginput(1);

    size = 200;
    beat = ecg_filtered(round(x)-200:round(x)+200);


    plot(beat)
    pause(1)

    
    save(['selected_beats/' num2str(filter_num) '.mat'],'beat')




end






