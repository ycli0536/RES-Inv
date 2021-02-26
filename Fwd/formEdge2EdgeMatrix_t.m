function Edge2Edge = formEdge2EdgeMatrix_t(edges,lengths)

    Nedges = size(edges,1);

    % form Edge2Edge (matrix to be multiplied by edgeCon)
    Edge2Edge = spdiags(1./lengths,0,Nedges,Nedges);

end
