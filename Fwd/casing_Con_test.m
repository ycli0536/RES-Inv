clear

Config_file = 'ModelsDesign.ini';
PATH = config_parser(Config_file, 'PATH');
savePath = PATH.savePath_PC;
if exist(savePath, 'dir') == 0;     mkdir(savePath);     end

miniSize = 50;
casing_con_base = 5e6;
depth_max = 2000;
blk_num = depth_max/miniSize;
nodes = -(0:blk_num) * miniSize;
step = 2;

casing_con_par = [1e2, 5e2, 1e3, 5e3, 1e4, 5e4, 1e5, 5e5, 1e6]; % degree of corrosion/damage
ths = 1:6; % length of corrosion/damage part
depths_length = zeros(1, length(ths));
for i = 1:length(ths)
    depths_top = 1:step:blk_num - ths(i); % depth of corrosion/damage part
    depths_length(i) = length(depths_top);
end

num = length(casing_con_par) * sum(depths_length) + 1;
C = cell(num, 1);
casingLoc = [zeros(blk_num, 4) nodes(1:end-1)' nodes(2:end)'];
casingCon = casing_con_base * ones(blk_num, 1);
C{1, 1} = [casingLoc casingCon];
n = 2;

for i = 1:length(casing_con_par)
    for j = 1:length(ths)
        depths_top = 1:step:blk_num - ths(j); % depth of corrosion/damage part
        for k = 1:length(depths_top)
            casingCon = casing_con_base * ones(blk_num, 1);
            casingCon(depths_top(k):depths_top(k)+ths(j)-1) = casing_con_par(i);
            C{n, 1} = [casingLoc casingCon];
            n = n + 1;
        end
    end
end

num_segments = blk_num * ones(num, 1); % n-1
% save Cell data C and num_segments
data_name = PATH.data_file;
save([savePath data_name], 'C', 'num_segments');
fprintf('data savePATH: %s \n', [savePath data_name]);
copyfile('ModelsDesign.ini', savePath)
