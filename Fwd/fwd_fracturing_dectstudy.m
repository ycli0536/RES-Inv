
% fracLoc_origin = [300 300 -50 50 -1850 -1950];
% fracLoc_upExp = [300 300 -50 50 -1800 -1950];
% fracLoc_downExp = [300 300 -50 50 -1850 -2000];
% fracLoc_rightExp = [300 300 -50 100 -1850 -1950];
% fracLoc_leftExp = [300 300 -100 50 -1850 -1950];

%% initial
% PC terminal
% pre-setting values in this code: Config_file

clear
Config_file = 'ModelsDesign_2d_3wells_base500ohmm.ini';
diff_flag = true; % whether to calculate differentical data

PATH = config_parser(Config_file, 'PATH');
savePath = PATH.savePath_PC;
dataPath = PATH.dataPath_PC;
if exist(savePath, 'dir') == 0;     mkdir(savePath);     end
if exist(dataPath, 'dir') == 0;     mkdir(dataPath);     end

if diff_flag
    [nodeX, nodeY, nodeZ, ~, ~, ~, ~, source, dataLoc, ~, MaxCount] = setup(Config_file, 2, 'fracturing');
else
    [nodeX, nodeY, nodeZ, edgeCon, faceCon, cellCon, ~, source, dataLoc, E, MaxCount] = setup(Config_file, 1, 'fracturing');
end
dataLoc_x = dataLoc.X(:);
dataLoc_y = dataLoc.Y(:);

% (1) get connectivity
[nodes, edges, lengths, faces, cells] = ...
    formRectMeshConnectivity_t(nodeX, nodeY, nodeZ);
% (2) get matrices
Edge2Edge = formEdge2EdgeMatrix_t(edges,lengths);
Face2Edge = formFace2EdgeMatrix_t(edges,lengths,faces);
Cell2Edge = formCell2EdgeMatrix_t(edges,lengths,faces,cells);

G = formPotentialDifferenceMatrix(edges);
s = formSourceNearestNodes(nodes,source);

