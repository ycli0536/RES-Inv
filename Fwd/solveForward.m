% Solve the forward DC problem and get potentials, potential difference, 
% current, E field
% function [potentials, potentialDiffs, currents, efields] =
%                                               solveForward(G,c,s,lengths)
% INPUT
%     G: a sparse gradient matrix mapping from potentials on nodes to
%     potential difference on edges
%     c: a vector of conductance on edges
%     s: a vector of length Nnodes; mostly zero except the nodes where
%     source currents inject
%     lengths: a vector of the edges' lengths in meter; if missing [], no
%     output for efields
% OUTPUT
%     potentials: electric potentials on nodes
%     potentialDiffs: potential differences on edges
%     currents: electric currents on edges
%     efields: electric fields on edges; becomes [] if lengths = []
% NOTE
%     Original problem to solve: (-G'*C*G)*p = s
%     Here solve a modified but equivalent system: (G'*C*G+E)*p = -s
function [potentials, potentialDiffs, currents, efields] = ...
                                                solveForward(G,c,s,lengths)

[Nedges, Nnodes] = size(G);
C = spdiags(c,0,Nedges,Nedges);

E = sparse(1,1,1,Nnodes,Nnodes,1);
A = G' * C * G + E;

% direct solver
% L = chol(A,'lower'); 
% y = L \ -s;
% potentials = L' \ y;

% auto/iterative solver
% t0 = tic;
% dA = decomposition(A);
% potentials = dA \ s; 
potentials = A \ s;
% toc(t0)


% save('A', 'A')
% save('s', 's')

% compute potential difference (E field) on all edges
potentialDiffs = G * potentials;

% compute current on all edges
currents = C * potentialDiffs;
                                                
if isempty(lengths)
    efields = [];
else
    efields = potentialDiffs ./ lengths;
end                                      
                                                
                                                
                                                
end