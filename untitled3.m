clc;clear all; close all;


filenames = subdir('../Sada_02/*_dual_m_dual_m*');

for file_num = 1:length(filenames)
    filename = filenames(file_num).name;
    filename_out = replace(filename,'_dual_m_dual_m','_dual_m');

    movefile(filename, filename_out);
end

