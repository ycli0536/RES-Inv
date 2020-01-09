clear

[source, dataLoc, E] = ABMNsettings();

dataLocX = dataLoc.X;
dataLocY = dataLoc.Y;
% for parfor
dataLoc_x = dataLocX(:);
dataLoc_y = dataLocY(:);

%% load data and label
% homePath = 'D:/Yinchu Li/EMG_largeFiles/forloop/';
homePath = 'D:/Yinchu Li/EMG_largeFiles/forloop_noProductionWell/';
% savePath = [homePath 'new_dataset20191021/'];
% homePath = '/home/liyinchu/Data/ML20191017/';
savePath = [homePath 'dataset20191219/'];
if exist(savePath, 'dir') == 0;     mkdir(savePath);     end




dataGrouplist = dir([savePath 'train' '*.mat']);
ShapeGrouplist = dir([savePath 'Sheet' '*.mat']);
data = [];
label = [];
fracCons = [];

for i = 1:length(dataGrouplist)
    temp1 = load([savePath dataGrouplist(i).name]);
    temp2 = load([savePath ShapeGrouplist(i).name]);
    data = [data; temp1.data];
    label = [label; temp1.label];
    fracCons = [fracCons;temp2.fracCons];
%     fracCon = [fracCon; str2num(dataGrouplist(i).name(7:9)) * ones(length(temp1.label), 1)];
end

%%
name_51X51_ObsData = '51X51_ObsData_';
path_51X51_ObsData = [homePath name_51X51_ObsData '/'];
if exist(path_51X51_ObsData, 'dir') == 0;     mkdir(path_51X51_ObsData);     end

%---Showing fwd result
reso = 20;
cutoff = [1e-8 1e-6];

for i = 1:length(label)

[~, ~, ~, ZI] = imagexyc([dataLoc_x dataLoc_y data(i, 1:length(dataLoc_x))' data(i, length(dataLoc_y)+1:end)'], ...
                         reso,'',cutoff,'log');
% set(gca,'position',[0 0 1 1])
% axis normal
% axis off 

imwrite(flipud(ZI), [path_51X51_ObsData, num2str(i,'%05d'), '_fracCon', num2str(fracCons(i)), ...
    '_', char(label(i)), '_' name_51X51_ObsData, '.jpg'])
end