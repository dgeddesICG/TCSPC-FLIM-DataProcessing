%This code opens up H5 files generated from the capture of TCSPC data using
%Horiba SPAD and EzTime ver3 software. H5 files are opened and the
%individual datasets housed within are opened, reshaped and saved in a
%folder that is created in the same directory as the H5 file. There is also
%a config file that contains the values of image widths, time per bin etc.
%
%Written by Daniel Geddes, d.geddes.1@research.gla.ac.uk

clear all;

%% Set up directories

file_dir = 'C:\Users\Daniel Geddes\OneDrive - University of Glasgow\UCL';
datafile = 'Lung 7 5s.h5';
data_dir = [file_dir '\' datafile];

%Sets up new folder which will contain data extracted from the H5
[~, filename, ~] = fileparts(data_dir);
sv_dir = [file_dir '\' filename '_DataFiles'];

if ~exist(sv_dir, 'dir')
    mkdir(sv_dir)
end


%% Open H5 and strip metadata


info = h5info(data_dir);
for k = 1 : size(info.Groups.Attributes,1)
    if  info.Groups.Attributes(k).Name == "Width" %|| info.Groups.Attributes(k).Name =="ImageWidth"
        Image_Width = info.Groups.Attributes(k).Value;
    elseif  info.Groups.Attributes(k).Name == "Height" %|| info.Groups.Attributes(k).Name =="ImageHeight"
        Image_Height = info.Groups.Attributes(k).Value;
    elseif info.Groups.Attributes(k).Name == "NumberOfBins"
            Num_of_Bins = info.Groups.Attributes(k).Value;
    elseif info.Groups.Attributes(k).Name == "TimePerBin"
            Time_Per_Bin_ps = info.Groups.Attributes(k). Value * 1e12; %Converts the time per bin to PicoSeconds
    %elseif info.Groups.Attributes(k).Name == " Add as neccessasry       
        continue
    end
end


%% Extract FLIM + intensity data

Histogram_data = h5read(data_dir,'/FLIM/Histogram'); %TCSPC data
Intensity_data = h5read(data_dir,'/FLIM/Intensity'); %Autofluorescence data
FWHM_data = h5read(data_dir, '/FLIM/FWHM'); %Full-width half-max
Lifetime_data = h5read(data_dir, '/FLIM/Lifetime'); %Crude single exponential fit exported from EZtime
Snapshot_data = h5read(data_dir, '/FLIM/Snapshot'); %Not sure what this represents but EzTime includes it in the export
Sum_data = h5read(data_dir, '/FLIM/Sum'); %Sum of all histograms

%Reshape data files in to appropriate format
FWHM_data = flip(reshape(FWHM_data, [Image_Width Image_Height]),1);
Lifetime_data = flip(reshape(Lifetime_data, [Image_Width Image_Height]),1);
Intensity_data = flip(reshape(Intensity_data, [Image_Width Image_Height]),1);

%Intensity_data = reshape(Intensity_data', [Image_Height Image_Width]);

info_data = [Image_Width Image_Height Num_of_Bins Time_Per_Bin_ps]; %Note TimePerBin has been converted to PicoSeconds


%% Save Data as txt files

%Saves the data in tab delimited txt files to the newly created folder
writematrix(Histogram_data, [sv_dir '\' filename '_Histogram_Data'], 'Delimiter', 'tab')
writematrix(FWHM_data, [sv_dir '\' filename '_FWHM_Data'], 'Delimiter', 'tab')
writematrix(Lifetime_data, [sv_dir '\' filename '_Lifetime_Data'], 'Delimiter', 'tab')
writematrix(Snapshot_data, [sv_dir '\' filename '_Snapshot_Data'], 'Delimiter', 'tab')
writematrix(Sum_data, [sv_dir '\' filename '_SUM_Data'], 'Delimiter', 'tab')
writematrix(Intensity_data, [sv_dir '\' filename '_Intensity_Data'], 'Delimiter', 'tab')
% 
% %File containing properties of the data sets
writematrix(info_data, [sv_dir '\' filename '_InfoFile'], 'Delimiter', 'tab')

