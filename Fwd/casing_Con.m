function [casingLoc, casingCon] = casing_Con(miniSize, casing_con_base, depth, loop_num)
    loop_num = 100;
    miniSize = 50;
    depth = 1500;
    casing_con_base = 5e6;
    blk_num = depth/miniSize;
    max_num_segments = 8;
    num_segments = unidrnd(max_num_segments, [loop_num, 1]); % defult: 1 to 8
    for i = 1:length(num_segments)
        % number of nodes is num_segments - 1 + 2
        nodes = sort(randperm(blk_num, num_segments(i) - 1))*miniSize;
        % casing_lengths = [nodes; blk_num] - [0; nodes];
        nodes = [0 -nodes -blk_num * miniSize];
        casingLoc = [zeros(num_segments(i), 4) nodes(1:end-1)' nodes(2:end)']; % vertical well
        casingCon = casing_con_base * (1 - abs(0.1 * randn(num_segments(i), 1))); % <= 5e6
    end
    % a set of base values of casings
    % casingCon_list = [1e6 5e6 2.5e6 1e7];
    
end