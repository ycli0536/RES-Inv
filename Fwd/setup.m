function [nodeX, nodeY, nodeZ, edgeCon, faceCon, cellCon, minSize, source, dataLoc, E, MaxCount] = setup(Config_file, count)

RectMeshModelsDesign = config_parser(Config_file, 'RectMeshModelsDesign');
ABMN = config_parser(Config_file, 'ABMNsettings');
Mesh = config_parser(Config_file, 'Mesh');

%---Setup
earthLoc = RectMeshModelsDesign.earthLoc;
earthCon = RectMeshModelsDesign.earthCon;

blk_data = load(RectMeshModelsDesign.data_file);
blk_info = blk_data.C; % Cell data structure
blkLoc_added = blk_info{count, 1}(:, 1:6);
blkCon_added = blk_info{count, 1}(:, 7);
MaxCount = length(blk_info);

blkLoc = [earthLoc; blkLoc_added];
blkCon = [earthCon; blkCon_added];

coreVolume = Mesh.coreVolume;
minSize = Mesh.minSize;
paddings = Mesh.paddings;
forcedNodeX = Mesh.forcedNodeX;
forcedNodeY = Mesh.forcedNodeY;
forcedNodeZ = Mesh.forcedNodeZ;

%---Get forced nodes
forcedNodeX = reshape(forcedNodeX,[],1);
forcedNodeX = unique([blkLoc(:,1); blkLoc(:,2); forcedNodeX]);
forcedNodeX(~isfinite(forcedNodeX)) = []; % remove inf
forcedNodeY = reshape(forcedNodeY,[],1);
forcedNodeY = unique([blkLoc(:,3); blkLoc(:,4); forcedNodeY]);
forcedNodeY(~isfinite(forcedNodeY)) = []; % remove inf
forcedNodeZ = reshape(forcedNodeZ,[],1);
forcedNodeZ = flipud(unique([blkLoc(:,5); blkLoc(:,6); forcedNodeZ]));
forcedNodeZ(~isfinite(forcedNodeZ)) = []; % remove inf

undefined = 0; % if object value not specified

%---Make a mesh
[nodeX, nodeY, nodeZ] = makeRectMeshForced(forcedNodeX, forcedNodeY, forcedNodeZ, ...
    coreVolume, minSize, paddings);
%---Make conductivity models
[edgeCon,faceCon,cellCon] = makeRectMeshModels_t(nodeX,nodeY,nodeZ,blkLoc,blkCon,...
    undefined,minSize(1),minSize(2),0-minSize(3));

source = ABMN.source;

dataGridX = -500:20:500;
dataGridY = -500:20:500;
dataGrid = [dataGridX; dataGridY];

[dataLoc, E] = ABMNsettings(dataGrid);

end