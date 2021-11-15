% This code takes in the txt file containing the raw histogram data and
% aligns the peaks of each decay to the mean peak location then saves the
% resulting data volume (XYT) in a seperate file.
%It is intended that this code is executed after the H5_Extractor script to
%ensure all folder directories are created correctly
%
%Written by Daniel Geddes, d.geddes.1@research.gla.ac.uk

clear all;
%% Open histogram data file and reshape

datafile = 'h5-D';
file_dir = 'C:\Users\Daniel Geddes\OneDrive - University of Glasgow\UCL';
data_dir = [file_dir '\' datafile '_DataFiles' '\'];

hist_data = readmatrix([data_dir datafile '_Histogram_Data.txt'], 'OutputType', 'int32');

dataset_info = load([data_dir datafile '_InfoFile.txt']);

Image_Width = dataset_info(1); %image width
Image_Height = dataset_info(2); % image height
Num_of_Bins = dataset_info(3); %number of time bins
Time_Per_Bin = dataset_info(4); %Time per bin (ps)

hist_data = reshape(hist_data', [Image_Width, Image_Height, Num_of_Bins]); %Reshapes histogram


%% Align Peaks


    decay_data = zeros(Image_Width,Image_Height, Num_of_Bins, 'int32');


    %Find location of maximum of each peak
    [~, Idx_Vol] = max(hist_data, [], 3);

    %Mean peak location if idx neq 0 (i.e. excludes dead pixels).
    mean_Idx = round(mean(nonzeros(Idx_Vol))); 



for kk = 1:Image_Width
        for jj =1:Image_Height
        
        
            %Set up temp data
            temp_data = hist_data(kk,jj,:);
        
            temp_idx = Idx_Vol(kk,jj);
        
       
            shift = mean_Idx - temp_idx;
            %Shift data to align

            if shift > 0
                decay_data(kk,jj, shift +1 : end) = temp_data(1:end-shift);
            elseif shift < 0
                decay_data(kk,jj,1:end + shift) = temp_data(-shift+1:end);
            elseif shift == 0
                decay_data(kk,jj,:) = temp_data;
            end


        end
    end

%% Save file

%Reshape to allow saving to txt file
sv_decay_data = reshape(permute(decay_data,[3 1 2]),[Num_of_Bins, Image_Width * Image_Height]);

%Save matrix to tab delimieted txt file in the same directory as the other
%txt files generated from H5_Extracter
writematrix(sv_decay_data, [data_dir datafile '_AlignedHistogram_Data'], 'Delimiter', 'tab');
