% This code takes in the histogram and dataset_info files generated from the
% H5 Extracter script and generates a corresponding OME-TIFF compatible
% with FLIMfit. 
%To use this code the bioformats MATLAB toolbox must be downloaded,
%unzipped and added to path (Home -> Set Path -> Add with Subfolders)
%download here -> https://www.openmicroscopy.org/bio-formats/downloads/
%
%The fluorescence decay is encoded into the 3rd Dimension of the data
%volume and the tag "ModuloAlongT" is added into the OME metadata to allow
%the OME-TIFF to be interpreted as lifetime data by FLIMfit.
%Currently restricted to single image OME-TIFF with one channel.
%
%Written by Daniel Geddes, d.geddes.1@research.gla.ac.uk

clear all;
%% Open histogram data file and reshape

[status, version] = bfCheckJavaPath();

datafile = 'Lung 7 5s';

file_dir = ['C:\Users\Daniel Geddes\OneDrive - University of Glasgow\UCL' '\' datafile '_DataFiles\'];

hist_data = readmatrix([file_dir datafile '_' 'AlignedHistogram_Data.txt'], 'OutputType', 'int32');



dataset_info = load([file_dir datafile '_' 'InfoFile.txt']);

Image_Width = dataset_info(1); %image width
Image_Height = dataset_info(2); % image height
Num_of_Bins = dataset_info(3); %number of time bins
Time_Per_Bin = dataset_info(4); %Time per bin (ps)

% Adjust Resolution for Binned data
%Bin factor of n refers to summing n X n pixels into a single pixel
BinFactor = 1;

if BinFactor > 1
    Image_Width = floor(Image_Width / BinFactor);
    Image_Height = floor(Image_Height / BinFactor);
end

data = flip(reshape(hist_data', [Image_Width Image_Height Num_of_Bins]), 1); %Reshapes histogram


%% Create Metadata


OMEXMLService  = loci.formats.services.OMEXMLServiceImpl();
metadata = OMEXMLService.createOMEXMLMetadata();


%Basic Metadata
metadata.createRoot();
metadata.setImageID('Image:0', 0);
metadata.setPixelsID('Pixels:0', 0);
metadata.setPixelsBigEndian(javaObject('java.lang.Boolean', 'TRUE'), 0)



%DimensionOrder
dimOrder = 'XYTZC';
dimensionOrderEnumHandler = javaObject('ome.xml.model.enums.handlers.DimensionOrderEnumHandler');
dimensionOrder = dimensionOrderEnumHandler.getEnumeration(dimOrder);
metadata.setPixelsDimensionOrder(dimensionOrder, 0);


%pixelType
pixelTypeEnumHandler = javaObject('ome.xml.model.enums.handlers.PixelTypeEnumHandler');
pixelType = pixelTypeEnumHandler.getEnumeration('int32');
metadata.setPixelsType(pixelType,0);

%PixelSizes
%Converts MATLAB ints to JAVA ints
toInt = @(x) javaObject('ome.xml.model.primitives.PositiveInteger', ...
                        javaObject('java.lang.Integer', x));
%Calculate values
sizeX = size(data,2);
sizeY = size(data,1);
sizeT = size(data,3);
sizeZ = size(data, find('XYTZC' == 'Z'));
sizeC = size(data, find('XYTZC' == 'C'));

%Set Metadata
metadata.setPixelsSizeX(toInt(sizeX),0);
metadata.setPixelsSizeY(toInt(sizeY),0);
metadata.setPixelsSizeZ(toInt(sizeZ),0);
metadata.setPixelsSizeT(toInt(sizeT),0);
metadata.setPixelsSizeC(toInt(sizeC),0);


%Set Channels
metadata.setChannelID('Channel:0:0', 0, 0);
metadata.setChannelSamplesPerPixel(toInt(1), 0, 0);



                                        
% define the Modulo annotations
coreMetadata = loci.formats.CoreMetadata();

% see the loci.formats.Modulo javadoc for details of what fields can be set
% this will be turned into a Modulo XML annotation later
Time_Per_Bin_ns = Time_Per_Bin *1e-3;
coreMetadata.moduloT.step = Time_Per_Bin_ns;
coreMetadata.moduloT.end = Time_Per_Bin_ns*(Num_of_Bins-1);
coreMetadata.moduloT.type = loci.formats.FormatTools.LIFETIME;
coreMetadata.moduloT.unit = 'ns';

% moduloZ and moduloT in coreMetadata can be set in the same way if desired

% adds each of the Modulo annotations defined by coreMetadata to the OME-XML
% the '0' argument specifies the Image to which the annotations should be attached;
% for multi-Image datasets (multi-series in Bio-Formats terms) you will need to call this method
% in a loop over the number of Images
OMEXMLService.addModuloAlong(metadata, coreMetadata, 0);

writer = loci.formats.ImageWriter();
writer.setMetadataRetrieve(metadata);
         

%% Save OME-TIFF

[~, filename, ~] = fileparts(datafile);


bfsave(data, [file_dir datafile '_FLIMAligned' '.ome.tif'], 'metadata', metadata);





