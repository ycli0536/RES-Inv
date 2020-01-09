function [h, XI, YI, ZI] = imagexyc(raw,spacing,mark,amplims,amplogflag)
% visualize scattered complex numbers (or a 2D vector) on a x-y plane
% amplitude and angle are coded as saturation and hue in HSV color model
% rendered by false color composite 
% FUNCTION [h, XI, YI, ZI] = imagexyc(raw,spacing,mark,amplims,amplogflag)
% raw : 4-column matrix [x_loc y_loc real imag] or [x_loc y_loc x_comp y_comp] 
% spacing: spacing of grid
% mark: mark for location of scattered points
% amplims: [min max] for the range of amplitude that is mapped to [0 1]
% amplogflag: 'log' indicates taking log10 of amplitude

% understand input
x = raw(:,1);
y = raw(:,2);
re = raw(:,3);
im = raw(:,4);
amp = sqrt(re.^2+im.^2);
ang = atan2(re,im) / pi; % range from -1 to 1

% understand input
if isempty(spacing)
    spacing = max([1 sqrt(  (x(1)-x(2))^2 + (y(1)-y(2))^2 )]);
end

% understand input
if isempty(mark)
    mark = '';
end

% understand input
if ~isempty(amplims)
    ampmin = amplims(1);
    ampmax = amplims(2);
    amp(amp<ampmin) = ampmin;
    amp(amp>ampmax) = ampmax;
else
    ampmin = min(amp);
    ampmax = max(amp);
end

% understand input
if strcmpi(amplogflag,'log')
    amp = log10(amp);
    ampmin = log10(ampmin);
    ampmax = log10(ampmax);
end

% map to [0, 1]
amp = interp1([ampmin ampmax],[0 1],amp);
ang = interp1([-1 1],[0 1],ang);

% grid data
left = min(x);
right = max(x);
top = max(y);
bottom = min(y);
[XI,YI] = meshgrid(left:spacing:right,bottom:spacing:top);
F = scatteredInterpolant(x,y,amp,'linear','none');
ZIamp = F(XI,YI);
F = scatteredInterpolant(x,y,ang,'linear','none');
ZIang = F(XI,YI);

hsv = [ZIang(:) ZIamp(:) ones(length(amp(:)),1)]; % [hue saturation brightness]
% hvs = [ZIang(:) ones(length(ZIamp(:)),1) ZIamp(:)]; % [hue saturation brightness]
hsv(hsv>1) = 1;
hsv(hsv<0) = 0;
rgb = hsv2rgb(hsv);
R = reshape(rgb(:,1),size(XI));
G = reshape(rgb(:,2),size(XI));
B = reshape(rgb(:,3),size(XI));
ZI = cat(3,R,G,B);


% plot
h = imagesc(left:spacing:right,bottom:spacing:top,ZI);
% h = scatter(XI(:),YI(:),YI(:)*0+3,[reshape(ZI(:,:,1),[],1) reshape(ZI(:,:,2),[],1) reshape(ZI(:,:,3),[],1)]);
set(h,'alphadata',~isnan(R));
set(gca,'ydir','normal');
axis equal;
axis tight;


end