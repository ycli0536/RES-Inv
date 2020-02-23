clear

Config_file = 'ModelsDesign.ini';
PATH = config_parser(Config_file, 'PATH');
dataPath = PATH.savePath_PC;
diff_data_plotPath = [dataPath '/diff_data_plot/'];
if exist(diff_data_plotPath, 'dir') == 0;     mkdir(diff_data_plotPath);     end
data_plotPath = [dataPath '/data_plot/'];
if exist(data_plotPath, 'dir') == 0;     mkdir(data_plotPath);     end

load([dataPath 'diff_data_1.mat']);
load([dataPath 'data_1.mat']);

% figure; histogram(log10(abs(diff_data))); figure; histogram(log10(abs(data)))
loopplot_imagexyc(diff_data_plotPath, diff_data, [1e-9 1e-3]);
loopplot_imagexyc(data_plotPath, data, [1e-7 1e-3]);


function loopplot_imagexyc(plotPath, data, cutoff)
    dataGridX = -500:20:500;
    dataGridY = -500:20:500;
    [dataLocX, dataLocY] = meshgrid(dataGridX, dataGridY);
    % for parfor
    dataLoc_x = dataLocX(:);
    dataLoc_y = dataLocY(:);

    reso = 20;
    k = 26;
    for i = 1:size(data, 1)
        amp = reshape(sqrt(data(i, 1:length(dataLoc_x)).^2+data(i, length(dataLoc_y)+1:end).^2),51,51);
        
        fig_hsv = figure;
        set(fig_hsv, 'Visible', 'off')
        [~, ~, ~, ~] = imagexyc([dataLoc_x dataLoc_y data(i, 1:length(dataLoc_x))' data(i, length(dataLoc_y)+1:end)'], ...
                         reso,'',cutoff,'log');
        hold on;
        levellist = -10:0.5:-2;
        [ct, h] = contour(dataLocX, dataLocY, log10(amp), 'LevelStep',0.5, 'linecolor','k');
        clabel(ct,h, levellist, 'FontSize',14,'Color','k')
        clim = caxis;
        c = colorbar('Ticks',linspace(clim(1),clim(2),7), 'TickLabels',{'-180','-120','-60','0','60','120','180'});
        c.Label.String = 'degree';
        c.Label.Rotation = 0;
        c.Label.FontSize = 10;
        c.Label.Units = 'normalized';
        c.Label.Position = [0.5 1.06 0]; % c.Label.Position
        colormap(hsv)
        saveas(fig_hsv, [plotPath '2D_HSV' num2str(i) '.png'])
        
        fig2 = figure;
        set(fig2, 'Visible', 'off', 'Units', 'Normalized', 'OuterPosition', [0, 0, 0.4, 1])
        semilogy(dataLocX(k, :), amp(k, :), '.-'); grid on %y = 0 profile
        xlabel('X(m)')
        ylabel('Amplitude')
        ylim(cutoff)
        title(['Amplitude profile (y = 0) - ' num2str(i) '/' num2str(size(data, 1))])
        saveas(fig2, [plotPath '1D_amp' num2str(i) '.png'])
    end
    
    fig3 = figure; % together
    set(fig3, 'Visible', 'off', 'Units', 'Normalized', 'OuterPosition', [0, 0, 1, 1])
    for i=1:size(data, 1)
        amp = reshape(sqrt(data(i, 1:length(dataLoc_x)).^2+data(i, length(dataLoc_y)+1:end).^2),51,51);
        semilogy(dataLocX(k, :), amp(k, :), '.-'); %y = 0 profile
        hold on
    end
    legend(string(1:size(data, 1)), 'Location','EastOutside')
    xlabel('X(m)')
    ylabel('Amplitude')
    ylim(cutoff)
    title('Amplitude profile (y = 0)')
    grid on
    saveas(fig3, [plotPath '1D_amps_detailed.png'])
end
