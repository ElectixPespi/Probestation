%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to operate Keithley 2410C and Agilent E4980A to measure CV
% data from the connected probe startion.
%
% THIS ONLY WORKS WITH THE Keithley 2410C and Agilent E4980!!
% If changes are made to instrument setting, revision of the code
% is recommended

% NB. At the moment O.C. correction must be performed before each
% measurement.
%
% Based on work of Tiina Naaranoja, Esa Tuovinen, Ville Pyykkonen
% and Keithley recources.
%
% Version 2 (current version)
% Agilenth does C measurement
% Keithley 2410-C sources voltage
%

% By CMS pixel group HIP, November 2016
%
% To do:
% Short term:
%
% Long term:
% - graphical interface and standalone version
% - refactor the code in to smaller blocks (functions and files)
% to make it more easily maintainable and understandable
% - push the code to github to create version management
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all
close all

% Clear possible previous waitbars
a=findall(0,'Tag','TMWWaitbar');
delete(a);


% Ask about details of measurement with inputsdlg
Title = 'C-V measurement input';

Prompt ={};
Formats = {};
DefAns = struct([]);
Options.Resize = 'on';
Boxsize = 200;

Prompt(1,:) = {'Enter the working directory:','WorkDir',[]};
Formats(1,1).type = 'edit';
Formats(1,1).format = 'text';
Formats(1,1).size = 1.5*Boxsize;
DefAns(1).WorkDir = 'C:\Users\HIPadmin\Desktop\Probestation\Development';

c=clock;
Prompt(2,:) = {'Enter name for output file (automatically .txt):','FileName',[]};
Formats(2,1).type = 'edit';
Formats(2,1).format = 'text';
Formats(2,1).size = Boxsize;
DefAns(1).FileName = ['HIP_BLT1_MOS_noimpl_T11_43Gy_1kHz@_CV_' num2str(c(3)) '_' num2str(c(2)) '_' ...
    num2str(c(1)) '_' num2str(c(4)) '_' num2str(c(5),'%02d')];

Prompt(3,:) = {'Enter initial voltage (in Volts):','InitialVoltage',[]};
Formats(3,1).type = 'edit';
Formats(3,1).format = 'integer';
Formats(3,1).size = Boxsize;
DefAns(1).InitialVoltage = 10;

Prompt(4,:) = {'Enter final voltage (in Volts):','FinalVoltage',[]};
Formats(4,1).type = 'edit';
Formats(4,1).format = 'integer';
Formats(4,1).size = Boxsize;
DefAns(1).FinalVoltage = -10;

Prompt(5,:) = {'Enter the number of measurement steps:','MeasSteps',[]};
Formats(5,1).type = 'edit';
Formats(5,1).format = 'integer';
Formats(5,1).size = Boxsize;
DefAns(1).MeasSteps = 21;

Prompt(6,:)         = {'Use file specified voltages?','FileVoltages',[]};
Formats(6,1).type   = 'list';
Formats(6,1).format = 'text';
Formats(6,1).style  = 'radiobutton';
Formats(6,1).items  = {'YES' 'NO'};
DefAns(1).FileVoltages = 'NO';

Prompt(7,:) = {'Enter a path to a file specifying voltage values:','VoltPath',[]};
Formats(7,1).type = 'edit';
Formats(7,1).format = 'text';
Formats(7,1).size = Boxsize;
DefAns(1).VoltPath = 'voltages.txt';


Prompt(8,:) = {'Enter the number of measurements at a voltage step:','NMeas',[]};
Formats(8,1).type = 'edit';
Formats(8,1).format = 'integer';
Formats(8,1).size = Boxsize;
DefAns(1).NMeas = 3;

Prompt(9,:) = {'Enter delay between measurements (s):','MeasDelay',[]};
Formats(9,1).type = 'edit';
Formats(9,1).format = 'integer';
Formats(9,1).size = Boxsize;
DefAns(1).MeasDelay = 3;

Prompt(10,:)  = {'Measurement Frequency (20Hz - 1MHz)', 'Frequency',[]};
Formats(10,1).type   = 'edit';
Formats(10,1).format = 'text';
Formats(10,1).size   = Boxsize; % automatically assign the height
DefAns(1).Frequency = '1e3';

