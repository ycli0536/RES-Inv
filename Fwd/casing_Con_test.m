clear

Config_file = 'ModelsDesign.ini';
PATH = config_parser(Config_file, 'PATH');
savePath = PATH.homePath_PC;
if exist(savePath, 'dir') == 0;     mkdir(savePath);     end

miniSize = 50;
casing_con_base = 1.5e5;
length_vertical = 1900;
length_horizonral = 600;
length_max = length_vertical + length_horizonral;
blk_num = length_max/miniSize; % length_max is pseudo depth
nodes = -(0:blk_num) * miniSize; % pseudo

blk_num_vertical = length_vertical/miniSize;
nodes_vertical = -(0:blk_num_vertical) * miniSize;
blk_num_horizontal = length_horizonral/miniSize;
nodes_horizontal = (0:blk_num_horizontal) * miniSize;

step = 1;

casing_con_par = [2.5, 50, 250, 750, 2e3, 5e3, 1e4, 5e4]; % degree of corrosion/damage
ths = 1:6; % length of corrosion/damage part
depths_length = zeros(1, length(ths));
start_point = 2; % where to start (depths)
for i = 1:length(ths)
    depths_top = start_point:step:blk_num - ths(i); % depth of corrosion/damage part
    depths_length(i) = length(depths_top);
end

num = length(casing_con_par) * sum(depths_length) + 1;
C = cell(num, 1);
casingLoc_v = [zeros(blk_num_vertical, 4) nodes_vertical(1:end-1)' nodes_vertical(2:end)'];
casingLoc_h = [nodes_horizontal(1:end-1)' nodes_horizontal(2:end)' zeros(blk_num_horizontal, 2) -length_vertical*ones(blk_num_horizontal, 2)];
% casingLoc = [casingLoc_v; casingLoc_h];
casingLoc = [zeros(blk_num, 4) nodes(1:end-1)' nodes(2:end)'];
casingCon = casing_con_base * ones(blk_num, 1);
C{1, 1} = [casingLoc casingCon];
n = 2;

ids = [];
for i = 1:length(casing_con_par)
    for j = 1:length(ths)
        depths_top = start_point:step:blk_num - ths(j); % depth of corrosion/damage part
        for k = 1:length(depths_top)
            casingCon = casing_con_base * ones(blk_num, 1);
            casingCon(depths_top(k):depths_top(k)+ths(j)-1) = casing_con_par(i);
            C{n, 1} = [casingLoc casingCon];
            ids = [ids; casing_con_par(i) miniSize * ths(j) miniSize * (depths_top(k) - 1)];
            n = n + 1;
        end
    end
end

num_segments = blk_num * ones(num, 1); % n-1
% save Cell data C and num_segments
data_name = PATH.casing_Loc_Con_file;
save([savePath data_name], 'C', 'num_segments', 'ids');
fprintf('data savePATH: %s \n', [savePath data_name]);
copyfile('ModelsDesign.ini', savePath)
