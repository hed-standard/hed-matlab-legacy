% tagdir_input
% GUI for input needed to create inputs for tagdir function
%
% Usage:
%   >>  tagdir_input()
%
% Description:
% tagcsv_input() brings up a GUI for input needed to create inputs for
% tagdir
%
% Function documentation:
% Execute the following in the MATLAB command window to view the function
% documentation for tagdir_input:
%
%    doc tagdir_input
% See also: tagdir, pop_tagdir
%
% Copyright (C) Kay Robbins and Thomas Rognon, UTSA, 2011-2013,
% krobbins@cs.utsa.edu
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
%
% $Log: tagdir_input.m,v $
% $Revision: 1.0 21-Apr-2013 09:25:25 krobbins $
% $Initial version $
%

function [cancelled, inDir, baseMap, doSubDirs, editXml, ...
    preservePrefix, rewriteOption, saveDatasets, saveMapFile, ...
    selectOption, useGUI, writeTags] = tagdir_input()

% Setup the variables used by the GUI
baseMap = '';
cancelled = true;
doSubDirs = true;
inDir = '';
preservePrefix = false;
editXml = false;
rewriteOption = 'preserve';
saveDatasets = true;
saveMapFile = '';
selectOption = true;
useGUI = true;
title = 'Inputs for tagging directory of data files';
writeTags = true;
inputFig = figure( ...
    'Color', [.94 .94 .94], ...
    'MenuBar', 'none', ...
    'Name', title, ...
    'NextPlot', 'add', ...
    'NumberTitle','off', ...
    'Resize', 'on', ...
    'Tag', title, ...
    'Toolbar', 'none', ...
    'Visible', 'off', ...
    'WindowStyle', 'modal');
