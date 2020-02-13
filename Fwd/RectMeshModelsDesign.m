function [nodeX, nodeY, nodeZ, edgeCon, faceCon, cellCon, minSize] = RectMeshModelsDesign(singleFracSheet_loc, singleFracCon)
% 1. Design a forced rectangular mesh by setting some layout parameters
% 2. Design conductivity models based on the mesh and conductivity settings 

%---Setup
% layered earth
earthLoc = [-inf inf -inf inf 0 -800;
            -inf inf -inf inf -800 -1050;
            -inf inf -inf inf -1050 -1400;
            -inf inf -inf inf -1400 -1600;
            -inf inf -inf inf -1600 -1800;
            -inf inf -inf inf -1800 -2000;
            -inf inf -inf inf -2000 -inf];
earthCon = [1/80; 1/20; 1/500; 1/30; 1/200; 1/30; 1/200];
% earthCon = [1/500; 1/500; 1/500; 1/500; 1/500; 1/500; 1/500];

casing_con = 5e6;

% fracturing sheet
fracLoc = singleFracSheet_loc;
fracCon = singleFracCon;

% central well
well1Loc = [0     0    0   0    0  -1900;
            0  1000   0   0  -1900 -1900];
well1Con = [casing_con; casing_con];

% north well
well2Loc = [0   0   50   50   0  -1900;
            0   0   50  250  -1900 -1900;
            0  500  250  250  -1900 -1900];
well2Con = [casing_con; casing_con; casing_con];

% south well
well3Loc = [0   0   -50   -50   0  -1900;
            0   0   -250  -50  -1900 -1900;
            0  500  -250  -250  -1900 -1900];
well3Con = [casing_con; casing_con; casing_con];

blkLoc = [earthLoc; fracLoc; well1Loc; well2Loc; well3Loc];
blkCon = [earthCon; fracCon; well1Con; well2Con; well3Con];

% Some other mesh parameters
coreVolume = [-400 400 -400 400  0  -2200];
minSize = [50 50 50];
paddings = [10000 10000  10000 10000  0 10000];
forcedNodeX = 0;
forcedNodeY = 0;
forcedNodeZ = 0;

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
end





