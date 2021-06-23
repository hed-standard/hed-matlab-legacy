% GUI for input needed to create inputs for tagdir function.
%
% Usage:
%
%   >>  [baseMap, canceled, doSubDirs,inDir, preservePrefix, ...
%       selectFields, useGUI] = pop_tagdir_input()
%
% Output:
%
%   baseMap          A fieldMap object or the name of a file that contains
%                    a fieldMap object to be used to initialize tag
%                    information.
%
%   canceled
%                    True if the cancel button is pressed. False if
%                    otherwise.
%
%   extensionsAllowed
%                    If true (default), the HED can be extended. If
%                    false, the HED can not be extended. The 
%                    'ExtensionAnywhere argument determines where the HED
%                    can be extended if extension are allowed.
%                  
%
%   extensionsAnywhere
%                    If true, the HED can be extended underneath all tags.
%                    If false (default), the HED can only be extended where
%                    allowed. These are tags with the 'extensionAllowed'
%                    attribute or leaf tags (tags that do not have
%                    children).
%
%   hedXML         
%                    Full path to a HED XML file. The default is the 
%                    HED.xml file in the hed directory. 
%
%   doSubDirs        If true (default) the entire inDir directory tree is
%                    searched. If false only the inDir directory is
%                    searched.
%
%   inDir
%                    The input directory containing .set files.
%
%   preservePrefix
%                    If false (default), tags for the same field value that
%                    share prefixes are combined and only the most specific
%                    is retained (e.g., /a/b/c and /a/b become just
%                    /a/b/c). If true, then all unique tags are retained.
%
%   selectFields
%                    If true (default), the user is presented with a
%                    GUI that allow users to select which fields to tag.
%
%   useGUI
%                    If true (default), the CTAGGER GUI is displayed after
%                    initialization.
%
% Copyright (C) 2012-2016 Thomas Rognon tcrognon@gmail.com,
% Jeremy Cockfield jeremy.cockfield@gmail.com, and
% Kay Robbins kay.robbins@utsa.edu
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

function [canceled, baseMap, doSubDirs, hedExtensionsAllowed, ...
    hedXml, inDir, preserveTagPrefixes, ...
    selectEventFields, useCTagger] = pop_tagdir_input(varargin)
p = parseArguments(varargin{:});
baseMap = p.BaseMap;
canceled = true;
doSubDirs = p.DoSubDirs;
hedExtensionsAllowed = p.HedExtensionsAllowed;
hedXml = p.HedXml;
inDir = p.InDir;
preserveTagPrefixes = p.PreserveTagPrefixes;
selectEventFields = p.SelectEventFields;
useCTagger = p.UseCTagger;

%% Defining GUI elements
geometry = {[0.3 1 0.2] ...
            [0.3 1 0.2] ...
            [0.3 1 0.2] ...
            [0.3 1] ...
            [0.3 1] ...
            [0.3 1] ...
            [0.3 1]};
uilist = {...
    {'Style', 'text', 'string', 'HED Schema'} ...
    {'Style', 'edit', 'string', hedXml, 'tag', 'HEDpath', 'TooltipString', 'The HED XML file', 'Callback', {@hedEditBoxCallback}} ...
    {'Style', 'pushbutton', 'string', '...', 'callback', @browseHEDFileCallBack} ...
    {'Style', 'text', 'string', 'Directory'} ...
    {'Style', 'edit', 'string', inDir, 'tag', 'DirectoryPath', 'TooltipString', 'Directory of .set files', 'Callback', {@directoryEditboxCallback}} ...
    {'Style', 'pushbutton', 'string', '...', 'callback', @browseDirectoryCallBack} ...
    {'Style', 'text', 'string', 'Import tagfile'} ...
    {'Style', 'edit', 'string', baseMap, 'tag', 'fMapPath', 'TooltipString', 'FieldMap file (.mat) containing events and their associated HED tags', 'Callback', {@baseMapEditboxCallback}} ...
    {'Style', 'pushbutton', 'string', '...', 'callback', @browseBaseMapCallBack} ...
    {'Style', 'text', 'string', ''},...
    {'Style', 'checkbox', 'value', 1,...
        'string', 'Look in subdirectories',...
        'TooltipString', 'If checked, traverse all subdirectories to process .set dataset files', 'tag', 'DoSubDirs' } ...
    {'Style', 'text', 'string', ''},...        
    {'Style', 'checkbox', 'value', 1,...
        'string', 'Use CTagger to add/modify tags/schema',...
        'TooltipString', 'If checked, use CTagger for each selected field', 'tag', 'UseCTAGGER', 'Callback', @useCTaggerCallback } ...
    {'Style', 'text', 'string', ''},...        
    {'Style', 'checkbox', 'value', 1,...
        'string', 'Select EEG.event fields to use for tagging',...
        'TooltipString', 'If checked, use menu to select fields to tag', 'tag', 'SelectField' } ...
    {'Style', 'text', 'string', ''},...        
    {'Style', 'checkbox', 'value', 0,...
        'string', 'Allow new HED tags (if compatible with the HED schema)',...
        'TooltipString', 'If checked, allow extension of HED schema where compatible with the schema definition', 'tag', 'ExtensionAllowed' } ...        
    };

