% This function takes in a 3D volume of histograms, X,Y,T and aligns the
% peaks in time without distorting amplitude or curve shape. The input
% volume should be formated as int32 with a shape of [width X height X
% bins]
% The output volume has the same shape as the input and is in int32's


function AlignedVolume = TimeAlignHistogram(InputVolume)

    width  = size(InputVolume,1); %width of volume - pixels
    height = size(InputVolume,2); %height of volume - pixels
    bins = size(InputVolume,3); % number of time bins in volume
    in_data_volume = InputVolume;

    %intialise volume
    out_data_volume = zeros(width,height, bins, 'int32');


    %Find location of maximum of each peak
    [~, Idx_Vol] = max(in_data_volume, [], 3);

    %Mean peak location if idx neq 0 (i.e. excludes dead pixels).
    mean_Idx = round(mean(nonzeros(Idx_Vol))); 

    for kk = 1:width
        for jj =1:height
        
        
            %Set up temp data
            temp_data = in_data_volume(kk,jj,:);
        
            temp_idx = Idx_Vol(kk,jj);
        
       
            shift = mean_Idx - temp_idx;
            %Shift data to align

            if shift > 0
                out_data_volume(kk,jj, shift +1 : end) = temp_data(1:end-shift);
            elseif shift < 0
                out_data_volume(kk,jj,1:end + shift) = temp_data(-shift+1:end);
            elseif shift == 0
                out_data_volume(kk,jj,:) = temp_data;
            end


        end
    end

AlignedVolume = out_data_volume;

end



