% Clear possible previous business
clear all;
close all;

% Ask about details of measurement with inputsdlg
Title = 'V-I measurement input';

Prompt ={};
Formats = {};
DefAns = struct([]);
Options.Resize = 'on';
Boxsize = 200;

Prompt(1,:)= {'Enter the working directory:','WorkDir',[]};
Formats(1,1).type = 'edit';
Formats(1,1).format = 'text';
Formats(1,1).size = 1.5*Boxsize;
DefAns(1).WorkDir = 'C:\Users\HIPadmin\Desktop\Probestation\Development';

Prompt(2,:)= {'Enter name for output file (automatically .txt):','FileName',[]};
Formats(2,1).type = 'edit';
Formats(2,1).format = 'text';
Formats(2,1).size = Boxsize;
DefAns(1).FileName = 'CMS_BLT_C5_runX';

Prompt(3,:)= {'Enter initial voltage (in Volts):','InitialVoltage',[]};
Formats(3,1).type = 'edit';
Formats(3,1).format = 'integer';
Formats(3,1).size = Boxsize;
DefAns(1).InitialVoltage = -1;

Prompt(4,:)= {'Enter final voltage (in Volts):','FinalVoltage',[]};
Formats(4,1).type = 'edit';
Formats(4,1).format = 'integer';
Formats(4,1).size = Boxsize;
DefAns(1).FinalVoltage = -250;

Prompt(5,:)= {'Enter the number of measurement steps:','MeasSteps',[]};
Formats(5,1).type = 'edit';
Formats(5,1).format = 'integer';
Formats(5,1).size = Boxsize;
DefAns(1).MeasSteps = 31;

Prompt(6,:) ={'Enter the number of measurements at a voltage step:','NMeas',[]};
Formats(6,1).type = 'edit';
Formats(6,1).format = 'integer';
Formats(6,1).size = Boxsize;
DefAns(1).NMeas = 1;

Prompt(7,:) ={'Enter delay before a current measurement (s):','MeasDelay',[]};
Formats(7,1).type = 'edit';
Formats(7,1).format = 'integer';
Formats(7,1).size = Boxsize;
DefAns(1).MeasDelay = 1;
Prompt(8,:) = {'Irradiated or NON-irradiated sample?', 'NonIrr',[]};

Formats(8,1).type = 'list';
Formats(8,1).format = 'text';
Formats(8,1).style = 'radiobutton';
Formats(8,1).items = {'NON-Irradiated' 'Irradiated' 'high current'};
DefAns(1).NonIrr = 'NON-Irradiated';

[answer, cancelled] = inputsdlg(Prompt,Title,Formats,DefAns,Options);

if cancelled == 1
    sprintf('Measurement Aborted');
    clear all; close all;
    return;
end

