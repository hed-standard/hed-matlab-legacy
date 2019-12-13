% Allows a user to validate the HED tags in an EEGLAB study and its
% associated .set files using a GUI.
%
% Usage:
%
%   >>  [fPaths, com] = pop_validatestudy()
%
%   >>  [fPaths, com] = pop_validatestudy(studyFile)
%
%   >>  [fPaths, com] = pop_validatestudy(studyFile, 'key1', value1 ...)
%
% Input:
%
%   Required:
%

%   Optional (key/value):
%   'UseGui'
%                    If true (default), use a series of menus to set
%                    function arguments.
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
%   'WriteToOutputFile'
%                   If true write an issue report for each of the EEG set
%                   of the STUDY to 'outputFileDirectory'. If 'outputFileDirectory' is not
%                   specified, issue report will be written to current
%                   directory
%
%   'OutputFileDirectory'
%                   The directory where the log files are written to.
%                   There will be a log file generated for each study
%                   dataset validated. The default directory will be the
%                   current directory.
%
% Output:
%
%   issues         issues found in STUDY
%
%   com
%                  String containing call to tagstudy with all parameters
%
% Copyright (C) 2015 Jeremy Cockfield jeremy.cockfield@gmail.com and
% Kay Robbins, UTSA, kay.robbins@utsa.edu
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
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA

function [issues, com] = pop_validatestudy(STUDY, ALLEEG, varargin)
com = '';
issues = '';

if nargin < 2
    help pop_validatestudy;
    return;
end
if isempty(ALLEEG) || ~isstruct(ALLEEG)
    warning('ALLEEG struct array is not specified... exiting function');
    return;
end

p = parseArguments(varargin{:});

% Get input from user if calling function with menu
if p.UseGui
    menuInputArgs = getkeyvalue({'GenerateWarnings', 'HedXml', 'OutputFileDirectory'}, varargin{:});
    [canceled, generateWarnings, hedXML, outDir] = ...
        pop_validatestudy_input(menuInputArgs{:});
    p.OutputFileDirectory = outDir;
    p.HedXml = hedXML;
    p.GenerateWarnings = generateWarnings;
    if canceled
        return;
    end
end

inputArgs = {'GenerateWarnings', p.GenerateWarnings, 'HedXml', p.HedXml};
issues = validatestudy(STUDY, ALLEEG, inputArgs{:});

if p.WriteToOutputFile
    p.issues = issues;
    writeOutputFiles(ALLEEG, p);
end

    function writeOutputFiles(ALLEEG, p)
        % Writes the issues and replace tags found to a log file and a
        % replace file
        p.dir = p.OutputFileDirectory;
        for i=1:length(ALLEEG)
            EEG = ALLEEG(i);
            issue = p.issues{i};
            if ~isempty(EEG.filename)
                [~, p.file] = fileparts(EEG.filename);
            else
                [~, p.file] = fileparts(EEG.setname);
            end
            p.ext = '.txt';
            try
                if ~isempty(issue)
                    createLogFile(p.dir, issue, p.file, p.ext, false);
                else
                    createLogFile(p.dir, issue, p.file, p.ext, true);
                end
            catch
                throw(MException('validatestudy:cannotWrite', ...
                    'Could not write log file'));
            end
        end 
    end % writeOutputFiles

    function createLogFile(dir, issue, file, ext, empty)
        % Creates a log file containing any issues found through the
        % validation
        numErrors = length(issue);
        errorFile = fullfile(dir, ['validated_' file ext]);
        fileId = fopen(errorFile,'w');
        if ~empty
            fprintf(fileId, '%s', issue{1});
            for a = 2:numErrors
                fprintf(fileId, '\n%s', issue{a});
            end
        else
            fprintf(fileId, 'No issues were found.');
        end
        fclose(fileId);
    end % createLogFile
    
com = char(['pop_validatestudy(STUDY, ALLEEG,' logical2str(p.UseGui) ', ' ...
    keyvalue2str(varargin{:}) ');']);


    function p = parseArguments(varargin)
        % Parses the arguements passed in and returns the results
        p = inputParser();
        p.addOptional('UseGui', true, @islogical);
        p.addParamValue('GenerateWarnings', false, ...
            @(x) validateattributes(x, {'logical'}, {}));
        p.addParamValue('HedXml', which('HED.xml'), ...
            @(x) (~isempty(x) && ischar(x)));
        p.addParamValue('WriteToOutputFile', true, @islogical);
        p.addParamValue('OutputFileDirectory', pwd, ...
            @(x) ischar(x));
        p.parse(varargin{:});
        p = p.Results;
    end % parseArguments

end % pop_validatestudy