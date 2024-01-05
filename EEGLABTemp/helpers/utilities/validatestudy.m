% This function takes in a STUDY and the ALLEEG structure array containing
% all ALLEEG datasets of the STUDY and validates the tags the against the latest HED schema.
%
% Usage:
%
%   >>  validatestudy(STUDY, ALLEEG);
%
%   >>  validatestudy(STUDY, ALLEEG, 'key1', 'value1', ...);
%
% Input:
%
%   STUDY
%                   EEGLAB STUDY structure
%
%   ALLEEG
%                   structure array containing all ALLEEG sets of the STUDY
%
%
%   Optional:
%
%   'generateWarnings'
%                   True to include warnings in the log file in addition
%                   to errors. If false (default) only errors are included
%                   in the log file.
%
%   'hedXml'
%                   The full path to a HED XML file containing all of the
%                   tags. This by default will be the HED.xml file
%                   found in the hed directory.
%
%
% Copyright (C) 2012-2019 Thomas Rognon tcrognon@gmail.com,
% Jeremy Cockfield jeremy.cockfield@gmail.com, Dung Truong dutruong@ucsd.edu and
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

function issues = validatestudy(STUDY, ALLEEG, varargin)
p = parseArguments(varargin{:});
issues = validate(ALLEEG, p);

    function issues = validate(ALLEEG, p)
        issues = [];
        % Validates all .set files in the array structure ALLEEG
%         p.hedMaps = getHEDMaps(p);
        nonTaggedSets = {};
        nonTagedIndex = 1;
        for a = 1:length(ALLEEG)
            EEG = ALLEEG(a);
            if isfield(EEG.event, 'usertags') || ...
                    isfield(EEG.event, 'hedtags')
                issues = [issues {parseeeg(p.hedXml, ...
                    EEG.event, p.generateWarnings)}];
            else
                issues = [issues {"No HED tags found for this file"}];
                if ~isempty(EEG.filename)
                    nonTaggedSets{nonTagedIndex} = EEG.filename; %#ok<AGROW>
                else
                    nonTaggedSets{nonTagedIndex} = EEG.setname; %#ok<AGROW>
                end
                nonTagedIndex = nonTagedIndex + 1;
            end
        end
        if ~isempty(nonTaggedSets)
            printNonTaggedDatasets(nonTaggedSets);
        end
    end % validate

    function hedMaps = getHEDMaps(p)
        % Gets a structure that contains Maps associated with the HED XML
        % tags
        hedMaps = loadHEDMaps();
        mapVersion = hedMaps.version;
        xmlVersion = getxmlversion(p.hedXml);
        if ~isempty(xmlVersion) && ~strcmp(mapVersion, xmlVersion)
            hedMaps = mapattributes(p.hedXml);
        end
    end % getHEDMaps

    function printNonTaggedDatasets(nonTaggedSets)
        % Prints all datasets in directory that are not tagged
        numFiles = length(nonTaggedSets);
        datasets = nonTaggedSets{1};
        for a = 2:numFiles
            datasets = [datasets sprintf('\n%s' , nonTaggedSets{a})];             %#ok<AGROW>
        end
        warning('Please tag the following dataset(s):\n%s', datasets);
    end % printNonTaggedDatasets

    function hedMaps = loadHEDMaps()
        % Loads a structure that contains Maps associated with the HED XML
        % tags
        Maps = load('hedMaps.mat');
        hedMaps = Maps.hedMaps;
    end % loadHEDMap

    function p = parseArguments(varargin)
        % Parses the arguements passed in and returns the results
        p = inputParser();
%         p.addRequired('studyFile', @(x) (~isempty(x) && ischar(x)));
        p.addParamValue('generateWarnings', false, ...
            @(x) validateattributes(x, {'logical'}, {}));
        p.addParamValue('hedXml', 'HED.xml', ...
            @(x) (~isempty(x) && ischar(x)));
        p.parse(varargin{:});
        p = p.Results;
    end % parseArguments


end % validatestudy