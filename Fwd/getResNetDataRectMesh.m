% Get potential diff data (dc data) from RESnet modeling result (rectilinear mesh)
% FUNCTION [potentialDiffs, P, PM, PN] = getResNetDataRectMesh(nodeX,nodeY,nodeZ,potentials,MNpositions)
% INPUT
%     nodeX, nodeY, nodeZ: define a lattice structure
%     potentials: a vector of potentials defined on the nodes
%     MNpositions: a list of measurement electrode M-N pairs in the format of [Mx My Mz Nx Ny Nz]
% OUTPUT
%     potentialDiffs: potential diff between M and N
%     P: the pojection matrix so that potentialDiffs = P * potentials
%     PM, PN: the individual projection matrix for M and N (P = PM - PN)
function [potentialDiffsMN, P, PM, PN] = getResNetDataRectMesh(nodeX,nodeY,nodeZ,potentials,MNpositions)

    % get M and N electrodes positions
    M = MNpositions(:,1:3);
    N = MNpositions(:,4:6);

    % if M or N involves inf, treat it as the first node (pre-determined inf reference point)
    ind = isinf(sum(M,2));
    M(ind,1:3) = repmat([nodeX(1) nodeY(1) nodeZ(1)],sum(ind),1);
    ind = isinf(sum(N,2));
    N(ind,1:3) = repmat([nodeX(1) nodeY(1) nodeZ(1)],sum(ind),1);

    % get trilinear interp matrix
    PM = formLatticeTrilinearInterpMatrix(nodeX,nodeY,nodeZ,M);
    PN = formLatticeTrilinearInterpMatrix(nodeX,nodeY,nodeZ,N);

    % differenciate potentials
    P = PM - PN;
    potentialDiffsMN = P * potentials;

end
