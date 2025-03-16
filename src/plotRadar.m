function plotRadar(varargin)
% Radar Data Processing Tracker plotting function

% Get radar measurement interval from model
deltat = 1;

% Get logged data from workspace
data = locGetData();

if isempty(data)
  return;  % if there is no data, no point in plotting
else
  XYCoords          = data.XYCoords;
  measurementNoise  = data.measurementNoise;
  polarCoords       = data.polarCoords;
  residual          = data.residual;
  xhat              = data.xhat;
end

% Plot data: set up figure
if nargin > 0
    figTag = varargin{1};
else
    figTag = 'no_arg';
end

figH = findobj('Type','figure','Tag', figTag);

if isempty(figH)
    figH = figure; 
    set(figH,'WindowState','maximized','Tag',figTag);
end

clf(figH)

% Polar plot of actual/estimated position
figure(figH); % keep focus on figH
axesH = subplot(2,3,1,polaraxes);
polarplot(axesH,polarCoords(:,2) - measurementNoise(:,2), ...
      polarCoords(:,1) - measurementNoise(:,1),'r')

hold on
rangehat = sqrt(xhat(:,1).^2+xhat(:,3).^2);
bearinghat = atan2(xhat(:,3),xhat(:,1));
polarplot(bearinghat,rangehat,'g');
legend(axesH,'Actual','Estimated','Location','south');

% Range Estimate Error
figure(figH); % keep focus on figH
axesH = subplot(2,3,4);
plot(axesH, residual(:,1)); grid; set(axesH,'xlim',[0 length(residual)]);
xlabel(axesH, 'Number of Measurements');
ylabel(axesH, 'Range Estimate Error - Feet')
title(axesH, 'Estimation Residual for Range')

% East-West position
XYMeas    = [polarCoords(:,1).*cos(polarCoords(:,2)), ...
             polarCoords(:,1).*sin(polarCoords(:,2))];
numTSteps = size(XYCoords,1);
t_full    = 0.1 * (0:numTSteps-1)';
t_hat     = (0:deltat:t_full(end))';    
       

figure(figH); % keep focus on figH
axesH = subplot(2,3,2:3);
plot(axesH, t_full,XYCoords(:,2),'r');
grid on;hold on
plot(axesH, t_full,XYMeas(:,2),'g');
plot(axesH, t_hat,xhat(:,3),'b');
title(axesH, 'E-W Position');
legend(axesH, 'Actual','Measured','Estimated','Location','Northwest');
hold off

% North-South position
figure(figH); % keep focus on figH
axesH = subplot(2,3,5:6);
plot(axesH, t_full,XYCoords(:,1),'r');
grid on;hold on
plot(axesH, t_full,XYMeas(:,1),'g');
plot(axesH, t_hat,xhat(:,1),'b');
xlabel(axesH, 'Time (sec)');
title(axesH, 'N-S Position');
legend(axesH, 'Actual','Measured','Estimated','Location','Northwest');
hold off
end

% Function "locGetData" logs data to workspace
function data = locGetData
% Get simulation result data from workspace 

% If necessary, convert logged signal data to local variables
if evalin('base','exist(''radarLogsOut'')')
    try
        logsOut = evalin('base','radarLogsOut');
        if isa(logsOut, 'Simulink.SimulationData.Dataset')
            data.measurementNoise = logsOut.get('measurementNoise').Values.Data;
            data.XYCoords         = logsOut.get('XYCoords').Values.Data;
            data.polarCoords      = logsOut.get('polarCoords').Values.Data;
            data.residual         = logsOut.get('residual').Values.Data;
            data.xhat             = logsOut.get('xhat').Values.Data;
        else
            assert(isa(logsOut, 'Simulink.ModelDataLogs'));
            data.measurementNoise = logsOut.measurementNoise.Data;
            data.XYCoords         = logsOut.XYCoords.Data;
            data.polarCoords      = logsOut.polarCoords.Data;
            data.residual         = logsOut.residual.Data;
            data.xhat             = logsOut.xhat.Data;
        end
    catch %#ok<CTCH>
        data = [];
    end
else
    if evalin('base','exist(''measurementNoise'')')
        data.measurementNoise  = evalin('base','measurementNoise');
        data.XYCoords          = evalin('base','XYCoords');
        data.polarCoords       = evalin('base','polarCoords');
        data.residual          = evalin('base','residual');
        data.xhat              = evalin('base','xhat');
    else
        data = [];  % something didn't run, skip retrieval
    end
end
end