%This code opens up H5 files generated from the capture of TCSPC data using
%Horiba SPAD and EzTime ver3 software. H5 files are opened and the
%individual datasets housed within are opened, reshaped and saved in a
%folder that is created in the same directory as the H5 file. There is also
%a config file that contains the values of image widths, time per bin etc.
%
%Written by Daniel Geddes, d.geddes.1@research.gla.ac.uk

clear all;
%% Open H5 and strip metadata

datafile = ['h5-FAD.h5'];

info = h5info(datafile);
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

Histogram_data = h5read(datafile,'/FLIM/Histogram');



Intensity_data = h5read(datafile,'/FLIM/Intensity');
FWHM_data = h5read(datafile, '/FLIM/FWHM');
Lifetime_data = h5read(datafile, '/FLIM/Lifetime');
Snapshot_data = h5read(datafile, '/FLIM/Snapshot');
Sum_data = h5read(datafile, '/FLIM/Sum');

%Reshape data files in to appropriate format
FWHM_data = reshape(FWHM_data', [Image_Width Image_Height]);
Lifetime_data = reshape(Lifetime_data', [Image_Width Image_Height]);
Intensity_data = reshape(Intensity_data', [Image_Width Image_Height]);

info_data = [Image_Width Image_Height Num_of_Bins Time_Per_Bin_ps]; %Note TimePerBin has been converted to PicoSeconds


%% Save Data as txt files for FLIM_Fit

%Sets up new folder which will contain data extracted from the H5
[~, filename, ~] = fileparts(datafile);
  if ~exist([filename '_DataFiles'], 'dir')
       mkdir([filename '_DataFiles'])
  end
data_dir = [filename '_DataFiles'];

%Saves the data in tab delimited txt files to the newly created folder
writematrix(Histogram_data, [cd '/' data_dir '/' filename '_Histogram_Data'], 'Delimiter', 'tab')
writematrix(FWHM_data, [cd '/' data_dir '/' filename '_FWHM_Data'], 'Delimiter', 'tab')
writematrix(Lifetime_data, [cd '/' data_dir '/' filename '_Lifetime_Data'], 'Delimiter', 'tab')
writematrix(Snapshot_data, [cd '/' data_dir '/' filename '_Snapshot_Data'], 'Delimiter', 'tab')
writematrix(Sum_data, [cd '/' data_dir '/' filename '_SUM_Data'], 'Delimiter', 'tab')
writematrix(Intensity_data, [cd '/' data_dir '/' filename '_Intensity_Data'], 'Delimiter', 'tab')

%File containing properties of the data sets
writematrix(info_data, [cd '/' data_dir '/' filename '_InfoFile'], 'Delimiter', 'tab')

