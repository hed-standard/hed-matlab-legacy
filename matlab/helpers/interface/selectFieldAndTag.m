function [fMap, canceled] = selectFieldAndTag(initialfMap, varargin)
varargin = varargin{:};
fMap = initialfMap;
[~, primaryField] = getkeyvalue('PrimaryEventField',varargin{:});
fields = fMap.getFields();

%% Defining GUI elements
geometry = {[0.5] ...
            [0.5] ...
            [0.5] ...
            [0.3 0.5] ...
            [0.5]};
uilist = {...
    {'Style', 'text', 'string', 'Select a field then click "Tag"', 'FontWeight', 'bold'} ...
    {'Style', 'listbox', 'string', fields, 'tag', 'listboxCB', 'HorizontalAlignment','left'} ...
    {'Style', 'pushbutton', 'string', 'Tag', 'FontWeight','bold','tag', 'TagBtn', 'callback', @tagCallback} ...
    {'Style', 'text', 'string', 'Primary field:','HorizontalAlignment','left'} ...
    {'Style', 'popupmenu', 'string', fields, 'Value', find(strcmp(fields,primaryField)), 'tag', 'primaryFieldBox'} ...
    {'Style', 'text', 'string', 'Click "Ok" to continue when finish tagging'}};

%% Waiting for user input
[tmp1, tmp2, strhalt, structout] = inputgui( 'geometry', geometry, 'geomvert',[1 8 1.3 1.5 1], 'uilist', uilist, ...
           'helpcom', 'pophelp(''pop_tageeg'');', 'title', 'Select field to use for tagging -- pop_tageeg()');
    
%% Set values accordingly 
if isempty(structout) % if canceled
    canceled = true;
    fMap = initialfMap;
end        

     %% Callback for button "Tag"
    % Tag selected field. Can be repeated while select field window is
    % still on and fMap (shared across tagging sessions) will keep being updated
    function tagCallback(src, event) 
        % disable all buttons
        set(findobj('tag','primaryFieldBox'),'Enable','off');
        set(findobj('tag','listboxCB'),'Enable','off');
        set(findobj('tag','TagBtn'),'Enable','off');
        set(findobj('tag','cancel'),'Enable','off');
        set(findobj('tag','ok'),'Enable','off');
        % set primary field
        primaryFieldBox = findobj('tag', 'primaryFieldBox');
        primaryFieldIdx = get(primaryFieldBox,'Value');
        fieldsInBox = get(primaryFieldBox, 'String');
        selectedField = fieldsInBox{primaryFieldIdx};
        if (fMap.isField(selectedField)) 
            fMap.setPrimaryMap(selectedField);
        else
            error("Error in pop_tageeg: selected primary field is not in fMap");
        end
%         p.PrimaryEventField = selectedField;
        % prepare input arguments
        selected = get(findobj('Tag', 'listboxCB'),'Value');
        mainOptions = get(findobj('Tag','listboxCB'),'string');
        args = {'EventFieldsToIgnore', setdiff(mainOptions,mainOptions{selected})};
        editmapsInputArgs = [getkeyvalue({'HedExtensionsAllowed', 'PreserveTagPrefixes'}, ...
                varargin{:}) args];
            
        % call CTAGGER
        [fMap, canceled] = editmaps(fMap, editmapsInputArgs{:});
        
        % finish tagging, return control to fieldSelectWindow
        set(findobj('Tag','listboxCB'),'Enable','on');
        set(findobj('Tag','TagBtn'),'Enable','on');
        set(findobj('tag','cancel'),'Enable','on');
        set(findobj('tag','ok'),'Enable','on');
    end % tagFieldCallback

    %% Callback for closing buttons in fieldSelectWindow
    % Close fieldSelectWindow
    % if Cancel button was clicked, restore orignial fMap
    function fieldSelectCloseCallback(src, event, f, initialfMap)
        if isfield(src,'String') && strcmp(src.String,'Cancel')
            canceled = true;
            fMap = initialfMap;
            close(f);
        else
            close(f);
        end
    end % fieldSelectCloseCallback
end