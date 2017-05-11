function S = FirstGUI

    S.f1 = figure('Name', 'Background GUI'); % Figure where each CV measurement is plotted piecewise
    movegui(S.f1,'southeast')
    
    % Creat measurement button
    S.ButtonValue = uicontrol('style','edit', 'Visible', 'off', 'string','Data');
    
    S.BackGround = uicontrol('Parent',S.f1,'Style','pushbutton', ...
                 'String', {'Do open-clamp measurement'}, ...
                 'Position',[81,200,419,23],'Callback', ...
                 {@SupportBackGround,S});
    
    % Creat load previous data button
    S.SkipData = uicontrol('Parent',S.f1,'Style','pushbutton', ...
                 'String', {'Skip previous open-needle data'}, ...
                 'Position',[81,150,419,23],'Callback', ...
                 {@SupportSkipData,S});
             
    % UI control to cancwel and close instruments.
    S.CloseMeasurement = uicontrol('Parent',S.f1,'Style','pushbutton', ...
                 'String', 'Cancel', 'Position', ...
                 [81,100,419,23], 'Callback', ...
                 {@SupportCancel,S});
    
    % Info message of what to do
    mTextBox1 = uicontrol('style','text');
        set(mTextBox1,'String',{'Open clamp measurement:'}, ...
                      'Units', 'characters');
        set(mTextBox1,'Position', [35 25 50 4]); % [x y length height]
    
    mTextBox2 = uicontrol('style','text');
        set(mTextBox2,'String',{'DETACH needles FROM sample'}, ...
                      'FontSize', 25, 'backgroundcolor', 'r', ...
                      'Units','characters');
        set(mTextBox2,'Position', [35 17.7 50 9.5]); % [x y length height]
        
    uiwait(gcf); % Wait for user input

%% Assing answer of which button has been pusehed to output variable
    
    % Take open needle measurement
    function [S] = SupportBackGround(varargin)
        display('Taking open-needle data.');
        S = varargin{3};  % Get the structure.
        set(varargin{1,3}.ButtonValue, 'String', 'Background');
        uiresume(gcbf);
        return;
    end
    
    % Skip previous open needle data
    function [S] = SupportSkipData(varargin)
        display('Skip open-needle measurement.');
        S = varargin{3};  % Get the structure.
        set(varargin{1,3}.ButtonValue, 'String', 'SkipBGData');
        uiresume(gcbf);
        return;
    end

    function [S] = SupportCancel(varargin)
        % change vaiables and give back to main function
        display('Measurement has been canceled.');
        S = varargin{3};  % Get the structure.
        set(varargin{1,3}.ButtonValue, 'String', 'Cancel');
        uiresume(gcbf);
        return;
    end
end














