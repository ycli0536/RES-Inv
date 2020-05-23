% PC terminal
% savePath_HPC -> savePath_PC
% testPath_HPC -> testPath_PC

clear

Config_file = 'ModelsDesign_2d.ini';
PATH = config_parser(Config_file, 'PATH');
Mesh = config_parser(Config_file, 'Mesh');
testPath = PATH.testPath_PC;

savePath = PATH.savePath_PC;
if exist(savePath, 'dir') == 0;     mkdir(savePath);     end
minSize = Mesh.minSize;

fracLoc = [300 300 -200 200 -1700 -2100];
fracCon = 250;

tic
% save test dataset's fracCon data
filename_test = 'fracCon250_test_dataset.mat';
filename_pred = 'fracCon250_pred_dataset.mat';
count = 1500;
test_label_coe = load([testPath '20200522_0055_0194_test_label_coe.mat']);
pred_label_coe = load([testPath '20200522_0055_0194_pred_label_coe.mat']);
[C1, coe1] = fracCon_generator(test_label_coe.test_label_coe, fracLoc, fracCon, minSize, count, ...
                               savePath, filename_test);
[C2, coe2] = fracCon_generator(pred_label_coe.pred_label_coe, fracLoc, fracCon, minSize, count, ...
                               savePath, filename_pred);
toc

function [C, coe] = fracCon_generator(coe_input, fracLoc, fracCon, minSize, count, ...
                                      savePath, filename)

% dx = minSize(1); dy = minSize(2); dz = -minSize(3); % negative number
minSize(3) = - minSize(3);
n = 4; % 4*minSize expansion
% which dimension (x/y/z) fracturing sheet loss
objType = find([fracLoc(1)-fracLoc(2); fracLoc(3)-fracLoc(4); fracLoc(5)-fracLoc(6)] == 0);

switch objType
    case 1 % 1 -> YOZ plane
        index = [3 4; 5 6; 2 3]; % [fracCon_index_dim1;fracCon_index_dim2; minSize_dim]
    case 2 % 2 -> XOZ plane
        index = [1 2; 5 6; 1 3];
    case 3 % 3 -> XOY plane
        index = [1 2; 3 4; 1 2];
end

% e.g., YOZplane: [y1, z1] = meshgrid(fracLoc(3):dy:fracLoc(4)-dy, fracLoc(5):dz:fracLoc(6)-dz);
[dim1_1, dim2_1] = meshgrid(fracLoc(index(1,1)):minSize(index(3,1)):fracLoc(index(1,2))-minSize(index(3,1)), ...
                            fracLoc(index(2,1)):minSize(index(3,2)):fracLoc(index(2,2))-minSize(index(3,2)));
[dim1_2, dim2_2] = meshgrid(fracLoc(index(1,1))+minSize(index(3,1)):minSize(index(3,1)):fracLoc(index(1,2)), ...
                            fracLoc(index(2,1)):minSize(index(3,2)):fracLoc(index(2,2))-minSize(index(3,2)));
[dim1_3, dim2_3] = meshgrid(fracLoc(index(1,1))+minSize(index(3,1)):minSize(index(3,1)):fracLoc(index(1,2)), ...
                            fracLoc(index(2,1))+minSize(index(3,2)):minSize(index(3,2)):fracLoc(index(2,2)));
[dim1_4, dim2_4] = meshgrid(fracLoc(index(1,1)):minSize(index(3,1)):fracLoc(index(1,2))-minSize(index(3,1)), ...
                            fracLoc(index(2,1))+minSize(index(3,2)):minSize(index(3,2)):fracLoc(index(2,2)));
nodes = [dim1_1(:) dim1_2(:) dim1_3(:) dim1_4(:) dim2_1(:) dim2_2(:) dim2_3(:) dim2_4(:)];

meshlist = [];
fracturingLoc = repmat(fracLoc, length(nodes), 1);
for i = 1:length(nodes)
    mini_mesh = polyshape(nodes(i,1:4), nodes(i,5:8));
    meshlist = [meshlist; mini_mesh];
    fracturingLoc(i, index(1,1)) = nodes(i, 1);
    fracturingLoc(i, index(1,2)) = nodes(i, 2);
    fracturingLoc(i, index(2,1)) = nodes(i, 6);
    fracturingLoc(i, index(2,2)) = nodes(i, 7);
end

C = cell(length(count)+1,1); % one more C data
C{1, 1} = [fracturingLoc zeros(length(nodes), 1)]; % first for initial E-field data
coe = cell(length(count),1);
for i = 2:count + 1
    coe{i - 1, 1} = squeeze(coe_input(i - 1, :, :));
    C{i, 1} = [fracturingLoc fracCon * reshape(coe{i - 1, 1}, [length(nodes) 1])];
end

save([savePath filename], 'C', 'coe', 'fracLoc', 'fracCon');
end