clear

dataGridX = -500:20:500;
dataGridY = -500:20:500;
Ndata = length(dataGridX) * length(dataGridY);
[dataLocX, dataLocY] = meshgrid(dataGridX, dataGridY);

% for parfor
dataLoc_x = dataLocX(:);
dataLoc_y = dataLocY(:);

dataPath = 'D:/data/fwd_casing/';
savePath = 'D:/data/fwd_casing/images/';
if exist(savePath, 'dir') == 0;     mkdir(savePath);     end

dataGrouplist = dir([dataPath 'Casing' '*.mat']);
data = [];
for i = 1:length(dataGrouplist)
    temp = load([dataPath dataGrouplist(i).name]);
    data = [data; temp.data];
end

reso = 20;
cutoff = [1e-6 1e-1];
% figure; histogram(log10(abs(data)))
for i=1:size(data, 1)
    [~, ~, ~, ZI] = imagexyc([dataLoc_x dataLoc_y data(i, 1:length(dataLoc_x))' data(i, length(dataLoc_y)+1:end)'], ...
                         reso,'',cutoff,'log');
    % test ZI
    imwrite(ZI, [savePath, num2str(i,'%05d'), 'Efield_casingCon', '.png'])
end
