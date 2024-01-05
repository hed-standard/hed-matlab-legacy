% GUI for input needed to create inputs for pop_tageeg
%
% Usage:
%
%   >>  [baseMap, canceled, editXML, preservePrefix, selectFields, ...
%       useGUI] = pop_tageeg_input()
%
%   >>  [baseMap, canceled, editXML, preservePrefix, selectFields, ...
%       useGUI] = pop_tageeg_input('key1', 'value1', ...)
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
%   hedExtensionsAllowed
%                    If true (default), the HED can be extended. If
%                    false, the HED can not be extended. The 
%                    'ExtensionAnywhere argument determines where the HED
%                    can be extended if extension are allowed.
%
%   hedXml         
%                    Full path to a HED XML file. The default is the 
%                    HED.xml file in the hed directory. 
%
%   preserveTagPrefixes
%                    If false (default), tags for the same field value that
%                    share prefixes are combined and only the most specific
%                    is retained (e.g., /a/b/c and /a/b become just
%                    /a/b/c). If true, then all unique tags are retained.
%
%   useCTagger
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

function [canceled, baseMap, hedExtensionsAllowed,...
    hedXml, preserveTagPrefixes, useCTagger] = pop_tageeg_input(varargin)
p = parseArguments(varargin{:});
baseMap = p.BaseMap;
canceled = true;
hedExtensionsAllowed = p.HedExtensionsAllowed;
hedXml = p.HedXml;
preserveTagPrefixes = p.PreserveTagPrefixes;
useCTagger = p.UseCTagger;

%% Defining GUI elements
geometry = {[0.3 1 0.2] ...
            [0.3 1 0.2] ...
            [0.3 1]};
uilist = {...
    {'Style', 'text', 'string', 'HED Schema'} ...
    {'Style', 'edit', 'string', hedXml, 'tag', 'HEDpath', 'TooltipString', 'The HED XML file', 'Callback', {@hedEditBoxCallback}} ...
    {'Style', 'pushbutton', 'string', '...', 'callback', @browseHEDFileCallBack} ...
    {'Style', 'text', 'string', 'Import tags from file'} ...
    {'Style', 'edit', 'string', baseMap, 'tag', 'fMapPath', 'TooltipString', '.mat file containing events and their associated HED tags', 'Callback', {@baseMapEditboxCallback}} ...
    {'Style', 'pushbutton', 'string', '...', 'callback', @browseBaseMapCallBack} ...
    {'Style', 'text', 'string', ''},...        
    {'Style', 'checkbox', 'value', 1,...
        'string', 'Use CTagger to add/modify tags/schema',...
        'TooltipString', 'If checked, use CTagger for each selected field', 'tag', 'UseCTAGGER'}};
%% Waiting for user input
[~, ~, ~, structout] = inputgui( geometry, uilist, ...
           'pophelp(''pop_tageeg'');', 'Tag current dataset - pop_tageeg()');
       
%% Set values accordingly 
if ~isempty(structout)  % if not canceled
    hedXml = structout.HEDpath;
    baseMap = structout.fMapPath;
    useCTagger = logical(structout.UseCTAGGER);
    hedExtensionsAllowed = true;
    canceled = false;
end


    function baseMapEditboxCallback(src, ~)
        importedTags = get(src, 'String');
        if exist(importedTags, 'file')
            baseMap = importedTags;
        else
            errordlg(['Import file is invalid. Setting the import' ...
                ' file back to the previous file.'], ...
                'Invalid import file', 'modal');
        end
        set(src, 'String', baseMap);
    end

    function browseBaseMapCallBack(~, ~)
        % Callback for 'Browse' button that sets the 'Base tags' editbox
        [file, path] = uigetfile({'*.mat', 'MATLAB Files (*.mat)'}, ...
            'Browse for event tags');
        if file ~= 0
            tagsFile = fullfile(path, file);
            if ischar(file) && ~isempty(file) && validateBaseTags(tagsFile)
                baseMap = tagsFile;
                set(findobj('Tag', 'fMapPath'), 'String', baseMap);
            end
        end
    end % browseBaseTagsCallback

    function browseHEDFileCallBack(~, ~)
        % Callback for 'Browse' button that sets the 'HED' editbox
        [tFile, tPath] = uigetfile({'*.xml', 'XML files (*.xml)'}, ...
            'Browse HED schema file');
        if tFile ~= 0
            hedXml = fullfile(tPath, tFile);
            set(findobj('Tag', 'HEDpath'), 'String', hedXml);
        end
    end % browseHedXMLCallback

    function hedEditBoxCallback(src, ~) 
        % Callback for user directly editing the HED XML editbox
        xml = get(src, 'String');
        if exist(xml, 'file')
            hedXml = xml;
        else 
            errordlg(['XML file is invalid. Setting the XML' ...
                ' file back to the previous file.'], ...
                'Invalid XML file', 'modal');
        end
        set(src, 'String', hedXml);
    end % hedEditBoxCallback


    function p = parseArguments(varargin)
        % Parses the input arguments and returns the results
        parser = inputParser;
        parser.addParamValue('BaseMap', '', @ischar);
        parser.addParamValue('HedExtensionsAllowed', false, @islogical);
        parser.addParamValue('HedXml', which('HED.xml'), @ischar);
        parser.addParamValue('PreserveTagPrefixes', false, @islogical);
        parser.addParamValue('UseCTagger', true, @islogical);
        parser.parse(varargin{:});
        p = parser.Results;
    end % parseArguments

    function valid = validateBaseTags(tagsFile)
        % Checks to see if the 'Base tags' passed in is valid
        valid = true;
        if isempty(fieldMap.loadFieldMap(tagsFile))
            valid = false;
            warndlg([ tagsFile ...
                ' is a invalid base tag file'], 'Invalid file');
            set(findobj('Tag', 'BaseTags'), 'String', baseMap);
        end
    end % validateBaseTags

end % pop_tageeg_input