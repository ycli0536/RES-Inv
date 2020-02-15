function C = casing_Con(miniSize, casing_con_base, depth_max, loop_num)
    % miniSize = 50;
    % casing_con_base = 5e6;
    % depth_max = 1500;
    % loop_num = 30000;
    
    blk_num = depth_max/miniSize;
    max_num_segments = 8;
    num_segments = unidrnd(max_num_segments, [loop_num, 1]); % defult: 1 to 8
    
    C = cell(length(num_segments),1);
    for i = 1:length(num_segments)
        % number of nodes is num_segments - 1 + 2
        nodes = sort(randperm(blk_num - 1, num_segments(i) - 1))*miniSize;
        % casing_lengths = [nodes; blk_num] - [0; nodes];
        nodes = [0 -nodes -blk_num * miniSize];
        casingLoc = [zeros(num_segments(i), 4) nodes(1:end-1)' nodes(2:end)']; % vertical well
        casingCon = casing_con_base * (1 - abs(0.1 * randn(num_segments(i), 1))); % <= 5e6
        % nearly half of casingCon become casing_con_base value
        casingCon(randperm(num_segments(i), floor(length(casingCon)/2))) = casing_con_base;
        
        C{i,1} = [casingLoc casingCon];
    end
    % save Cell data C
    data_name = 'casing_Loc_Con.mat';
    save(data_name, 'C', 'num_segments');
    fprintf('data savePATH: %s\\%s \n', pwd, data_name);
end