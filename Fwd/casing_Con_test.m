clear

miniSize = 50;
casing_con_par = [1e6 2e6 3e6 4e6];
casing_con_base = 5e6;
num_segments = 10;
fractor = 1.2;
th = zeros(1, num_segments);
nodes = zeros(1, num_segments+1);
th(1) = 2;
nodes(1) = 0;
for i=2:num_segments
    th(i) = th(i-1) * fractor;
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
data_name = 'casing_Loc_Con_test.mat';
save(data_name, 'C', 'num_segments');
fprintf('data savePATH: %s\\%s \n', pwd, data_name);