createLayout();
movegui(inputFig); % Make sure it is visible
uiwait(inputFig);

    function createLayout()
        createBrowsePanel();
        createWriteGroupPanel();
        createOptionsGroupPanel();
        createButtonPanel();
    end

    function browseSaveTagsCallback(~, ~)
        % Callback for browse button sets a directory for control
        [file,path] = uiputfile({'*.mat', 'MATLAB Files (*.mat)'}, ...
            'Save field map', 'fMap.mat');
        if ischar(file) && ~isempty(file)
            saveMapFile = fullfile(path, file);
            set(findobj('Tag', 'SaveTags'), 'String', saveMapFile);
        end
    end % browseSaveTagsCallback

    function browseTagsCallback(~, ~)
        % Callback for browse button sets a directory for control
        [file, path] = uigetfile({'*.mat', 'MATLAB Files (*.mat)'}, ...
            'Browse for base tags');
        tagsFile = fullfile(path, file);
        if ischar(file) && ~isempty(file) && validateBaseTags(tagsFile)
            baseMap = fullfile(path, file);
            set(findobj('Tag', 'BaseTags'), 'String', baseMap);
        end
    end % browseTagsCallback


    function createBrowsePanel()
        browsePanel = uipanel('BorderType','none', ...
            'BackgroundColor',[.94 .94 .94],...
            'FontSize',12,...
            'Position',[0 .7 1 .3]);
        uicontrol('Parent', browsePanel, ...
            'Style','text', 'String', 'Directory', ...
            'Units','normalized',...
            'HorizontalAlignment', 'Left', ...
            'Position', [0.015 0.8 0.1 0.13]);
        uicontrol('Parent', browsePanel, ...
            'Style','text', 'String', 'Base tags', ...
            'Units','normalized',...
            'HorizontalAlignment', 'Left', ...
            'Position', [0.015 0.5 0.12 0.13]);
        uicontrol('Parent', browsePanel, ...
            'Style','text', 'String', 'Save tags', ...
            'Units','normalized',...
            'HorizontalAlignment', 'Left', ...
            'Position', [0.015 .2 0.12 0.13]);
        uicontrol('Parent', browsePanel, 'Style', 'edit', ...
            'BackgroundColor', 'w', 'HorizontalAlignment', 'Left', ...
            'Tag', 'Directory', 'String', '', ...
            'TooltipString', ...
            'Directory of .set files', ...
            'Units','normalized',...
            'Callback', @dirCtrlCallback, ...
            'Position', [0.15 0.7 0.6 0.25]);
        uicontrol('Parent', browsePanel, 'style', 'edit', ...
            'BackgroundColor', 'w', 'HorizontalAlignment', 'Left', ...
            'Tag', 'BaseTags', 'String', '', ...
            'TooltipString', ...
            'Complete path for loading the consolidated event tags', ...
            'Units','normalized',...
            'Callback', @tagsCtrlCallback, ...
            'Position', [0.15 0.4 0.6 0.25]);
        uicontrol('Parent', browsePanel, 'Style', 'edit', ...
            'BackgroundColor', 'w', 'HorizontalAlignment', 'Left', ...
            'Tag', 'SaveTags', 'String', '', ...
            'TooltipString', ...
            'Complete path for saving the consolidated event tags', ...
            'Units','normalized',...
            'Callback', @saveTagsCtrlCallback, ...
            'Position', [0.15 0.1 0.6 0.25]);
        uicontrol('Parent', browsePanel, ...
            'string', 'Browse', ...
            'style', 'pushbutton', 'TooltipString', ...
            'Press to bring up directory chooser', ...
            'Units','normalized',...
            'Callback', @browseDirCallback, ...
            'Position', [0.775 0.7 0.21 0.25]);
        uicontrol('Parent', browsePanel, ...
            'string', 'Browse', 'style', 'pushbutton', ...
            'TooltipString', 'Press to choose BaseTags file', ...
            'Units','normalized',...
            'Callback', @browseTagsCallback, ...
            'Position', [0.775 0.4 0.21 0.25]);
        uicontrol('Parent', browsePanel, ...
            'string', 'Browse', 'style', 'pushbutton', ...
            'TooltipString', 'Press to find directory to save tags object', ...
            'Units','normalized',...
            'Callback', @browseSaveTagsCallback, ...
            'Position', [0.775 0.1 0.21 0.25]);
    end % createBrowsePanel

    function createOptionsGroupPanel()
        % Create the button panel on the side of GUI
        optionGroupPanel = uipanel('BackgroundColor',[.94,.94,.94],...
            'FontSize',12,...
            'Title','Other options', ...
            'Position',[0.535 .2 .45 .5]);
        uicontrol('Parent', optionGroupPanel, ...
            'Style', 'CheckBox', 'Tag', 'WriteTagsCB', ...
            'String', 'Save to directory dataset files', 'Enable', 'on', 'Tooltip', ...
            'If checked, save tags to directory dataset files', ...
            'Units','normalized', ...
            'Value', 1, ...
            'Callback', @saveCallback, ...
            'Position', [0.1 0.85 0.8 0.1]);
        uicontrol('Parent', optionGroupPanel, ...
            'Style', 'CheckBox', 'Tag', 'DoSubDirsCB', ...
            'String', 'Look in subdirectories', 'Enable', 'on', 'Tooltip', ...
            'If checked, traverse all subdirectories to process dataset files', ...
            'Units','normalized', ...
            'Value', 1, ...
            'Callback', @doSubDirsCallback, ...
            'Position', [0.1 0.7 0.8 0.1]);
        uicontrol('Parent', optionGroupPanel, ...
            'Style', 'CheckBox', 'Tag', 'UseGUICB', ...
            'String', 'Use GUI to edit tags', 'Enable', 'on', 'Tooltip', ...
            'If checked, use GUI to edit consolidated tags', ...
            'Units','normalized', ...
            'Value', 1, ...
            'Callback', @useGUICallback, ...
            'Position', [0.1 0.55 0.8 0.1]);
        uicontrol('Parent', optionGroupPanel, ...
            'Style', 'CheckBox', 'Tag', 'SelectFieldsCB', ...
            'String', 'Use GUI to select fields to tag', 'Enable', 'on', 'Tooltip', ...
            'If checked, use GUI to select which fields to tag', ...
            'Units','normalized', ...
            'Value', 1, ...
            'Callback', @selectCallback, ...
            'Position', [0.1 0.4 0.8 0.1]);
        uicontrol('Parent', optionGroupPanel, ...
            'Style', 'CheckBox', 'Tag', 'EditXMLCB', ...
            'String', 'XML containing schema can be edited', 'Enable', 'on', 'Tooltip', ...
            'If checked, XML containing all of the schema tags can be edited', ...
            'Units','normalized', ...
            'Value', 0, ...
            'Callback', @editXmlCallback, ...
            'Position', [0.1 0.25 0.9 0.1]);
        uicontrol('Parent', optionGroupPanel, ...
            'Style', 'CheckBox', 'Tag', 'PreservePrefixCB', ...
            'String', 'Preserve tag prefixes', 'Enable', 'on', 'Tooltip', ...
            'If checked, do not consolidate tags that share prefixes', ...
            'Units','normalized', ...
            'Value', 0, ...
            'Callback', @preservePrefixCallback, ...
            'Position', [0.1 0.1 0.8 0.1]);
    end % createOptionsGroupPanel

    function createWriteGroupPanel()
        % Create the button panel on the side of GUI
        writeButtonGroup = uibuttongroup('BackgroundColor',[.94,.94,.94],...
            'FontSize',12,...
            'Title','Data precision save options', ...
            'Tag', 'WriteButtonGroup', ...
            'SelectionChangeFcn', @rewriteCallback, ...
            'Position',[0.015 .2 .45 .5]);
        uicontrol('Parent', writeButtonGroup, ...
            'Style', 'RadioButton', 'Tag', 'Double', ...
            'String', 'Double (.set file)', 'Enable', 'On', ...
            'Tooltip', 'If selected, save the data as double precision and the dataset in a .set file', ...
            'Units','normalized', ...
            'Position', [0.1 0.8 0.8 0.1]);
        uicontrol('Parent', writeButtonGroup, ...
            'Style', 'RadioButton', 'Tag', 'Single One', ...
            'String', 'Single (.set file)', 'Enable', 'on', 'Tooltip', ...
            'If selected, save the data as single precision and the dataset in a .set file', ...
            'Units','normalized', ...
            'Position', [0.1 0.6 0.8 0.1]);
        uicontrol('Parent', writeButtonGroup, ...
            'Style', 'RadioButton', 'Tag', 'Single Two', ...
            'String', 'Single (.set and .fdt)', 'Enable', 'on', 'Tooltip', ...
            'If selected, save the data as single precision and the dataset in a .set and .fdt file', ...
            'Units','normalized', ...
            'Position', [0.1 0.4 0.8 0.1]);
        uicontrol('Parent', writeButtonGroup, ...
            'Style', 'RadioButton', 'Tag', 'Preserve', ...
            'String', 'Preserve', 'Enable', 'on', 'Tooltip', ...
            'If selected, preserve the data precision and preserve the way that the dataset is saved.', ...
            'Value', 1, ...
            'Units','normalized', ...
            'Position', [0.1 0.2 0.8 0.1]);
    end % createWriteGroupPanel


    function createButtonPanel()
        % Create the button panel on the side of GUI
        rewriteGroupPanel = uipanel('BorderType','none', ...
            'BackgroundColor',[.94 .94 .94],...
            'FontSize',12,...
            'Position',[0.6 0 .4 .2]);
        uicontrol('Parent', rewriteGroupPanel, ...
            'Style', 'pushbutton', 'Tag', 'OkayButton', ...
            'String', 'Okay', 'Enable', 'on', 'Tooltip', ...
            'Save the current configuration in a file', ...
            'Units','normalized', ...
            'Callback', {@okayCallback}, ...
            'Position',[0.025 0.3 0.45 0.4]);
        uicontrol('Parent', rewriteGroupPanel, ...
            'Style', 'pushbutton', 'Tag', 'CancelButton', ...
            'String', 'Cancel', 'Enable', 'on', 'Tooltip', ...
            'Cancel the directory tagging', ...
            'Units','normalized', ...
            'Callback', {@cancelCallback}, ...
            'Position',[0.515 0.3 0.45 0.4]);
    end % createButtonPanel


    function cancelCallback(src, eventdata)  %#ok<INUSD>
        % Callback for browse button sets a directory for control
        baseMap = '';
        cancelled = true;
        preservePrefix = false;
        rewriteOption = 'Preserve';
        saveMapFile = '';
        selectOption = true;
        useGUI = true;
        close(inputFig);
    end % browseTagsCallback

    function okayCallback(src, eventdata)  %#ok<INUSD>
        % Callback for closing GUI window
        cancelled = false;
        close(inputFig);
    end % okayCallback

    function saveTagsCtrlCallback(hObject, eventdata, saveTagsCtrl) %#ok<INUSD>
        % Callback for user directly editing directory control textbox
        saveMapFile = get(hObject, 'String');
    end % saveTagsCtrlCallback

    function preservePrefixCallback(src, eventdata) %#ok<INUSD>
        preservePrefix = get(src, 'Max') == get(src, 'Value');
    end % preservePrefixCallback

    function rewriteCallback(src, ~)
        % Callback for the radio button group
        rewriteOption = lower(get(get(src, 'SelectedObject'), 'Tag'));
    end % rewriteCallback

    function selectCallback(src, eventdata) %#ok<INUSD>
        selectOption = get(src, 'Max') == get(src, 'Value');
    end % selectCallback

    function tagsCtrlCallback(hObject, eventdata, tagsCtrl) %#ok<INUSD>
        % Callback for user directly editing directory control textbox
        tagsFile = get(src, 'String');
        if ~isempty(strtrim(tagsFile)) && validateBaseTags(tagsFile)
            baseMap = tagsFile;
        end
    end % tagsCtrlCallback

    function valid = validateBaseTags(tagsFile)
        valid = true;
        if isempty(fieldMap.loadFieldMap(tagsFile))
            valid = false;
            warndlg([ tagsFile ...
                ' is a invalid base tag file'], 'Invalid file');
            set(findobj('Tag', 'BaseTags'), 'String', baseMap);
        end
    end % validateBaseTags

    function useGUICallback(src, eventdata) %#ok<INUSD>
        useGUI = get(src, 'Max') == get(src, 'Value');
        if ~useGUI
            set(findobj('Tag', 'SelectFieldsCB'), 'Enable', 'off');
            set(findobj('Tag', 'EditXMLCB'), 'Enable', 'off');
            set(findobj('Tag', 'PreservePrefixCB'), 'Enable', 'off');
        else
            set(findobj('Tag', 'SelectFieldsCB'), 'Enable', 'on');
            set(findobj('Tag', 'EditXMLCB'), 'Enable', 'on');
            set(findobj('Tag', 'PreservePrefixCB'), 'Enable', 'on');
        end
    end % useGUICallback

    function editXmlCallback(src, eventdata) %#ok<INUSD>
        editXml = get(src, 'Max') == get(src, 'Value');
    end % editXmlCallback

    function browseDirCallback(~, ~)
        % Callback for browse button sets a directory for control
        directory = uigetdir(pwd, 'Browse for input directory');
        if directory ~= 0
            set(findobj('Tag', 'Directory'), 'String', directory);
            inDir = directory;
        end
    end % browseDirCallback

    function saveCallback(src, ~)
        saveDatasets = get(src, 'Max') == get(src, 'Value');
        if ~saveDatasets
            set(findall(findobj('Tag', 'WriteButtonGroup'), ...
                '-property', 'Enable'), 'Enable', 'off')
        else
            set(findall(findobj('Tag', 'WriteButtonGroup'), ...
                '-property', 'Enable'), 'Enable', 'on')
        end
    end % saveAllCallback

    function dirCtrlCallback(src, ~)
        % Callback for user directly editing directory control textbox
        directoryName = get(src, 'String');
        if isdir(directoryName)
            inDir = directoryName;
        else  % if user entered invalid directory reset back
            set(src, 'String', inDir);
        end
    end % dirCtrlCallback

    function doSubDirsCallback(src, ~)
        doSubDirs = get(src, 'Max') == get(src, 'Value');
    end % useGUICallback

end % tagdir_input