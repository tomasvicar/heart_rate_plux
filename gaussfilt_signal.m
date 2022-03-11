function [ecg_filtered] =  gaussfilt_signal(ecg,sig)

    filter_size_half = 3*sig;
    x = -filter_size_half:1:filter_size_half;
    filter = gaussmf(x,[sig 0]);

    filter = filter / sum(filter(:));
    filter_size = length(x);
    
    ecg_filtered = padarray(ecg,[floor(filter_size/2) 0],'symmetric','both');
    ecg_filtered = conv(ecg_filtered,filter,'valid');


end