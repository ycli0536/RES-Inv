% Form the source term with source current input
% function s = formSourceNearestNodes(source)
% INPUT
%     nodes: a 3-column matrix of X-Y-Z locations for the nodes (grid conjunction)
%     source: a Nsource x 4 matrix whose columns are [x y z I]; sum of I 
%     across rows must = 0
% OUTPUT
%     s: a vector of length Nnodes; mostly zero except the nodes where
%     source currents inject.
% NOTE
%     Find the nearest node and snap to it.
function s = formSourceNearestNodes(nodes,source)

Nsource = size(source,1);      

Nnodes = size(nodes,1);      
s = zeros(Nnodes,1);

for i = 1:Nsource
    dist = (nodes(:,1) - source(i,1)).^2 + (nodes(:,2) - source(i,2)).^2 + (nodes(:,3) - source(i,3)).^2;
    [~, nodeInd] = min(dist); % snap to nearest node
    s(nodeInd) = source(i,4);
end


end