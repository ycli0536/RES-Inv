clear

Config_file = 'ModelsDesign.ini';
PATH = config_parser(Config_file, 'PATH');

dataPath = PATH.homePath_PC; % E-field data path
savePath = PATH.savePath_PC; % where to save the processed data
% plotPath = PATH.targetPath_PC; % plot path
% if exist(plotPath, 'dir') == 0;     mkdir(plotPath);     end
dataname = PATH.data_file;
filename = PATH.saved_file;

% dataGrouplist = dir([dataPath 'Casing#01_' '*.mat']);
dataGrouplist = dir([dataPath dataname]);
data = [];
for i = 1:length(dataGrouplist)
    temp = load([dataPath dataGrouplist(i).name]);
    data = [data; temp.data];
end

reso = 20;
cutoff = [1e-10 1e-2];
% figure; histogram(log10(abs(data)))
% loopplot_raw_imagexyc(savePath, data, cutoff)
% loopplot_profile(savePath, data, cutoff)
% data_profile = data1D(plotPath, data, 26, log10(cutoff));
% for i = 1:40
%     plot(data_profile(i,:))
%     grid on
%     hold on
% end
data2D(savePath, filename, data, log10(cutoff));
data2D_orig(savePath, filename, data);

function loopplot_raw_imagexyc(plotPath, data, cutoff)
    dataGridX = -500:20:500;
    dataGridY = -500:20:500;
    [dataLocX, dataLocY] = meshgrid(dataGridX, dataGridY);
    
    dataLoc_x = dataLocX(:);
    dataLoc_y = dataLocY(:);
    
    reso = 20;
    for i = 1:size(data, 1)
        [~, ~, ~, ZI] = imagexyc([dataLoc_x dataLoc_y data(i, 1:length(dataLoc_x))' data(i, length(dataLoc_y)+1:end)'], ...
                         reso,'',cutoff,'log');
        % test ZI
        imwrite(ZI, [plotPath, num2str(i,'%05d'), 'Ed_field_casingCon', '.png'])
    end
end
function loopplot_profile(plotPath, data, cutoff)
    dataGridX = -500:20:500;
    dataGridY = -500:20:500;
    [dataLocX, dataLocY] = meshgrid(dataGridX, dataGridY);
    
    dataLoc_x = dataLocX(:);
    dataLoc_y = dataLocY(:);
    
    k = 26;
    for i = 1:size(data, 1)
        amp = reshape(sqrt(data(i, 1:length(dataLoc_x)).^2+data(i, length(dataLoc_y)+1:end).^2),51,51);
        figure_Aprofile(plotPath, dataLocX, data, amp, i, k, cutoff)
    end
end
function data_output = data1D(savePath, data, k, cutoff)
    dataGridX = -500:20:500;
    dataGridY = -500:20:500;
    [dataLocX, dataLocY] = meshgrid(dataGridX, dataGridY);
    
    dataLoc_x = dataLocX(:);
    dataLoc_y = dataLocY(:);
    data_output = [];
    for i = 1:size(data, 1)
        amp = reshape(sqrt(data(i, 1:length(dataLoc_x)).^2+data(i, length(dataLoc_y)+1:end).^2),51,51);
        amp_log = log10(amp);
        data_output = [data_output; amp_log(k, :)];
    end
    data_output(data_output <= cutoff(1)) = cutoff(1);
    save([savePath 'Casing_profile#' num2str(k, '%02d') '_casingCon' '.mat'], 'data_output');
end
function figure_Aprofile(plotPath, dataLoc, data, amp, i, k, cutoff)
    fig2 = figure;
    set(fig2, 'Visible', 'off', 'Units', 'Normalized', 'OuterPosition', [0, 0, 0.4, 1])
    semilogy(dataLoc(k, :), amp(k, :), '.-'); grid on %y = 0 profile
    xlabel('X(m)')
    ylabel('Amplitude')
    ylim(cutoff)
    title(['Amplitude profile (y = 0) - ' num2str(i) '/' num2str(size(data, 1))])
    saveas(fig2, [plotPath '1D_amp' num2str(i) '.png'])
end

function data2D_orig(savePath, filename, data)
    dataGridX = -500:20:500;
    dataGridY = -500:20:500;
    [dataLocX, dataLocY] = meshgrid(dataGridX, dataGridY);
    
    dataLoc_x = dataLocX(:);
    dataLoc_y = dataLocY(:);
    data_log_amp_orig = zeros(size(data, 1), 51, 51);
    data_log_ang_orig = zeros(size(data, 1), 51, 51);
    for i = 1:size(data, 1)
        Ex = data(i, 1:length(dataLoc_x));
        Ey = data(i, length(dataLoc_y)+1:end);
        amp = reshape(sqrt(Ex.^2+Ey.^2),51,51);
        amp_log = log10(amp);
        ang = atan2(Ex, -Ey) / pi; % range from -1 to 1
        data_log_amp_orig(i, :, :) = amp_log;
        data_log_ang_orig(i, :, :) = reshape(ang, 51, 51);
    end
    save([savePath 'orig_' filename], 'data_log_amp_orig', 'data_log_ang_orig');
end

function data2D(savePath, filename, data, cutoff)
    dataGridX = -500:20:500;
    dataGridY = -500:20:500;
    [dataLocX, dataLocY] = meshgrid(dataGridX, dataGridY);
    
    dataLoc_x = dataLocX(:);
    dataLoc_y = dataLocY(:);
    data_log_amp = zeros(size(data, 1), 51, 51);
    data_log_ang = zeros(size(data, 1), 51, 51);
    for i = 1:size(data, 1)
        Ex = data(i, 1:length(dataLoc_x));
        Ey = data(i, length(dataLoc_y)+1:end);
        amp = reshape(sqrt(Ex.^2+Ey.^2),51,51);
        amp_log = log10(amp);
        amp_log(amp_log <= cutoff(1)) = cutoff(1);
        ampmin = min(min(amp_log));
        ampmax = max(max(amp_log));
        amp_log = interp1([ampmin ampmax],[0 1],amp_log);
        ang = atan2(Ex, -Ey) / pi; % range from -1 to 1
        ang = interp1([-1 1],[0 1],ang);
        data_log_amp(i, :, :) = amp_log;
        data_log_ang(i, :, :) = reshape(ang, 51, 51);
    end
    save([savePath filename], 'data_log_amp', 'data_log_ang');
end

