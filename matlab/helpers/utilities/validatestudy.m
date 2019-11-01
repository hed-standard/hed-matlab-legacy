% This function takes in a directory containing EEG datasets and validates
% the tags the against the latest HED schema.
%
% Usage:
%
%   >>  validatestudy(study);
%
%   >>  validatestudy(study, 'key1', 'value1', ...);
%
% Input:
%
%   studyFile
%                   The full path to an EEG study file.
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
%   'outputFileDirectory'
%                   The directory where the log files are written to.
%                   There will be a log file generated for each study
%                   dataset validated. The default directory will be the
%                   current directory.
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

function issues = validatestudy(EEG, varargin)
p = parseArguments(varargin{:});
issues = validate(EEG, p);

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

    function issues = validate(EEG, p)
        % Validates all .set files in the input directory
        p.hedMaps = getHEDMaps(p);
%         [~, fPaths] = loadstudy(p.studyFile);

        validatingItems = [];
        % get HED string items to be validated from fMap
        fMap = getfMapFromSTUDY(EEG);
        fMapStruct = fMap.getStruct();
        eventCode_tagMaps_of_fields = fMapStruct.map;     
        for i=1:numel(eventCode_tagMaps_of_fields)
            field_eventCode_tagMaps = eventCode_tagMaps_of_fields(i);
            eventCodes_tagMaps = field_eventCode_tagMaps.values;
            for k=1:numel(eventCodes_tagMaps)
                eventCode_tagMap = eventCodes_tagMaps(k);
                if ~isempty(eventCode_tagMap.tags)
                    item.type = 'fieldValue';
                    item.typeName = field_eventCode_tagMaps.field;
                    item.value = eventCode_tagMap.code;
                    item.hedString = cellArray2String(eventCode_tagMap.tags);
                    validatingItems = [validatingItems item];
                end
            end
        end

        nonTaggedSets = {};
        nonTagedIndex = 1;
        % get HED string items to be validated from individual dataset's
        % event.hedtags field
        for a = 1:numel(EEG)
%             p.EEG = pop_loadset(fPaths{a});
%             p.fPath = fPaths{a};
            if isfield(EEG(a).event, 'usertags') || ...
                    isfield(EEG(a).event, 'hedtags') % check if the dataset is tagged or not
                if (isfield(EEG(a).event, 'hedtags'))
                    hedTags = {EEG(a).event.hedtags};
                    hasHedTags = cellfun(@(x) ~isempty(x), hedTags);
                    indices = find(hasHedTags);
                    for c=1:numel(indices)
                    	item.type = ['eventSpecific'];
                        if ~isempty(EEG(a).setname)
                            item.typeName = EEG(a).setname;
                        else
                            item.typeName = EEG(a).filename;
                        end
                        item.value =  num2str(indices(c));
                        item.hedString = hedTags{indices(c)};
                        validatingItems = [validatingItems item];
                    end
                end
%                 p.issues = parseeeg(p.hedXml, ...
%                     p.EEG.event, p.generateWarnings);
%                 writeOutputFiles(p);
            else
                if ~isempty(EEG(a).filename)
                    nonTaggedSets{nonTagedIndex} = EEG(a).filename; %#ok<AGROW>
                else
                    nonTaggedSets{nonTagedIndex} = EEG(a).setname; %#ok<AGROW>
                end
                nonTagedIndex = nonTagedIndex + 1;
            end
        end
        if ~isempty(validatingItems)
            if ~isempty(nonTaggedSets)
                printNonTaggedDatasets(nonTaggedSets);
            end
            issues = validateHedStrings(p.hedXml, validatingItems, p.generateWarnings);
%             writeOutputFiles(p);
        else
            warning('No tag found. Please tag datasets before validating.');
            return;
        end
    end % validate

    function printNonTaggedDatasets(nonTaggedSets)
        % Prints all datasets in directory that are not tagged
        numFiles = length(nonTaggedSets);
        datasets = nonTaggedSets{1};
        for a = 2:numFiles
            datasets = [datasets sprintf('\n%s' , nonTaggedSets{a})];             %#ok<AGROW>
        end
        warning('Please tag the following dataset(s):\n%s', datasets);
    end % printNonTaggedDatasets

    function [s, fNames] = loadstudy(studyFile)
        % Set baseTags if tagsFile contains an tagMap object
        try
            t = load('-mat', studyFile);
            tFields = fieldnames(t);
            s = t.(tFields{1});
            sPath = fileparts(studyFile);
            fNames = getstudyfiles(s, sPath);
        catch ME %#ok<NASGU>
            warning('tagstudy:loadStudyFile', 'Invalid study file');
            s = '';
            fNames = '';
        end
    end % loadstudy

    function fNames = getstudyfiles(study, sPath)
        % Set baseTags if tagsFile contains an tagMap object
        datasets = {study.datasetinfo.filename};
        paths = {study.datasetinfo.filepath};
        validPaths = true(size(paths));
        fNames = cell(size(paths));
        for ik = 1:length(paths)
            fName = fullfile(paths{ik}, datasets{ik}); % Absolute path
            if ~exist(fName, 'file')  % Relative to stored study path
                fName = fullfile(study.filepath, paths{ik}, datasets{ik});
            end
            if ~exist(fName, 'file') % Relative to actual study path
                fName = fullfile(sPath, paths{ik}, datasets{ik});
            end
            if ~exist(fName, 'file') % Give up
                warning('tagstudy:getStudyFiles', ...
                    ['Study file ' fname ' doesn''t exist']);
                validPaths(ik) = false;
            end
            fNames{ik} = fName;
        end
        fNames(~validPaths) = [];  % Get rid of invalid paths
    end % getstudyfiles

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
        p.addParamValue('outputFileDirectory', pwd, ...
            @(x) ischar(x));
        p.parse(varargin{:});
        p = p.Results;
    end % parseArguments

    function writeOutputFiles(p, EEG)
        % Writes the issues and replace tags found to a log file and a
        % replace file
        p.dir = p.outputFileDirectory;
        if ~isempty(EEG.filename)
            [~, p.file] = fileparts(EEG.filename);
        else
            [~, p.file] = fileparts(EEG.setname);
        end
        p.ext = '.txt';
        try
            if ~isempty(p.issues)
                createLogFile(p, false);
            else
                createLogFile(p, true);
            end
        catch
            throw(MException('validatestudy:cannotWrite', ...
                'Could not write log file'));
        end
    end % writeOutputFiles

    function createLogFile(p, empty)
        % Creates a log file containing any issues found through the
        % validation
        numErrors = length(p.issues);
        errorFile = fullfile(p.dir, ['validated_' p.file p.ext]);
        fileId = fopen(errorFile,'w');
        if ~empty
            fprintf(fileId, '%s', p.issues{1});
            for a = 2:numErrors
                fprintf(fileId, '\n%s', p.issues{a});
            end
        else
            fprintf(fileId, 'No issues were found.');
        end
        fclose(fileId);
    end % createLogFile
    
    function hedString = cellArray2String(cellArr)
        hedString = '';
        for i=1:numel(cellArr)
            hedString = [hedString cellArr{i}];
            if i < numel(cellArr)
                hedString = [hedString ', '];
            end
        end
    end
    

end % validatestudy