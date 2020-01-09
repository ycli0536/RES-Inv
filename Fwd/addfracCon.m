function faceCon = addfracCon(nodeX, nodeY, nodeZ, fracLoc, fracCon, sheetsCenter)

Nx = length(nodeX);
Ny = length(nodeY);
Nz = length(nodeZ);
Nfaces = (Nx-1) * Ny * (Nz-1) + Nx * (Ny-1) * (Nz-1) + (Nx-1) * (Ny-1) * Nz;

faceCon = zeros(Nfaces,1);

if isempty(fracLoc) || isempty(fracCon)
    return;
end

% get connectivity lists from mesh definition
[nodes, edges, ~, faces, ~, ~, ~] = ...
    formRectMeshConnectivity(nodeX,nodeY,nodeZ);

Nblk = size(fracLoc,1);

% prescreen to identify object types
dim = ~[abs(fracLoc(:,1)-fracLoc(:,2))==0 ...
    abs(fracLoc(:,3)-fracLoc(:,4))==0 ...
    abs(fracLoc(:,5)-fracLoc(:,6))==0  ]; % 0 indicates that dimension vanished
objType = sum(dim,2); % dimensionality = 3 for volume, 2 for sheet, 1 for string

% Fracturing center positions
edgesCenter = 1/2 * (nodes(edges(:,1),:) + nodes(edges(:,2),:));
facesCenter = 1/4 * ( edgesCenter(faces(:,1),:) + edgesCenter(faces(:,2),:) + ...
    edgesCenter(faces(:,3),:) + edgesCenter(faces(:,4),:) );


for i = 1:Nblk
    
    xmin = min(fracLoc(i,1:2));
    xmax = max(fracLoc(i,1:2));
    ymin = min(fracLoc(i,3:4));
    ymax = max(fracLoc(i,3:4));
    zmax = max(fracLoc(i,5:6));
    zmin = min(fracLoc(i,5:6));
    
    switch objType(i)
        
        case 2 % sheet -> add to faceCon
            
            if xmin - xmax == 0 % YOZ plane
                [~, ind, indcoe] = intersect(facesCenter, [xmin*ones(length(sheetsCenter), 1) ...
                                             sheetsCenter(:,1) sheetsCenter(:,2)], 'rows', 'stable');
            elseif ymin - ymax == 0 % XOZ plane
                [~, ind, indcoe] = intersect(facesCenter, [sheetsCenter(:,1) ymin*ones(length(sheetsCenter), 1) ...
                                             sheetsCenter(:,2)], 'rows', 'stable');
            elseif zmin - zmax == 0 % XOY plane
                [~, ind, indcoe] = intersect(facesCenter, [sheetsCenter(:,1) sheetsCenter(:,2) ...
                                             zmin*ones(length(sheetsCenter), 1) ], 'rows', 'stable');
            end
            faceCon(ind) = fracCon(i)*sheetsCenter(indcoe,3);
            
        case 0 % point -> no action
            
    end
    
end
end