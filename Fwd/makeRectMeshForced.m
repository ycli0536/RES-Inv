% Make rectilinear mesh using the forced nodes
% function [nodeX,nodeY,nodeZ] = makeRectMeshForced(forcedNodeX,forcedNodeY,forcedNodeZ,coreVolume,minSize,paddings)
% INPUT
%     forcedNodex, forcedNodeY, forcedNodeZ: vectors specifiying the forced
%     nodes' location in X, Y, Z; -inf or inf is accepted for the location
%     determined by padding
%     coreVolume: a vector in the form of [xmin xmax ymin ymax zmax zmin]
%     to specify the boundaries of the core volume for fine cells
%     minSize: a vector in the form of [minSizeX minSizeY minSizeZ] to
%     specify the smallest cell sizes in the core volume
%     paddings: a vector in the form of [paddingXneg paddingXpos
%     paddingYneg paddingYpos paddingZpos paddingZneg] to specify the
%     padding (BC) distance in the six directions
% OUTPUT
%     nodeX,nodeY,nodeZ: nodes' locations for the designed mesh
function [nodeX,nodeY,nodeZ] = makeRectMeshForced(forcedNodeX,forcedNodeY,forcedNodeZ,coreVolume,minSize,paddings)

expRatio = 1.3;

forcedNodeX = reshape(forcedNodeX,[],1);
forcedNodeY = reshape(forcedNodeY,[],1);
forcedNodeZ = reshape(forcedNodeZ,[],1);
minSizeX = minSize(1);
minSizeY = minSize(2);
minSizeZ = minSize(3);
paddingXneg = paddings(1);
paddingXpos = paddings(2);
paddingYneg = paddings(3);
paddingYpos = paddings(4);
paddingZpos = paddings(5);
paddingZneg = paddings(6);

% make mesh grid: 
% (1) honor block boundaries and forced nodes
nodeX = unique(forcedNodeX);
nodeX(~isfinite(nodeX)) = []; % remove inf
nodeX = sort(nodeX,1,'ascend');
nodeY = unique(forcedNodeY);
nodeY(~isfinite(nodeY)) = []; % remove inf
nodeY = sort(nodeY,1,'ascend');
nodeZ = flipud(forcedNodeZ);
nodeZ(~isfinite(nodeZ)) = []; % remove inf
nodeZ = sort(nodeZ,1,'descend');

% (2) expand outwards until core boundary
while nodeX(1) > coreVolume(1)
    nodeX = [nodeX(1)-minSizeX; nodeX];
end
while nodeX(end) < coreVolume(2)
    nodeX = [nodeX; nodeX(end)+minSizeX];
end
while nodeY(1) > coreVolume(3)
    nodeY = [nodeY(1)-minSizeY; nodeY];
end
while nodeY(end) < coreVolume(4)
    nodeY = [nodeY; nodeY(end)+minSizeY];
end
while nodeZ(1) < coreVolume(5)
    nodeZ = [nodeZ(1)+minSizeZ; nodeZ];
end
while nodeZ(end) > coreVolume(6)
    nodeZ = [nodeZ; nodeZ(end)-minSizeZ];
end

% (3) fill the gaps larger than min cell size
nodeXtmp = [];
for i = 1:length(nodeX)-1
%     nodeXtmp = [nodeXtmp; round(linspace(nodeX(i),nodeX(i+1),1+ceil((nodeX(i+1)-nodeX(i))/minSizeX))')];
    nodeXtmp = [nodeXtmp; linspace(nodeX(i),nodeX(i+1),1+ceil((nodeX(i+1)-nodeX(i))/minSizeX))'];
end
nodeX = unique(nodeXtmp);

nodeYtmp = [];
for i = 1:length(nodeY)-1
%     nodeYtmp = [nodeYtmp; round(linspace(nodeY(i),nodeY(i+1),1+ceil((nodeY(i+1)-nodeY(i))/minSizeY))')];
    nodeYtmp = [nodeYtmp; linspace(nodeY(i),nodeY(i+1),1+ceil((nodeY(i+1)-nodeY(i))/minSizeY))'];
end
nodeY = unique(nodeYtmp);

nodeZtmp = [];
for i = length(nodeZ):-1:2
%     nodeZtmp = [nodeZtmp; round(linspace(nodeZ(i),nodeZ(i-1),1+ceil((nodeZ(i-1)-nodeZ(i))/minSizeZ))')];
    nodeZtmp = [nodeZtmp; linspace(nodeZ(i),nodeZ(i-1),1+ceil((nodeZ(i-1)-nodeZ(i))/minSizeZ))'];
end
nodeZ = flipud(unique(nodeZtmp));


% (4) expand outwards until outer boundary
while nodeX(1) > coreVolume(1) - paddingXneg
    nodeX = [nodeX(1) - expRatio*(nodeX(2)-nodeX(1)); nodeX];
end
while nodeX(end) < coreVolume(2) + paddingXpos
    nodeX = [nodeX; nodeX(end) + expRatio*(nodeX(end)-nodeX(end-1))];
end
while nodeY(1) > coreVolume(3) - paddingYneg
    nodeY = [nodeY(1) - expRatio*(nodeY(2)-nodeY(1)); nodeY];
end
while nodeY(end) < coreVolume(4) + paddingYpos
    nodeY = [nodeY; nodeY(end) + expRatio*(nodeY(end)-nodeY(end-1))];
end
while nodeZ(1) < coreVolume(5) + paddingZpos
    nodeZ = [nodeZ(1) + expRatio*(nodeZ(1)-nodeZ(2)); nodeZ];
end
while nodeZ(end) > coreVolume(6) - paddingZneg
    nodeZ = [nodeZ; nodeZ(end) - expRatio*(nodeZ(end-1)-nodeZ(end))];
end

nodeX = round(nodeX*10)/10; % keep first decimal
nodeY = round(nodeY*10)/10;
nodeZ = round(nodeZ*10)/10;

% mt(nodeX,nodeY,nodeZ,[],[],[],[]);


end