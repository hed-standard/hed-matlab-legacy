% Show select field and tag window
% This window includes option to change HED schema, import tag, and
% select field to tag
%
% Usage:
%
%   >>  [fMap, canceled] = selectFieldAndTag(basefMap, varargin)
% Copyright (C) 2020 Dung Truong dutruong@ucsd.edu
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
function [fMap, canceled] = selectFieldAndTag(initialfMap, p)
fMap = initialfMap;
hedVersion = getxmlversion(p.HedXml);
canceled = false;
taggingFields = fMap.getFields(); %setdiff(fieldnames(EEG.event), p.EventFieldsToIgnore);

%% Defining GUI elements
geometry = {[1] ...
            [1] ...
            [1] ...
            [1] ...
            [1 1]};
uilist = {...
    {'Style', 'text', 'string', ['HED version: ' hedVersion], 'tag', 'hedVersion'} ...
    {'Style', 'text', 'string', 'Select a field and click "Tag"', 'FontWeight', 'bold'} ...
    {'Style', 'listbox', 'string', taggingFields, 'tag', 'listboxCB', 'HorizontalAlignment','left'} ...
    {'Style', 'pushbutton', 'string', 'Tag', 'FontWeight','bold','tag', 'TagBtn', 'callback', @tagCallback} ...
    { 'style', 'pushbutton' , 'string', 'Cancel', 'tag', 'cancel', 'callback', @fieldSelectCloseCallback},...
    { 'style', 'pushbutton' , 'string', 'Done', 'tag', 'ok', 'callback', @fieldSelectCloseCallback}};

% Draw supergui
[~,~, handles] = supergui( 'geomhoriz', geometry, 'geomvert',[1 1 8 1.3 1], 'uilist', uilist, 'title', 'Select field to use for tagging -- pop_tageeg()');
figure_handle = get(handles{1},'parent');
% Add menu items
file_menu = uimenu(figure_handle,'Text','File');
uimenu(file_menu,'Text','Change HED version','MenuSelectedFcn',@changeHEDVersion);
uimenu(file_menu,'Text','Import tags','MenuSelectedFcn',@importMap);
% Select "type" by default
listbox = findobj('Tag','listboxCB');
index = find(strcmp(get(listbox,'String'),'type'));
if ~isempty(index)
   set(listbox,'Value',index);
end
%% Waiting for user input
waitfor(figure_handle);    

    
     %% Callback for button "Tag"
    % Tag selected field. Can be repeated while select field window is
    % still on and fMap (shared across tagging sessions) will keep being updated
    function tagCallback(~, ~)         
        % disable all buttons
        set(findobj('tag','primaryFieldBox'),'Enable','off');
        set(findobj('tag','listboxCB'),'Enable','off');
        set(findobj('tag','TagBtn'),'Enable','off');
        set(findobj('tag','cancel'),'Enable','off');
        set(findobj('tag','ok'),'Enable','off');
        
        % prepare input arguments
        selected = get(findobj('Tag', 'listboxCB'),'Value');
        listboxOptions = get(findobj('Tag','listboxCB'),'string');
        editmapsInputArgs = {'EventFieldsToIgnore', setdiff(listboxOptions,listboxOptions{selected})};
            
        % call CTAGGER
        [fMap, ~] = editmaps(fMap, editmapsInputArgs{:});
        
        % finish tagging, return control to fieldSelectWindow
        set(findobj('Tag','listboxCB'),'Enable','on');
        set(findobj('Tag','TagBtn'),'Enable','on');
        set(findobj('tag','cancel'),'Enable','on');
        set(findobj('tag','ok'),'Enable','on');
    end % tagFieldCallback
    
    %% Callback for loading new HED XML file
    function changeHEDVersion(~, ~)
        % Callback for 'Browse' button that sets the 'HED' editbox
        [tFile, tPath] = uigetfile({'*.xml', 'XML files (*.xml)'}, ...
            'Browse HED schema file');
        if tFile ~= 0
            hedXml = fullfile(tPath, tFile);
            xml = fileread(hedXml); % to set new HED XML for fieldMap, needs to read xml file into a string
            fMap.setXml(xml); % <-- editmaps() (CTAGGER) will retrieve HED Schema from the Xml field of fMap
            hedVersion = getxmlversion(hedXml);
            set(findobj('Tag', 'hedVersion'), 'String', ['HED version: ' hedVersion]);
        end
    end
    %% Callback for loading fieldMap
    function importMap(~, ~)
        % Callback for 'Browse' button that sets the 'HED' editbox
        [tFile, tPath] = uigetfile({'*.mat', 'MATLAB object (*.mat)'}, ...
            'Browse MATLAB tag map');
        if tFile ~= 0
            fMapPath = fullfile(tPath, tFile);
            baseMap = fieldMap.loadFieldMap(fMapPath);
            % merge tag map
            fMap.merge(baseMap, 'Update', {}, {});
            [~,~, h] = supergui( 'geomhoriz', { 1 1 1 }, 'uilist', { ...
             { 'style', 'text', 'string', 'Tags imported' }, { }, ...
             { 'style', 'pushbutton' , 'string', 'OK' 'callback' 'close(gcbf);' } } );
            waitfor(h);
        end
    end
    %% Callback for closing buttons in fieldSelectWindow
    % Close fieldSelectWindow
    % if Cancel button was clicked, restore orignial fMap
    function fieldSelectCloseCallback(src, ~)
        if strcmp(src.String,'Cancel')
            canceled = true;
            fMap = initialfMap;
            close(gcbf);
        else
            close(gcbf);
        end
    end % fieldSelectCloseCallback
end