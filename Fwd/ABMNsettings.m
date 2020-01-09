function [source, dataLoc, E_field] = ABMNsettings()

% source = [0 0 0 1; 
%           10000 0 0 -1];
% #### change +source location ####
source = [0 50 0 1; 
          10000 0 0 -1];

dataGridX = -500:20:500;
dataGridY = -500:20:500;
Ndata = length(dataGridX) * length(dataGridY);
[dataLocX, dataLocY] = meshgrid(dataGridX, dataGridY);
dataLoc.X = dataLocX;
dataLoc.Y = dataLocY;

% E field everywhere
electrodeSpacing = 50;
Mx = [dataLocX(:) - electrodeSpacing/2   dataLocY(:)   zeros(Ndata,1)]; % M electrodes for Ex
Nx = [dataLocX(:) + electrodeSpacing/2   dataLocY(:)   zeros(Ndata,1)]; % N electrodes for Ex
My = [dataLocX(:)   dataLocY(:) - electrodeSpacing/2  zeros(Ndata,1)]; % M electrodes for Ey
Ny = [dataLocX(:)   dataLocY(:) + electrodeSpacing/2  zeros(Ndata,1)]; % N electrodes for Ey

E_field.electrodeSpacing = electrodeSpacing;
E_field.Mx = Mx;
E_field.Nx = Nx;
E_field.My = My;
E_field.Ny = Ny;
end