if diff_flag
    data = [];
    diff_data = [];
    for i=2:MaxCount
        [~, ~, ~, edgeCon, faceCon, cellCon, ~, ~, ~, E, ~] = setup(Config_file, i, 'fracturing');
        % (3) total conductance
        ce = Edge2Edge * edgeCon; % on edges
        cf = Face2Edge * faceCon; % on faces
        cc = Cell2Edge * cellCon; % on cells
        c = ce + cf + cc; % cc times 3 is important
        % (4) solve
        [potentials, ~, ~, ~] = solveForward(G,c,s,lengths);
        
        % get dc data in E-field
        [potentialDiffs_x, ~, ~, ~] = getResNetDataRectMesh(nodeX,nodeY,nodeZ,potentials,[E.Mx E.Nx]);
        [potentialDiffs_y, ~, ~, ~] = getResNetDataRectMesh(nodeX,nodeY,nodeZ,potentials,[E.My E.Ny]);
        
        Ex = potentialDiffs_x / E.electrodeSpacing;
        Ey = potentialDiffs_y / E.electrodeSpacing;
        
        if i == 2
            E_obs1 = [Ex; Ey];
            data = E_obs1';
        else
            E_obs2 = [Ex; Ey];
            F_obs = E_obs2 - E_obs1;
            data = [data; E_obs2'];
            diff_data = [diff_data; F_obs'];
        end
    end
else
    % (3) total conductance
    ce = Edge2Edge * edgeCon; % on edges
    cf = Face2Edge * faceCon; % on faces
    cc = Cell2Edge * cellCon; % on cells
    c = ce + cf + cc; % cc times 3 is important
    % (4) solve
    [potentials, ~, ~, ~] = solveForward(G,c,s,lengths);
    
    % get dc data in E-field
    [potentialDiffs_x, ~, ~, ~] = getResNetDataRectMesh(nodeX,nodeY,nodeZ,potentials,[E.Mx E.Nx]);
    [potentialDiffs_y, ~, ~, ~] = getResNetDataRectMesh(nodeX,nodeY,nodeZ,potentials,[E.My E.Ny]);
    Ex = potentialDiffs_x / E.electrodeSpacing;
    Ey = potentialDiffs_y / E.electrodeSpacing;
    
    E_obs = [Ex; Ey];
    data = E_obs';
end

%% save data

% for UBC code requirement
% save([dataPath PATH.data_prefix '_' 'ABMN_data' '.mat'], 'E', 'potentialDiffs_x', 'potentialDiffs_y');

% for RESnet code requirement
% if diff_flag
%     save([dataPath 'directionalfluid_3wells_1000Hwell.mat'], 'diff_data')
% else
%     save([dataPath 'homo50ohmm_data.mat'], 'data')
% end
% 
% copyfile(Config_file, savePath)

%% plot surface data

dataGridX = -500:20:500;
dataGridY = -500:20:500;
[dataLocX, dataLocY] = meshgrid(dataGridX, dataGridY);

reso = 20; cutoff = [1e-12 1e-5];
levelstep = 0.4;
levellist = -9.2:levelstep:0;

if diff_flag
    for i = 1:4
        plot_data = diff_data(i, :);
        figure;
        [~, ~, ~, ZI] = imagexyc([dataLoc_x dataLoc_y plot_data(1:length(dataLoc_x))' plot_data(length(dataLoc_y)+1:end)'], ...
                                 reso,'',cutoff,'log');
        hold on;
        [ct, h] = contour(dataLocX, dataLocY, reshape(log10(sqrt(plot_data(1:length(dataLoc_x)).^2 + plot_data(length(dataLoc_y)+1:end).^2)),51,51), 'LevelStep',levelstep, 'linecolor','k');
        clabel(ct,h, levellist, 'FontSize',15,'Color','k')
        
        %
        hold on; xlabel('X(m)'); ylabel('Y(m)');
        clim = caxis;
        c = colorbar('Ticks',linspace(clim(1),clim(2),7), 'TickLabels',{'-180','-120','-60','0','60','120','180'});
        c.Label.String = 'degree';
        c.Label.Rotation = 0;
        c.Label.Position = [0.5 -1.25 0];
        colormap(hsv)
    end
else
    plot_data = data;
    figure;
    [~, ~, ~, ZI] = imagexyc([dataLoc_x dataLoc_y plot_data(1:length(dataLoc_x))' plot_data(length(dataLoc_y)+1:end)'], ...
                             reso,'',cutoff,'log');
    hold on;
    [ct, h] = contour(dataLocX, dataLocY, reshape(log10(sqrt(plot_data(1:length(dataLoc_x)).^2 + plot_data(length(dataLoc_y)+1:end).^2)),51,51), 'LevelStep',levelstep, 'linecolor','k');
    clabel(ct,h, levellist, 'FontSize',15,'Color','k')
    
    %
    hold on; xlabel('X(m)'); ylabel('Y(m)');
    clim = caxis;
    c = colorbar('Ticks',linspace(clim(1),clim(2),7), 'TickLabels',{'-180','-120','-60','0','60','120','180'});
    c.Label.String = 'degree';
    c.Label.Rotation = 0;
    c.Label.Position = [0.5 -1.25 0];
    colormap(hsv)
end

%% differential E (log) vs differential rho_a
% diff_flag = true;

% differential Ey
I = source(1, 4);
diff_Ey = diff_data(1, length(dataLoc_y)+1:end);

amp_y = reshape(diff_Ey, 51, 51);
amp_logy = log10(abs(amp_y));
% amp_logy(26, 26) = nan;

% --apparent resistivity formula--
Ey1 = data(1, length(dataLoc_y)+1:end);
Ey2 = data(2, length(dataLoc_y)+1:end);
amp_y1 = reshape(Ey1, 51, 51);
amp_y2 = reshape(Ey2, 51, 51);

index = reshape((1:2601)', 51, 51);
profile_loc = index(:, 26);
M = E.My(profile_loc, :);
N = E.Ny(profile_loc, :);

AM = sqrt(sum((M-[0 0 0]).^2, 2));
AN = sqrt(sum((N-[0 0 0]).^2, 2));
MN = sqrt(sum((M-N).^2, 2));
rho_a1 = (2 * pi .* AM .* AN ./ MN) .* (abs(amp_y1(:, 26)) .* MN ./ I);
rho_a2 = (2 * pi .* AM .* AN ./ MN) .* (abs(amp_y2(:, 26)) .* MN ./ I);

figure; 
yyaxis left
plot(amp_logy(:, 26), '.-')
title('Differential Electric field data vs Apparent resistivity')
xlabel('survey line points')
ylabel('\Delta Ey (log)')

yyaxis right
plot(abs(rho_a2 - rho_a1), '.-')
ylabel('\Delta \rho_a')
xlim([0 51])