Prompt(11,:)         = {'Agilent Beeper on/ off ?','BeepOrNotToBeep',[]};
Formats(11,1).type   = 'list';
Formats(11,1).format = 'text';
Formats(11,1).style  = 'radiobutton';
Formats(11,1).items  = {'ON' 'OFF'};
DefAns(1).BeepOrNotToBeep    = 'OFF';

[answer, cancelled] = inputsdlg(Prompt,Title,Formats,DefAns,Options);

if cancelled == 1
    sprintf('Measurement Aborted');
    %clear all; close all;
    return;
end

filename = answer.FileName;
workdir=answer.WorkDir;
output_name = ['Data\' filename '.txt'];
n_repeats = answer.NMeas;
n_points = answer.MeasSteps;
Vinit = answer.InitialVoltage;
Vfinal = answer.FinalVoltage;
VoltagePath = answer.VoltPath;
FileSpecified = answer.FileVoltages;
meas_delay = answer.MeasDelay;
beep=answer.BeepOrNotToBeep;
freq = answer.Frequency;

% setting working directory and inserting essential folders if not exist
try
    olddir=cd(workdir);
catch
    fprintf('Given working directory not found. Check the path. Exiting\n');
    return;
end
A=exist([workdir '\Figures']);
if(A ~= 7)
    fprintf('Creating the folder Figures\n');
    mkdir(workdir,'Figures');
end
A=exist([workdir '\Data']);
if(A ~=7)
    fprintf('Creating the folder Data\n');
    mkdir(workdir,'Data');
end


% Measurement per se
% waitbar for measurement process and cancelling the measurement
progress = waitbar(0,'Connecting to instruments','name','VI measurement',...
    'CreateCancelBtn','setappdata(gcbf,''cancelling'',1)');


% Addresses to Keithley instruments
% First for voltage generation etc.
% Second for capacitance
InstrAddress = [23 12];
% check whether already open
InstrV= instrfind('Type', 'gpib', 'BoardIndex', 0, 'PrimaryAddress', InstrAddress(1), 'Tag', '');
InstrC= instrfind('Type', 'gpib', 'BoardIndex', 0, 'PrimaryAddress', InstrAddress(2), 'Tag', '');

if isempty(InstrV)
    InstrV = gpib('NI', 0, InstrAddress(1));
else
    fclose(InstrV);
    InstrV=InstrV(1);
end
if isempty(InstrC)
    InstrC = gpib('NI', 0, InstrAddress(2));
else
    fclose(InstrC);
    InstrC=InstrC(1);
end

% Connect to the instruments
fprintf('Connecting to voltage source\n');
try
    fopen(InstrV);
catch ME
    fprintf('Could not connect to the voltage source\n');
    delete(InstrV);
    delete(InstrC);
    %clear all; close all;
    return;
end
fprintf('Connection acquired\n');
fprintf('Connecting to capacitance meter\n');
try
    fopen(InstrC);
catch ME
    fprintf('Could not connect to the capacitance meter 1\n');
    fclose(InstrV);
    delete(InstrV);
    delete(InstrC);
    %clear all; close all;
    return;
end
fprintf('Connection acquired\n');


% Configure property values (probably not necessary)
% End of string for writing and reading
% is by default 'LF' meaning that
% each command is completed by line feed character
%InstrV.EOSMode = 'read&write';
%InstrI.EOSMode = 'read&write';



%****** Plottings ******
% open figure for future plotting purposes
scrsz = get(groot,'ScreenSize');
PositionVector=[1 scrsz(4)/10 2*scrsz(3)/5 4*scrsz(4)/5];
CVcurve=figure('position',PositionVector);

%figure(IVcurve,'name',filename);


ylabel('Measured capacitance [A]');
xlabel('Source-Voltage [V]');
hold on;

% ****** variables to store stuff ******
voltage = zeros(n_points);
A = exist('BGcapacitance');
B = exist('BDdissipation');
c = exist('n_repeatsold');
d = exist('n_pointssold');
if( c == 0)
    n_repeatsold = n_repeats;
    n_pointsold = n_points;
end
if( A == 0 || n_repeatsold ~= n_repeats || n_pointsold ~= n_points)
    BGcapacitance = zeros(n_repeats,n_points);
    BGdissipation = zeros(n_repeats,n_points);
end
n_repeatsold = n_repeats;
n_pointssold = n_points;
capacitance = zeros(n_repeats,n_points);
dissipation = zeros(n_repeats,n_points);


% ****** Instrument setup ******

% Setting the capacitance measurement
% Agilent setup
fprintf(InstrC, '*RST;*CLS');     % reset
fprintf(InstrC, 'FORM ASC');
fprintf(InstrC, 'TRIG:SOUR BUS');
fprintf(InstrC, 'APER LONG,5');
fprintf(InstrC, 'COMP ON');
fprintf(InstrC, 'INIT:CONT OFF');
fprintf(InstrC, [':SYST:BEEP:STAT ', beep]);
fprintf(InstrC, [':FREQ ', freq]);

% C ranges (not needed for auto-range)


% setting initial V range
% if abs(Vfinal) < abs(Vinit)
%    helper = Vfinal;
%    Vfinal = Vinit;
%    Vinit = helper;
% end







cancelation = 0;
% setting the V sourcing

% voltage points
if(FileSpecified == 'YES')
    voltages = importdata(VoltagePath);
else
    voltages = linspace(Vinit,Vfinal,n_points);
end



% Initialization for voltage source
% Set the box to voltage setting
fprintf(InstrV,'*RST');
fprintf(InstrV,':ROUT:TERM REAR');
fprintf(InstrV, strcat(':SOUR:FUNC VOLT'));
fprintf(InstrV, strcat(':SOUR:VOLT:MODE FIX'));
fprintf(InstrV, strcat(':SENS:CURR:PROT 30E-5'));
fprintf(InstrV, strcat(':SENS:CURR:PROT 30E-5'));


if abs(Vfinal) > 20 && abs(Vfinal) <= 500
    fprintf(InstrV,':SOUR:VOLT:RANG 1000');
end
if abs(Vfinal) > 500
    fprintf('Too high highest voltage (over 500 V), aborting');
    fclose(InstrV);
    delete(InstrV);
    fclose(InstrC);
    delete(InstrC);
    return;
end

% setting initial V
fprintf(InstrV, strcat(':SOUR:VOLT:LEV 0'));
% setting the current limit
%fprintf(InstrV,strcat('SOUR:VOLT:ILIM ',I_limit));

% boolean for current compliance
stopping = 0;
% turn the voltage on
fprintf(InstrV,':OUTP ON');


voltage_idx = 0;

TempVar = FirstGUI;
ButtonValue = TempVar.ButtonValue.String;
close(TempVar.f1);
clearvars TempVar;
if(strcmp(ButtonValue, 'Background'))
    % ************ OPEN NEEDLE CALIBRATION *************
    for i=1:n_points
        voltage_idx = voltage_idx+1;
        if getappdata(progress,'cancelling')
            if(cancelation == 0)
                fprintf('Measurement canceled. %d measurements done\n',i-1);
                waitbar(1,progress,'Cancelled. Ramping down');
                cancelation = 1;
                pause(1);
                break;
            end
            if(cancelation == 1)
                break;
            end
        end
        %setting voltage
        waitbar((i-1)/n_points,progress,'Setting voltage');
        voltagestr = [':SOUR:VOLT:LEV ' num2str(voltages(i))]
        fprintf(InstrV,voltagestr);
        %fprintf(InstrV,'SOUR:VOLT:STAT ON');
        % delay to let the diode settle
        waitbar((i-1)/n_points,progress,'Delay to let the diode settle');
        pause(meas_delay);
        %doing measurements
        for j=1:n_repeats
            if getappdata(progress,'cancelling')
                fprintf('Measurement canceled. %d measurements done\n',i-1);
                waitbar(1,progress,'Cancelled. Pause for 1 sec and proceeding to ramp down');
                pause(1);
                cancelation = 1;
                break;
            end
            waitbar(((i-1)*n_repeats+j)/(n_points*n_repeats),progress,'Measuring capacitance');
            
            % capacitance measurement happens here
            fprintf(InstrC, 'INIT:IMM');
            fprintf(InstrC, 'TRIG:IMM');
            fprintf(InstrC, 'FETCh?'); % give command to send current readings shown on screen
            A1 = scanstr(InstrC); % capture read out ascii characters from buffer and convert to numeric
            % check how many columns A1 has so see if this
            % works
            BGcapacitance(j,i) = A1{1}; % scan for numbers related to Ampere and make absolute (use abs)
            BGdissipation(j,i) = A1{2}; % scan for numbers related to Ampere and make absolute (use abs)
            %t(jj)=A1{2};
            
        end
        if(stopping == 1)
            break;
        end
        
        %check whether figure is closed, start all over again
        %
        if(~isvalid(CVcurve))
            CVcurve=figure('position',PositionVector);
        end
        figure(CVcurve);
        subplot(3,1,1);
        if(Vfinal<0)
            set(gca,'Xdir','reverse');
        end
        plot(voltages(1:i),mean(BGcapacitance(:,1:i),1),'bo',...
            'LineWidth',1, ...
            'MarkerEdgeColor','k',...
            'MarkerFaceColor','b',...
            'MarkerSize',5);
        hold on;
        titlestr = {filename ,[ 'Voltage steeps from ' num2str(Vinit) ' V to ' ...
            num2str(Vfinal) ' V in ' num2str(n_points) ' steps' ]};
        % No LaTeX formatting as we want underscores to be written correctly
        title(titlestr,'Interpreter','none');
        ylabel('Capacitance (F)');
        xlabel('Source Voltage (V)');
        
        %same but x axis with logarithmic scale
        subplot(3,1,2);
        if(Vfinal<0)
            set(gca,'Xdir','reverse');
        end
        semilogy(voltages(1:i),mean(BGcapacitance(:,1:i),1),'bd',...
            'LineWidth',1, ...
            'MarkerEdgeColor','k',...
            'MarkerFaceColor','b',...
            'MarkerSize',5);
        hold on;
        
        ylabel('Capacitance (F)');
        xlabel('Source Voltage (V)');
        
        subplot(3,1,3)
        if(Vfinal<0)
            set(gca,'Xdir','reverse');
        end
        semilogy(voltages(1:i),1./(mean(BGcapacitance(:,1:i),1)).^2,'bd',...
            'LineWidth',1, ...
            'MarkerEdgeColor','k',...
            'MarkerFaceColor','b',...
            'MarkerSize',5);
        hold on;
        
        ylabel('1/Capacitance^2 (1/F^2)');
        xlabel('Source Voltage (V)');
    end
    
    for i=1:4
        pause(1);
        waitbar(1,progress,'Ramping down');
        voltagestr = ['SOUR:VOLT:LEV ' num2str(voltages(voltage_idx)*(4-i)/4)];
        fprintf(InstrV, voltagestr);
    end
    
    fprintf(InstrV, strcat('SOUR:VOLT:LEV 0'));
    % turn the voltage off
    fprintf(InstrV,':OUTP OFF');
    
end

fprintf(InstrV,':OUTP OFF');
if(strcmp(ButtonValue, 'Background') && ~cancelation )
    TempVar = SecondGUI;
    ButtonValue = TempVar.ButtonValue.String;
    close(TempVar.f3);
end
if(strcmp(ButtonValue,'Cancel'))
    waitbar(1,progress,'Canceled');
end
if(strcmp(ButtonValue,'SkipBGData')|| strcmp(ButtonValue,'Measure'))
    % ************ MEASUREMENT PER SE **************
    if(cancelation == 1)
        BGcapacitance = zeros(n_repeats,n_points);
        BGdissipation = zeros(n_repeats,n_points);
        cancelation == 0
        %progress = waitbar(0,'Beginning CV measurement','name','CV measurement',...
        %'%CreateCancelBtn','setappdata(gcbf,''cancelling'',1)');
    end
    
    BGvalid = 1;
    fprintf(InstrV,':OUTP ON');
    voltage_idx = 0;
    for i=1:n_points
        
        voltage_idx = voltage_idx+1;
        if getappdata(progress,'cancelling')
            if(cancelation == 0)
                fprintf('Measurement canceled. %d measurements done\n',i-1);
                waitbar(1,progress,'Cancelled. Ramping down');
                pause(1);
                break;
            end
            if(cancelation == 1)
                break;
            end
        end
        %setting voltage
        waitbar((i-1)/n_points,progress,'Setting voltage');
        voltagestr = [':SOUR:VOLT:LEV ' num2str(voltages(i))]
        fprintf(InstrV,voltagestr);
        %fprintf(InstrV,'SOUR:VOLT:STAT ON');
        % delay to let the diode settle
        waitbar((i-1)/n_points,progress,'Delay to let the diode settle');
        pause(meas_delay);
        %doing measurements
        for j=1:n_repeats
            if getappdata(progress,'cancelling')
                fprintf('Measurement canceled. %d measurements done\n',i-1);
                waitbar(1,progress,'Cancelled. Pause for 1 sec and proceeding to ramp down');
                pause(1);
                cancelation = 1;
                pause(meas_delay);
                break;
            end
            waitbar(((i-1)*n_repeats+j)/(n_points*n_repeats),progress,'Measuring capacitance');
            
            % capacitance measurement happens here
            fprintf(InstrC, 'INIT:IMM');
            fprintf(InstrC, 'TRIG:IMM');
            fprintf(InstrC, 'FETCh?'); % give command to send current readings shown on screen
            if( i == 1)
                fprintf(InstrC, 'INIT:IMM');
                fprintf(InstrC, 'TRIG:IMM');
                fprintf(InstrC, 'FETCh?'); % give command to send current readings shown on screen
            end
            A1 = scanstr(InstrC); % capture read out ascii characters from buffer and convert to numeric
            % check how many columns A1 has so see if this
            % works
            capacitance(j,i) = A1{1}; % scan for numbers related to Ampere and make absolute (use abs)
            dissipation(j,i) = A1{2}; % scan for numbers related to Ampere and make absolute (use abs)
            %t(jj)=A1{2};
            
        end
        if(stopping == 1)
            break;
        end
        %check whether figure is closed, start all over again
        %
        if(~isvalid(CVcurve))
            CVcurve=figure('position',PositionVector);
        end
        
        figure(CVcurve);
        subplot(3,1,1);
        if(Vfinal<0)
            set(gca,'Xdir','reverse');
        end
        plot(voltages(1:i),mean(capacitance(:,1:i),1),'bo',...
            'LineWidth',1, ...
            'MarkerEdgeColor','k',...
            'MarkerFaceColor','g',...
            'MarkerSize',5);
        if( BGvalid == 1)
            try
                plot(voltages(1:i),mean(capacitance(:,1:i)-BGcapacitance(:,1:i),1),'ko',...
                    'LineWidth',1, ...
                    'MarkerEdgeColor','k',...
                    'MarkerFaceColor','r',...
                    'MarkerSize',5);
            catch ME
                BGvalid = 0;
                fprintf('Invalid open needle dimension. Redo to have comparison');
            end
        end
        
        hold on;
        titlestr = {filename ,[ 'Voltage steeps from ' num2str(Vinit) ' V to ' ...
            num2str(Vfinal) ' V in ' num2str(n_points) ' steps' ],...
            'Blue = open needle','Green = measurement', ...
            'Red = measurement-open needle'};
        % No LaTeX formatting as we want underscores to be written correctly
        title(titlestr,'Interpreter','none');
        ylabel('Capacitance (F)');
        xlabel('Source Voltage (V)');
        
        %same but x axis with logarithmic scale
        subplot(3,1,2);
        if(Vfinal<0)
            set(gca,'Xdir','reverse');
        end
        semilogy(voltages(1:i),mean(capacitance(:,1:i),1),'bd',...
            'LineWidth',1, ...
            'MarkerEdgeColor','k',...
            'MarkerFaceColor','g',...
            'MarkerSize',5);
        if( BGvalid == 1)
            try
                semilogy(voltages(1:i),mean(capacitance(:,1:i)-BGcapacitance(:,1:i),1),'bd',...
                    'LineWidth',1, ...
                    'MarkerEdgeColor','k',...
                    'MarkerFaceColor','r',...
                    'MarkerSize',5);
            catch ME
                fprintf('Invalid open needle dimension. Redo to have comparison');
            end
        end
        hold on;
        ylabel('Capacitance (F)');
        xlabel('Source Voltage (V)');
        
        subplot(3,1,3)
        if(Vfinal<0)
            set(gca,'Xdir','reverse');
        end
        semilogy(voltages(1:i),1./(mean(capacitance(:,1:i),1)).^2,'bo',...
            'LineWidth',1, ...
            'MarkerEdgeColor','k',...
            'MarkerFaceColor','g',...
            'MarkerSize',5);
        if( BGvalid == 1)
            try
                semilogy(voltages(1:i),1./(mean(capacitance(:,1:i)-BGcapacitance(:,1:i),1)).^2,'ko',...
                    'LineWidth',1, ...
                    'MarkerEdgeColor','k',...
                    'MarkerFaceColor','r',...
                    'MarkerSize',5);
            catch ME
                fprintf('Invalid open needle dimension. Redo to have comparison');
            end
        end
        hold on;
        
        ylabel('1/Capacitance^2 (1/F^2)');
        xlabel('Source Voltage (V)');
    end
    
    for i=1:4
        pause(1);
        waitbar(1,progress,'Ramping down');
        voltagestr = ['SOUR:VOLT:LEV ' num2str(voltages(voltage_idx)*(4-i)/4)];
        fprintf(InstrV, voltagestr);
    end
end % the measurement

fprintf(InstrV, strcat('SOUR:VOLT:LEV 0'));
% turn the voltage off
fprintf(InstrV,':OUTP OFF');
fprintf(InstrV,'*RST');
fprintf(InstrV,'*CLS');

fprintf(InstrC,'*RST');
fprintf(InstrC,'*CLS');

waitbar(1,progress,'Measurements done');
delete(progress);




%After the measurements are done, close the instruments
fclose(InstrV);
delete(InstrV);
fclose(InstrC);
delete(InstrC);

%Saving the results in txt and saving/printing the figure
hold off;
print(CVcurve,'-dpdf',['Figures\' filename,'.pdf']);
savefig(CVcurve, ['Figures\' filename '.fig']);

%fprintf(['Standard deviation capacitance: ', num2str(std(capacitance(:,:))), ' A \n']);
%fprintf(['Standard deviation dissipation: ', num2str(std(dissipation(:,:))), ' A \n']);

% Save open needle if exists
if(isequal(size(BGcapacitance),[n_repeats, n_points]) ...
        && ~isequal(BGcapacitance,zeros(n_repeats,n_points)))
    % add t to 'wt' to open as text file : new line works
    fileID = fopen(['Data\' filename 'OpenNeedle.txt'],'wt');
    fprintf(fileID,'Source-Voltage [V]    ');
    for i=1:n_repeats
        fprintf(fileID,'Capacitance %d [F]    Dissipation %d     ', i, i )
    end
    %change of row
    fprintf(fileID,'\n')
    for i=1:n_points
        fprintf(fileID,'%e         ',voltages(i))
        for j=1:n_repeats
            fprintf(fileID,'%e         %e      ',...
                BGcapacitance(j,i),...
                BGdissipation(j,i));
        end
        fprintf(fileID,'\n');
    end
    fclose(fileID);
end

% Save data
fileID = fopen(['Data\' filename '.txt'],'wt');
fprintf(fileID,'Source-Voltage [V]    ');
for i=1:n_repeats
    fprintf(fileID,'Capacitance %d [F]    Dissipation %d     ', i, i )
end
%change of row
fprintf(fileID,'\n')
for i=1:n_points
    fprintf(fileID,'%e         ',voltages(i))
    for j=1:n_repeats
        fprintf(fileID,'%e         %e      ',...
            capacitance(j,i),...
            dissipation(j,i));
    end
    fprintf(fileID,'\n');
end
fclose(fileID);
cd(olddir);

fprintf('Data and figure saved\n');
fprintf('To close figure(s), type close all\n');
fprintf('To clear variables from memory, type clear all\n');
fprintf('Measurements done! :)\n');
fprintf('Everything went better than expected\n');
