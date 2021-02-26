% Form the 1st order differential operator "Gradient" with edge information
% function G = formGradientMatrix(edges)
% INPUT
%     edges: a 2-column matrix of node index for the edges; 1st column for
%     starting node and 2nd column for ending node
% OUTPUT
%     G: a sparse gradient matrix mapping from potentials on nodes to
%     potential difference on edges
% NOTE
%     G is the gradient operator without the length information; only
%     contains 1 and -1; the sign convention is starting node minus ending
%     node, so potentialDiff (potential drop) and current have the same sign.
%     The assignment of starting/ending nodes is pre-defined in edges list.
function G = formPotentialDifferenceMatrix(edges)

    Nnodes = max(max(edges)); % # of nodes
    Nedges = size(edges,1); % # of edges

    % form "potential difference" (gradient) operator
    I = kron(1:Nedges,[1; 1]);
    J = edges';
    S = kron(ones(1,Nedges),[1; -1]);
    G = sparse(I(:),J(:),S(:),Nedges,Nnodes); 

end
