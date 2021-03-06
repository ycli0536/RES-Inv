%node2center - calculate location of cell center along x/y/z direction of mesh
%
% FUNCTION: center = node2center(node)
%
% INPUT
%   node: cell nodes
% OUTPUT
%   center: cell centers
function center = node2center(node)
    node = reshape(node,[],1);
    Nnode = length(node);
    W = spdiags(ones(Nnode-1,2),[0 1],Nnode-1,Nnode);
    center = W * node * 0.5;
end