%% Waiting for user input
[tmp1, tmp2, strhalt, structout] = inputgui( geometry, uilist, ...
           'pophelp(''pop_tagdir'');', 'Tag directory -- pop_tagdir()');
    
%% Set values accordingly 
if ~isempty(structout) % if not canceled
    if isempty(structout.DirectoryPath)
        warndlg('No directory path was provided. Tagging was canceled', 'Empty path','modal');
        canceled = true;
        return;
    end
    hedXml = structout.HEDpath;
    inDir = structout.DirectoryPath;
    baseMap = structout.fMapPath;
    doSubDirs = logical(structout.DoSubDirs);
    useCTagger = logical(structout.UseCTAGGER);
    if useCTagger 
        selectEventFields = logical(structout.SelectField);
    else
        selectEventFields = false ;
    end
    hedExtensionsAllowed = logical(structout.ExtensionAllowed);
    canceled = false;
end
    %% Callback functions  
    function hedEditBoxCallback(src, ~) 
        % Callback for user directly editing the HED XML editbox
        xml = get(src, 'String');
        [~, ~, ext] = fileparts(xml);
        if exist(xml, 'file') && strcmp(lower(ext), ".xml")
            hedXml = xml;
        else 
            errordlg(['XML file is invalid. Setting the XML' ...
                ' file back to the previous file.'], ...
                'Invalid file', 'modal');
        end
        set(src, 'String', hedXml);
    end % hedEditBoxCallback
    function browseHEDFileCallBack(~, ~)
        % Callback for field map 'Browse' button
        [file,path] = uigetfile2({'*.xml';'*.XML'}, 'Load HED Schema', 'multiselect', 'off');
        [~, ~, ext] = fileparts(file);
        if strcmp(lower(ext), ".xml")
            HEDFile = fullfile(path, file);
            set(findobj('Tag', 'HEDpath'), 'String', HEDFile);
        end
    end % browseHEDFileCallBack
    function browseDirectoryCallBack(~, ~)
        % Callback for field map 'Browse' button
        path = uigetdir(pwd, 'Load directory containing .set files');
        if path ~= 0
            set(findobj('Tag', 'DirectoryPath'), 'String', path);
        end
    end % browseDirectoryCallBack
    function directoryEditboxCallback(src, ~)
        % Callback for user directly editing the 'Directory' editbox
        directoryName = get(src, 'String');
        if ~isempty(directoryName) && ~isdir(directoryName)
            errordlg(['Invalid path. Resetting'], ...
                'Invalid Path', 'modal');
            set(src, 'String', inDir);
        end
    end % directoryEditboxCallback

    function baseMapEditboxCallback(src, ~)
        % Callback for user directly editing the 'Base tags' editbox
        tagsFile = get(src, 'String');
        if ~isempty(strtrim(tagsFile)) && ~isValidBaseTags(tagsFile)
            errordlg(['Invalid tag file. Resetting'], ...
                'Invalid file', 'modal');
            set(src, 'String', baseMap);
        end
    end % baseTagsEditboxCallback


    function browseBaseMapCallBack(~, ~)
        [file, path] = uigetfile({'*.mat';'*.MAT'}, 'Browse for FieldMap file (*.mat)');
        tagsFile = fullfile(path, file);
        if ischar(tagsFile) && ~isempty(tagsFile) && isValidBaseTags(tagsFile)
            set(findobj('Tag', 'fMapPath'), 'String', tagsFile);
        end
    end % browsefMapCallBack

    function valid = isValidBaseTags(tagsFile)
        % Checks to see if the 'Base tags' passed in is valid
        valid = true;
        if isempty(fieldMap.loadFieldMap(tagsFile))
            valid = false;
        end
    end % isValidBaseTags

    function useCTaggerCallback(src, ~)
        if get(src, 'value') == 0
            set(findobj('Tag', 'SelectField'), 'Enable', 'off');
        else
            set(findobj('Tag', 'SelectFieldsCB'), 'Enable', 'on');
        end
    end % useCTaggerCallback

    function p = parseArguments(varargin)
        % Parses the input arguments and returns the results
        parser = inputParser;
        parser.addParamValue('BaseMap', '', @ischar);
        parser.addParamValue('DoSubDirs', true, @islogical);
        parser.addParamValue('HedExtensionsAllowed', true, @islogical);
        parser.addParamValue('HedXml', which('HED.xml'), @ischar);
        parser.addParamValue('InDir', '', @(x) (~isempty(x) && ischar(x)));
        parser.addParamValue('PreserveTagPrefixes', false, @islogical);
        parser.addParamValue('SelectEventFields', true, @islogical);
        parser.addParamValue('UseCTagger', true, @islogical);
        parser.parse(varargin{:});
        p = parser.Results;
    end % parseArguments

end % pop_tagdir_input