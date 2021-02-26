%node2size - calculate size of cell along x/y/z direction of mesh
%
% FUNCTION h = node2size(node)
% INPUT
%   nodes: cell nodes
% OUTPUT
%   H: a vector of all the cell size
function h = node2size(node)
    h = abs(diff(node));
end