filename = answer.FileName;
workdir=answer.WorkDir;
output_name = ['Data\' filename '.txt'];
n_repeats = answer.NMeas;
n_points = answer.MeasSteps;
Vinit = answer.InitialVoltage;
Vfinal = answer.FinalVoltage;
meas_delay = answer.MeasDelay;

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
    

% measurement range and compliance level;
switch answer.NonIrr
case 'NON-Irradiated'
    I_limit = 2e-7;
case 'Irradiated'
    I_limit = 2e-5;
case 'high current'
    I_limit = 2e-3;
end

% Measurement per se

% waitbar for measurement process

progress = waitbar(0,'Connecting to instruments','name','VI measurement',...
'CreateCancelBtn','setappdata(gcbf,''cancelling'',1)');


% Addresses to Keithley instruments
% First for voltage generation etc.
% Second for current measuring
KeithAddress = [23 21 22];
% check whether already open
KeithV= instrfind('Type', 'gpib', 'BoardIndex', 0, 'PrimaryAddress', KeithAddress(1), 'Tag', '');
KeithI1= instrfind('Type', 'gpib', 'BoardIndex', 0, 'PrimaryAddress', KeithAddress(2), 'Tag', '');
KeithI2= instrfind('Type', 'gpib', 'BoardIndex', 0, 'PrimaryAddress', KeithAddress(3), 'Tag', '');

if isempty(KeithV)
    KeithV = gpib('NI', 0, KeithAddress(1)); 
else
    fclose(KeithV);
    KeithV=KeithV(1);
end
if isempty(KeithI1)
    KeithI1 = gpib('NI', 0, KeithAddress(2)); 
else
    fclose(KeithI1);
    KeithI1=KeithI1(1);
end
if isempty(KeithI2)
    KeithI2 = gpib('NI', 0, KeithAddress(3)); 
else
    fclose(KeithI2);
    KeithI2=KeithI2(1);
end

% Connect to the instruments
fprintf('Connecting to voltage source\n');
try
    fopen(KeithV);
catch ME
    fprintf('Could not connect to the voltage source\n');
    delete KeithV;
    delete KeithI1;
    delete KeithI2;
    delete(progress);
    cd(olddir);
    clear all; close all;
    return;
end
fprintf('Connection acquired\n');
fprintf('Connecting to current meter 1\n');
try
    fopen(KeithI1);
catch ME
    fprintf('Could not connect to the current meter 1\n');
    fclose(KeithV);
    delete(KeithV);
    delete(KeithI1);
    delete(KeithI2);
    cd(olddir);
    delete(progress);
    clear all; close all;
    return;
end
fprintf('Connection acquired\n');
fprintf('Connecting to current metter 2\n');
try
    fopen(KeithI2);
catch ME
    fprintf('Could not connect to the current metter 2\n');
    fclose(KeithV);
    delete(KeithV);
    fclose(KeithI1);
    delete(KeithI1);
    delete(KeithI2);
    cd(olddir);
    clear all; close all;
    delete(progress);
    return;
end


% Configure property values (probably not necessary)
% End of string for writing and reading
% is by default 'LF' meaning that 
% each command is completed by line feed character
%KeithV.EOSMode = 'read&write';
%KeithI.EOSMode = 'read&write';

% Setting the measurements 
% Setting the voltage etc. metter

% I and V ranges
I_ranges = [ 2E-2 2E-3 2E-4 2E-5 2E-6 2E-7 2E-8 2E-9 ];

% setting the V  measurement 
% setting initial V range
% if abs(Vfinal) < abs(Vinit)
%    helper = Vfinal;
%    Vfinal = Vinit;
%    Vinit = helper;
% end


% ways of plotting
IVcurve=figure;

ylabel('Average measured current [A]');
xlabel('Source-Voltage [V]');
hold on;





cancelation = 0;

% Zero checks etc for ampere metter 1
fprintf(KeithI1,'*RST');
fprintf(KeithI1,'FUNC ''CURR''');
fprintf(KeithI1,'SYST:AZER ON');
%fprintf(KeithI1,'SYST:ZCH ON');
%fprintf(KeithI1,'CURR:RANGE 2e-9');
%fprintf(KeithI1,'INIT');
%fprintf(KeithI1,'SYST:ZCOR:STAT OFF');
%fprintf(KeithI1,'SYST:ZCOR:ACQ');
%fprintf(KeithI1,'SYST:ZCOR ON');
fprintf(KeithI1,'CURR:RANG:AUTO ON');
fprintf(KeithI1,'SYST:ZCH OFF');


% Zero checks etc for ampere metter 2
fprintf(KeithI2,'*RST');
fprintf(KeithI2,'FUNC ''CURR''');
fprintf(KeithI2,'SYST:AZER ON');
%fprintf(KeithI2,'SYST:ZCH ON');
%fprintf(KeithI2,'CURR:RANGE 2e-9');
%fprintf(KeithI2,'INIT');
%fprintf(KeithI2,'SYST:ZCOR:STAT OFF');
%fprintf(KeithI2,'SYST:ZCOR:ACQ');
%fprintf(KeithI2,'SYST:ZCOR ON');
fprintf(KeithI2,'CURR:RANG:AUTO ON');
fprintf(KeithI2,'SYST:ZCH OFF');


% voltage points
voltages = linspace(Vinit,Vfinal,n_points);
% current values 
Vcurrent = zeros(n_points,n_repeats);
Icurrent = zeros(n_points,n_repeats);

% Initialization for voltage source
% Set the box to voltage setting
fprintf(KeithV,'*RST');
fprintf(KeithV,':ROUT:TERM REAR');
fprintf(KeithV, strcat(':SOUR:FUNC VOLT'));
fprintf(KeithV, strcat(':SOUR:VOLT:MODE FIX'));
fprintf(KeithV, strcat(':SENS:CURR:PROT 10E-4'));


if abs(Vfinal) > 20 && abs(Vfinal) <= 500
    fprintf(KeithV,':SOUR:VOLT:RANG 1000');
end
if abs(Vfinal) > 500
    fprintf('Too high highest voltage (over 500 V), aborting');
    fclose(KeithV);
    delete(KeithV);
    fclose(KeithI1);
    delete(KeithI1);
    fclose(KeithI2);
    delete(KeithI2);
    delete(progress);
    cd(olddir);
    return;
end

% setting initial V
fprintf(KeithV, strcat(':SOUR:VOLT:LEV 0'));
% setting the current limit
%fprintf(KeithV,strcat('SOUR:VOLT:ILIM ',I_limit));

% boolean for current compliance
stopping = 0;
% turn the voltage on
fprintf(KeithV,':OUTP ON');


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
    fprintf(KeithV,voltagestr);
    %fprintf(KeithV,'SOUR:VOLT:STAT ON');
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
        waitbar(((i-1)*n_repeats+j)/(n_points*n_repeats),progress,'Measuring current');
        
        fprintf(KeithI1,'FUNC ''CURR''');
        fprintf(KeithI1,'READ?');
        curstr=scanstr(KeithI1);
        current=sscanf(curstr{1},'%fA')
        
        Icurrent(i,j)=current;
        if(abs(current) > I_limit)
            fprintf('Pad current exceeds compliance limit. Aborting\n');
            waitbar(1,progress,'Pad current exceeds compliance limit. Aborting');
            stopping = 1;
            break;
        end

        %fprintf(KeithV,'*RST');
        %fprintf(KeithV,'FUNC ''CURR''');

        fprintf(KeithI2,'FUNC ''CURR''');
        fprintf(KeithI2,'READ?');
        curstr=scanstr(KeithI2);
        current = sscanf(curstr{1},'%fA')
        Vcurrent(i,j)=current;
        if(abs(current) > I_limit)
            fprintf('Guard ring current exceeds compliance limit. Aborting\n');
            waitbar(1,progress,'Guard ring current exceeds compliance limit. Aborting');
            stopping = 1;
            break;
        end
    end
    if(stopping == 1)
        break;
    end
    subplot(2,1,1);
    if(Vfinal<0)
        set(gca,'Xdir','reverse');
        set(gca,'Ydir','reverse');
    end
    plot(voltages(i),mean(Icurrent(i,:)),':bo',...
    'LineWidth',1, ...
    'MarkerEdgeColor','k',...
    'MarkerFaceColor','r',...
    'MarkerSize',5);
    hold on;
    titlestr = ['Voltage steeps from ' num2str(Vinit) ' V to ' ...
        num2str(Vfinal) ' V in ' num2str(n_points) ' steps' ]
    title(titlestr);
    ylabel('Pad Current (A)');
    xlabel('Source Voltage');

    subplot(2,1,2);
    if(Vfinal<0)
        set(gca,'Xdir','reverse');
        set(gca,'Ydir','reverse');
    end
    plot(voltages(i),mean(Vcurrent(i,:)),':bo',...
    'LineWidth',1, ...
    'MarkerEdgeColor','k',...
    'MarkerFaceColor','r',...
    'MarkerSize',5);
    hold on;

    ylabel('Guard-Ring Current (A)');
    xlabel('Source Voltage');

    drawnow limitrate nocallbacks;

end

for i=1:4
    pause(1);
    waitbar(1,progress,'Ramping down');
    voltagestr = ['SOUR:VOLT:LEV ' num2str(voltages(voltage_idx)*(4-i)/4)];
    fprintf(KeithV, voltagestr);
end

fprintf(KeithV, strcat('SOUR:VOLT:LEV 0'));
% turn the voltage off
fprintf(KeithV,':OUTP OFF');
fprintf(KeithV,'*RST');
fprintf(KeithV,'*CLS');

fprintf(KeithI1,'*RST');
fprintf(KeithI1,'*CLS');
fprintf(KeithI2,'*RST');
fprintf(KeithI2,'*CLS');

waitbar(1,progress,'Measurements done');
delete(progress);



%After the measurements are done, close the instruments
fclose(KeithV);
delete(KeithV);
fclose(KeithI1);
delete(KeithI1);
fclose(KeithI2);
delete(KeithI2);

%Saving the results in txt and saving/printing the figure
hold off;
print(IVcurve,'-dpdf',['Figures\' filename,'.pdf']);
savefig(IVcurve, ['Figures\' filename '.fig']);

fprintf(['Standard deviation PAD current: ', num2str(std(Icurrent(:,:))), ' A \n']); 
fprintf(['Standard deviation GUARD current: ', num2str(std(Vcurrent(:,:))), ' A \n']); 

% add t to 'wt' to open as text file : new line works
fileID = fopen(['Data\' filename '.txt'],'wt');
fprintf(fileID,'Source-Voltages Top Keithley Measured Current Bottom Keithley Measured Current 2\n');
for i=1:n_points
    for j=1:n_repeats
        fprintf(fileID,'%e %e %e\n',voltages(i),Icurrent(i,j), Vcurrent(i,j));
    end 
end
cd(olddir);
fprintf('Data and figure saved\n');
fprintf('Measurements done! :)\n');



