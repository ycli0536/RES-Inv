clear

Config_file = 'ModelsDesign.ini';
PATH = config_parser(Config_file, 'PATH');
savePath = PATH.savePath_PC;
if exist(savePath, 'dir') == 0;     mkdir(savePath);     end

miniSize = 50;
casing_con_par = 1e4;
casing_con_base = 5e6;
num_segments = 10;
th = zeros(1, num_segments);
nodes = zeros(1, num_segments+1);
nodes(1) = 0;

% factor = 1.2;
factor = 1;
th(1) = 3;
for i=2:num_segments
    th(i) = th(i-1) * factor;
    temp = round(th(i-1));
    nodes(i) = nodes(i-1) - temp * miniSize;
end
th = round(th);
mesh_num = sum(th);
depth_max = -miniSize * mesh_num;
nodes(end) = depth_max;

C = cell(length(casing_con_par) * num_segments + 1, 1);
casingLoc = [zeros(num_segments, 4) nodes(1:end-1)' nodes(2:end)'];
casingCon = casing_con_base * ones(num_segments, 1);
% casingCon_ini = casing_con_par(end); % (casing_con_base)
C{1, 1} = [casingLoc casingCon];
k = 2;

for i=1:length(casing_con_par)
    for j = 1:num_segments
        casingCon = casing_con_base * ones(num_segments, 1);
        casingCon(j) = casing_con_par(i);
        C{k, 1} = [casingLoc casingCon];
        k = k + 1;
    end
end

num_segments = ones(length(casing_con_par)*num_segments+1, 1); % k-1
% save Cell data C and num_segments
data_name = 'casing_Loc_Con_test_1.mat';
save([savePath data_name], 'C', 'num_segments');
fprintf('data savePATH: %s \n', [savePath data_name]);
