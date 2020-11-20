
function [C ,ids, intersectL, casingCon_discrete] = casingCon_generation(Length_VH, edgeSize, n, Count)
% Length_VH: [lengthV, lengthH] must be integer multiple of edgeSize 
% edgeSize: The edge length
% n: Discrete to 1/n of the original length of each edge
% Count: The number of samples to be generated

    LengthV = Length_VH(1);
    LengthH = Length_VH(2);
    blk_numV = LengthV/edgeSize;
    blk_numH = LengthH/edgeSize; % assumed X-direction and minSize in X,Y,Z directions are the same
    
    pseudo_nodes = -(0:blk_numV + blk_numH) * edgeSize;
    nodesV = -(0:blk_numV) * edgeSize;
    nodesH = (0:blk_numH) * edgeSize;
    
    casingLocV = [zeros(blk_numV, 4) nodesV(1:end-1)' nodesV(2:end)'];
    casingLocH = [nodesH(1:end-1)' nodesH(2:end)' zeros(blk_numH, 2) -LengthV*ones(blk_numH, 2)];
    casingLoc = [casingLocV; casingLocH];
    
    intact_casingCon = 1.5e5;
    casingCon = intact_casingCon * ones(blk_numV + blk_numH, 1);
    C = cell(Count,1);
    C{1, 1} = [casingLoc casingCon];
    ids = nan(Count, 3);
    casingCon_discrete = nan((LengthV + LengthH) / (edgeSize / n) + 1, 2 * Count);
    intersectL = nan(length(pseudo_nodes) - 1, Count);
    for k = 2:Count + 1
        
        % measured depth and length of corrosion or damage
        rangeL_gen = 1;
        while rangeL_gen == 1
            % Upper boundary (measured depth) of casing corrosion or damage
            Tb = -(LengthV + LengthH) * rand;
            % Length of corrosion or damage
            rangeL = 300 * rand;
            if Tb - rangeL > -(LengthV + LengthH) % upper boundary above max measured depth
                % Lower boundary of casing corrosion or damage
                Lb = Tb - rangeL;
                rangeL_gen = 0;
            end
        end

        % Severity
        % conditional casingCon value distribution (<1e5)
%         anomalous_casingCon_vertex = 10.^(5 * rand(length(sorted_nodes),1)); % random distribution in logarithmic domain
        % Equivalent conductivity transform based on current mesh scheme
        casingCon = intact_casingCon * ones(blk_numV + blk_numH, 1);
        control_points = Tb;
        new_nodes_t = [];
        for i = 1:length(pseudo_nodes) - 1
            sorted_nodes = sort([pseudo_nodes(i:i+1), Tb, Lb], 'descend');
            index = (sorted_nodes<=pseudo_nodes(i) & sorted_nodes >=pseudo_nodes(i+1)) & (sorted_nodes<=Tb & sorted_nodes>=Lb);
            if sum(index) == 0
                intersectL(i, k - 1) = 0;
                new_nodes_t = [new_nodes_t pseudo_nodes(i)];
            else
                intersectL(i, k - 1) = sorted_nodes(2) - sorted_nodes(3);
                control_point = (sorted_nodes(2) + sorted_nodes(3)) / 2;
                control_points = [control_points control_point];
            end
        end
        control_points = [control_points Lb];
        new_nodes = sort([new_nodes_t, control_points], 'descend');
        % the range of anomalous casingCon in logarithmic domain is [1, log10(intact_casingCon)]
        con_a = 1;
        con_b = log10(intact_casingCon);
        v = log10(intact_casingCon) * ones(length(new_nodes), 1);
        [~, loc, ~] = intersect(new_nodes, control_points, 'stable');
        v(loc + 1:loc + length(control_points)) = [log10(intact_casingCon); ...
            (con_b - con_a) * rand(length(control_points)-2, 1) + con_a; log10(intact_casingCon)];
        zz = linspace(0, -(LengthV + LengthH), (LengthV + LengthH) / (edgeSize / n) + 1);
        vv = pchip(new_nodes, v, zz); % Hermite interpolation (real casingCon distribution)
        figure; plot(new_nodes, v, 'o', zz, vv)
        ylim([0, con_b])
        
        for i = 1:length(pseudo_nodes) - 1
            eq_anomalous_casingRes = abs( trapz(zz(n * (i - 1) + 1: n * i + 1), 1./10.^vv(n * (i - 1) + 1: n * i + 1)) );
            casingCon(i) = edgeSize / eq_anomalous_casingRes;
        end
        
        C{k,1} = [casingLoc casingCon];
        ids(k - 1, :) = [Tb, Lb, sum(intersectL(:, k - 1) ~= 0)];
        casingCon_discrete(:, k - 1:k) = [zz' 10.^vv'];
    end
end