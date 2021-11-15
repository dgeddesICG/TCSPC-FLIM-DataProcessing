%This function takes in an XYT volume and time per bin value 
%(in picoseconds) and saves an OME.TIFF with ModuloAlongT tag added to the
%metadata to ensure compatibillity with FLIMfit and possibly other fitting
%packages (your mileage my vary). The OME.TIFF has the format of a stack of
%images where each time slice represents an image in the stack.
%Data volumes inputted to this function should consist of 32bit integers to
%prevent endian + overflow errors corrupting the data.

function OMETIFF_Lifetime(data_volume,t_per_bin_ps, sv_dir)
    data  = data_volume;
    
    [status, version] = bfCheckJavaPath();

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
Time_Per_Bin_ns = t_per_bin_ps *1e-3;
coreMetadata.moduloT.step = Time_Per_Bin_ns;
coreMetadata.moduloT.start  =0;
coreMetadata.moduloT.end = Time_Per_Bin_ns*(sizeT-1);
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


bfsave(data, [sv_dir '.ome.tif'], 'metadata', metadata);


