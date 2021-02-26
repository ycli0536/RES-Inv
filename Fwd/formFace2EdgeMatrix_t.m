function Face2Edge = formFace2EdgeMatrix_t(edges,lengths,faces)
        [Nedges, ~] = size(edges);
        [Nfaces, Nepf] = size(faces);
        
        I1=repmat((1:Nfaces)',1,Nepf);
        J1=repmat((1:Nepf),Nfaces,1);
        A=[faces(:) I1(:) J1(:)];
        
        S1=faces(I1(:),:);
        S1=S1';
        S2=repmat(A(:,1)',Nepf,1);
        I2=repmat(1:size(A,1),size(S1,1),1);
        J2=repmat((1:Nepf)',1,size(S1,2));
        
        B=[S1(:) S2(:) I2(:) J2(:)];
        
        index1=(B(:,1)-B(:,2))==0;
        index12= all((edges(B(:,1),:)-repmat(edges(B(:,2),1),1,2)),2)==0;
        
        edge1=A(B(index1,3),1);
        edge_1=kron(edge1,ones(2,1));
        edge12=B(index12,1);
        index2=any((edge12-edge_1),2)==1;
        edge2=edge12(index2,:);
        
        S=lengths(edge2)./2./lengths(edge1);
        Face2Edge=sparse(edge1,A(:,2),S,Nedges,Nfaces);

end
