% calculate size of cell along x/y/z direction of mesh
% cell node as input
% output a vector of all the cell size
function h = node2size(node)

h = abs(diff(node));

end






