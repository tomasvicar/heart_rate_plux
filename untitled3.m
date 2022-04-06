clc;clear all; close all;


path = 'D:\data_vo_rate';


rng(42)

data_names = subdir([path '/*.txt']);
data_names = {data_names.name};


heart_rates_oxi1= [];
heart_rates_oxi2 = [];
heart_rates_ecg = [];

for file_num = 1:length(data_names)


    signal_file_name = data_names{file_num};



    data = readtable(signal_file_name,'Delimiter',';');

    oxi1 = data.Var6;
    oxi2 = data.Var7;

    oxi1 = oxi1(20:end);
    oxi2 = oxi2(20:end);

   


    oxi1_filtered = medfilt1(oxi1,40,'truncate');
    oxi1_filtered = gaussfilt_signal(oxi1_filtered,40);
%     oxi1_filtered = oxi1_filtered - gaussfilt_signal(oxi1_filtered,150);

    oxi2_filtered = medfilt1(oxi2,40,'truncate');
    oxi2_filtered = gaussfilt_signal(oxi2_filtered,40);
%     oxi2_filtered = oxi2_filtered - gaussfilt_signal(oxi2_filtered,150);

    hold off 
    plot(oxi1_filtered)
    hold on 
    plot(oxi2_filtered)

    pause(1)

end