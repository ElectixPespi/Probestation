clear all; close all;

sprintf('Prepare for open-needle measurement')

    % Create dialog box for BACKGROUND measurement
%     f1 = figure(1); % Figure where each CV measurement is plotted piecewise
%     movegui(f1,'southeast')
    
    % Open clamps measurement
    % UI control to do the Open clamps measurement
    
    
    SupportFunctions
    ButtonValue = ans.ButtonValue.String;
    
%     BackGround = uicontrol('Parent',f1,'Style','pushbutton', ...
%                  'String', {'Do open-clamp measurement'}, ...
%                  'Position',[81,200,419,23],'Callback', ...
%                  SupportFunctions);
%     
%     % UI control to cancwel and close instruments.
%     CloseMeasurement = uicontrol('Parent',f1,'Style','pushbutton', ...
%                  'String', 'Cancel', 'Position', ...
%                  [81,150,419,23], 'Callback', ...
%                  'cancelMesurement_Callback');
%     
%     % Info message of what to do
%     mTextBox1 = uicontrol('style','text')
%         set(mTextBox1,'String',{'Open clamp measurement:'}, ...
%                       'Units', 'characters')
%         set(mTextBox1,'Position', [35 25 50 4]) % [x y length height]
%     
%     mTextBox2 = uicontrol('style','text')
%         set(mTextBox2,'String',{'DETACH needles FROM sample'}, ...
%                       'FontSize', 25, 'backgroundcolor', 'r', ...
%                       'Units','characters')
%         set(mTextBox2,'Position', [35 17.7 50 9.5]) % [x y length height]
%         
%     uiwait(gcf); % Wait for user input           
%     
%     ButtonValue = ans;