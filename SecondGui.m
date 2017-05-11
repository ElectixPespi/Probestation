function S = SecondGUI

    S.f3 = figure('Name', 'Measurement GUI'); % Figure where each CV measurement is plotted piecewise
    movegui(S.f3,'southeast')
    S.ButtonValue = uicontrol('style','edit', 'Visible', 'off', 'string','Data');
    
    S.BackGround = uicontrol('Parent',S.f3,'Style','pushbutton', ...
                 'String', {'Do ACTUAL measurement'}, ...
                 'Position',[81,200,419,23],'Callback', ...
                 {@SupportMeasurement,S});
    
    % UI control to cancwel and close instruments.
    S.CloseMeasurement = uicontrol('Parent',S.f3,'Style','pushbutton', ...
                 'String', 'Cancel', 'Position', ...
                 [81,150,419,23], 'Callback', ...
                 {@SupportCancel,S});
    
    % Info message of what to do
    mTextBox3 = uicontrol('style','text');
        set(mTextBox3,'String',{'Actual measurement:'}, ...
                      'Units', 'characters');
        set(mTextBox3,'Position', [35 25 50 4]) % [x y length height]
    
    mTextBox4 = uicontrol('style','text');
        set(mTextBox4,'String',{'ATTACH needles TO sample'}, ...
                      'FontSize', 25, 'backgroundcolor', 'g', ...
                      'Units','characters');
        set(mTextBox4,'Position', [35 17.7 50 9.5]) % [x y length height]         
             
    uiwait(gcf); % Wait for user input

    function [S] = SupportMeasurement(varargin)
        display('Taking open-needle data.');
        S = varargin{3};  % Get the structure.
        set(varargin{1,3}.ButtonValue, 'String', 'Measure');
        uiresume(gcbf)
        return;
    end

    function [S] = SupportCancel(varargin)
        % change vaiables and give back to main function
        display('Measurement has been canceled.');
        S = varargin{3};  % Get the structure.
        set(varargin{1,3}.ButtonValue, 'String', 'Cancel');
        uiresume(gcbf)
        return;
    end
end













