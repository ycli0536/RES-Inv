% Form the mapping matrix that transform cell conductivity model (cellCon in S/m)
% to conductance on edges; mesh-independent.
% function Cell2Edge = formCell2EdgeMatrix_t(edges,lengths,faces,cells)
% INPUT
%     edges:  a 2-column matrix of node index for the edges; 1st column for
%     starting node and 2nd column for ending node
%     lengths: a vector of the edges' lengths in meter
%     faces: a 4-column matrix of edge index for the faces
%     cells: a 6-column matrix of face index for the cells
%     volumes: a vector of the cells' volume in cubic meter
% OUTPUT
%     Cell2Edge: a Nedges x Ncells matrix that is equivalent to cellVolume/length/length
% NOTE
%     Suppose cellCon is the cell conductivity vector defined on all of the
%     cells. Cc = Cell2Edge * cellCon gets the conductances of the
%     equivalent resistors defined on the edges. The total conductance from
%     a cell is equally distributed to all its edges.
function Cell2Edge = formCell2EdgeMatrix_t(edges,lengths,faces,cells)
%     t = tic;
    cellsbyedges=[faces(cells(:,1),:) faces(cells(:,2),:) faces(cells(:,3),:) ...
                  faces(cells(:,4),:) faces(cells(:,5),:) faces(cells(:,6),:)];
    cellsbyedges=sort(cellsbyedges,2);
    cellsbyedges=cellsbyedges(:,1:2:size(cellsbyedges,2)-1);
    [Nedges, ~] = size(edges); 
    [Ncells, Nepc] = size(cellsbyedges); % Nepc: # of edges per cell
    I=repmat((1:Ncells)',1,size(cellsbyedges,2));% # of cells
    J=repmat((1:Nepc),size(cellsbyedges,1),1); % index in each cells
    
    A=[cellsbyedges(:) I(:) J(:)];
    
    t1=cellsbyedges(A(:,2),:);
    t2=t1';
    E=repmat((A(:,1))',Nepc,1);
    r=repmat(1:size(A,1),size(t1,2),1);
    R=r(:);
    c=repmat((1:Nepc)',1,size(t1,1));
    C=c(:);
    B=[t2(:) E(:) R C];
%     toc(t)
%     
%     tt = tic;
    index1=(B(:,1)-B(:,2))==0;
%     loc1=A(R(index1),2:3);
%     loc_1=kron(loc1,ones(3,1));
    index123= all((edges(B(:,1),:)-repmat(edges(B(:,2),1),1,2)),2)==0;
%     loc123=[A(R(index123),2) C(index123)];
%     toc(tt)
    
    edge1=A(R(index1),1);
    edge_1=kron(edge1,ones(3,1));
    edge123=B(index123,1);
    index23=any((edge123-edge_1),2)==1;
    edge23=edge123(index23,:);
    edge1_23=[edge1 transpose(reshape(edge23,2,[]))];
    
    S=lengths(edge1_23(:,2))./2.*lengths(edge1_23(:,3))./2./lengths(edge1_23(:,1));
    Cell2Edge=sparse(edge1_23(:,1),A(:,2),S,Nedges,Ncells);   
end

