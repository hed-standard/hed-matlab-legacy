% GUI for input needed to create inputs for pop_validateeeg.
%
% Usage:
%
%   >>  [canceled, generateWarnings, hedXML, outDir] = pop_validateeeg_input()
%
%   >>  [canceled, generateWarnings, hedXML, outDir] = ...
%       pop_validateeeg_input('key1', 'value1', ...)
%
% Input:
%
%   Optional:
%
%   'GenerateWarnings'
%                   True to include warnings in the log file in addition
%                   to errors. If false (default) only errors are included
%                   in the log file.
%
%   'HedXml'
%                   The full path to a HED XML file containing all of the
%                   tags. This by default will be the HED.xml file
%                   found in the hed directory.
%
%   'OutputFileDirectory'
%                   The directory where the validation output is written
%                   to. There will be a log file generated for each study
%                   dataset validated.
%
% Output:
%
%   canceled
%                   True if the GUI is canceled. False if otherwise.
%
%   generateWarnings
%                   True to include warnings in the log file in addition
%                   to errors. If false (default) only errors are included
%                   in the log file.
%
%   hedXML
%                   A XML file containing every single HED tag and its
%                   attributes. This by default will be the HED.xml file
%                   found in the hed directory.
%
%   outDir
%                   The directory where the validation output will be
%                   written to if the 'writeOutput' argument is set to
%                   true. There will be log file containing any issues that
%                   were found while validating the HED tags. If there were
%                   issues found then a replace file will be created in
%                   addition to the log file if an optional one isn't
%                   already provided. The default output directory will be
%                   the current directory.
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

function [canceled, generateWarnings, hedXml, outDir] = ...
    pop_validateeeg_input(varargin)
% Setup the variables used by the GUI
p = parseArguments(varargin{:});
canceled = true;
generateWarnings = p.GenerateWarnings;
hedXml = p.HedXml;
outDir = p.OutputFileDirectory;

%% Defining GUI elements
geometry = {[0.3 1 0.2] ...
            [0.3 1 0.2] ...
            [0.3 1]};
uilist = {...
    {'Style', 'text', 'string', 'HED schema'} ...
    {'Style', 'edit', 'string', hedXml, 'tag', 'HEDpath', 'TooltipString', 'The HED XML file', 'Callback', {@hedEditBoxCallback}} ...
    {'Style', 'pushbutton', 'string', '...', 'callback', @browseHEDFileCallBack} ...
    {'Style', 'text', 'string', 'Output directory'} ...
    {'Style', 'edit', 'string', outDir, 'tag', 'OutputDirPath', 'TooltipString', 'Directory where the validation output will be stored', 'Callback', {@outputDirEditBoxCallback}} ...
    {'Style', 'pushbutton', 'string', '...', 'callback', {@browseOutputDirectoryCallback,'Browse for ouput directory'}} ...
    {'Style', 'text', 'string', ''},...        
    {'Style', 'checkbox', 'value', generateWarnings,...
        'string', 'Include warnings in log file',...
        'TooltipString', ['Check to include warnings in the log file in' ...
            ' addition to errors. If unchecked only errors are' ...
            ' included in the log file'], 'tag', 'GenerateWarnings' } ...        
    };
 
%% Waiting for user input
[tmp1, tmp2, strhalt, structout] = inputgui( geometry, uilist, ...
           'pophelp(''pop_validatestudy'');', 'Validate single EEG set -- pop_validateeeg()');
       
%% Set values accordingly 
if ~isempty(structout)  % if not canceled
    hedXml = structout.HEDpath;
    outDir = structout.OutputDirPath;
    generateWarnings = logical(structout.GenerateWarnings);
    canceled = false;
end

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
        if file ~= 0 
            [~, ~, ext] = fileparts(file);
            if strcmp(lower(ext), ".xml")
                HEDFile = fullfile(path, file);
                set(findobj('Tag', 'HEDpath'), 'String', HEDFile);
            end
        end
    end % browseHEDFileCallBack
    
    function outputDirEditBoxCallback(src, ~)
        % Callback for user directly editing the 'Output directory' editbox
        directory = get(src, 'String');
        if isempty(directory) || ~ischar(directory) || ~isdir(directory)
            errordlg('Directory path is invalid. Setting the output directory to current directory.', ...
                'Invalid directory path', 'modal');
            directory = pwd;
        end
        outDir = directory;
        set(src, 'String', outDir);
    end % outputDirEditBoxCallback
    function browseOutputDirectoryCallback(~, ~, myTitle)
        % Callback for browse button to set the output directory editbox
        startPath = get(findobj('Tag', 'OutputDirPath'), 'String');
        if isempty(startPath) || ~ischar(startPath) || ~isdir(startPath)
            startPath = pwd;
        end
        dName = uigetdir(startPath, myTitle);
        if dName ~=0
            set(findobj('Tag', 'OutputDirPath'), 'String', dName);
            outDir = dName;
        end
    end % browseOutputDirectoryCallback

    function p = parseArguments(varargin)
        % Parses the input arguments and returns the results
        parser = inputParser;
        parser.addParamValue('GenerateWarnings', false, ...
            @(x) validateattributes(x, {'logical'}, {}));
        parser.addParamValue('HedXml', which('hed.xml'), ...
            @(x) (~isempty(x) && ischar(x)));
        parser.addParamValue('OutputFileDirectory', pwd, @ischar);
        parser.parse(varargin{:});
        p = parser.Results;
    end % parseArguments
end % pop_validateeeg_input