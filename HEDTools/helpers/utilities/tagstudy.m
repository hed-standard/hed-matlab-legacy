% Allows a user to create a fieldMap from a study file and its associated
% EEG .set files. The events and tags from all data files are extracted and
% consolidated into a single fieldMap object by merging all of the existing
% tags. If an initial fMap is provided (baseMap), merge the baseMap with
% the newly extracted fMap
%
% Usage:
%
%   >>  [fMap, fPaths] = tagstudy(ALLEEG)
%
%   >>  [fMap, fPaths] = tagstudy(ALLEEG, 'key1', 'value1', ...)
%
% Input:
%
%   Required:
%
%   ALLEEG
%                    Structure array containing all EEG datasets of a STUDY.
%
%   Optional (key/value):
%
%   'BaseMap'
%                    A fieldMap object or the name of a file that contains
%                    a fieldMap object to be used to initialize tag
%                    information.
%
%   'BaseMapFieldsToIgnore'
%                    A one-dimensional cell array of field names in the
%                    .event substructure to ignore when merging with a
%                    fieldMap object 'BaseMap'.
%
%   'HedXml'
%                    Full path to a HED XML file. The default is the
%                    HED.xml file in the hed directory.
%
%   'EventFieldsToIgnore'
%                    A one-dimensional cell array of field names in the
%                    .event substructure to ignore during the tagging
%                    process. By default the following subfields of the
%                    .event structure are ignored: .latency, .epoch,
%                    .urevent, .hedtags, and .usertags. The user can
%                    over-ride these tags using this name-value parameter.
%
%   'PreserveTagPrefixes'
%                    If false (default), tags for the same field value that
%                    share prefixes are combined and only the most specific
%                    is retained (e.g., /a/b/c and /a/b become just
%                    /a/b/c). If true, then all unique tags are retained.
%
% Output:
%
%   fMap
%                    A fieldMap object that contains the tag map
%                    information
%
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
 
function [fMap, canceled] = tagstudy(STUDY, ALLEEG, varargin)

p = parseArguments(varargin{:});

canceled = 0;
[fMap, canceled] = findStudyTags(STUDY, ALLEEG, p);
if ~canceled && ~isempty(p.BaseMap)
    fMap = mergeBaseTags(fMap, p);
end
 
    function fMap = mergeBaseTags(fMap, p)
        % Merge baseMap and fMap tags
        if isa(p.BaseMap, 'fieldMap')
            baseTags = p.BaseMap;
        else
            baseTags = fieldMap.loadFieldMap(p.BaseMap);
        end
        fMap.merge(baseTags, 'Update', union(p.BaseMapFieldsToIgnore, ...
            p.EventFieldsToIgnore), {});
    end % mergeBaseTags
 
    function [fMap, canceled, studyFields] = findStudyTags(STUDY, ALLEEG, p)
        if hasSummaryTags(STUDY)
            fMap = etc2fMap(STUDY, p);
        else
            fMap = fieldMap('PreserveTagPrefixes',  p.PreserveTagPrefixes);
            % Find the existing tags from the study datasets
            studyFields = {};
            categoricalFields = {};
            for k = 1:length(ALLEEG) % Assemble the list
                studyFields = union(studyFields, fieldnames(ALLEEG(k).event));
                [fMapTemp, canceled, categoricalFields] = findtags(ALLEEG(k), 'PreserveTagPrefixes', ...
                    p.PreserveTagPrefixes, 'EventFieldsToIgnore', ...
                    p.EventFieldsToIgnore, 'HedXml', p.HedXml, 'CategoricalFields', categoricalFields);
                if ~canceled
                    fMap.merge(fMapTemp, 'Merge', p.EventFieldsToIgnore, {});
                else
                    return
                end
            end
        end
    end % findStudyTags
    
    function fMap = etc2fMap(STUDY, p)
        % Adds field values to the field maps from the .etc field
        fMap = fieldMap('PreserveTagPrefixes',  p.PreserveTagPrefixes);
        etcFields = getEtcFields(STUDY, p);
        for k = 1:length(etcFields)
            fMap.addValues(etcFields{k}, STUDY.etc.tags.map(k).values);
        end
    end % etc2fMap
    
    function summaryFound = hasSummaryTags(STUDY)
        % Returns true if there are summary tags found in the .etc field
        summaryFound = isfield(STUDY, 'etc') && ...
            isstruct(STUDY.etc) && ...
            isfield(STUDY.etc, 'tags') && ...
            isstruct(STUDY.etc.tags) && ...
            isfield(STUDY.etc.tags, 'map') && ...
            isstruct(STUDY.etc.tags.map) && ...
            isfield(STUDY.etc.tags.map, 'field');
    end % hasSummaryTags
    
    function etcFields = getEtcFields(STUDY, p)
        % Gets all of the event fields from the .etc field
        etcFields = {STUDY.etc.tags.map.field};
        etcFields = setdiff(etcFields, p.EventFieldsToIgnore);
    end % getEtcFields

    function p = parseArguments(varargin)
        % Parses the input arguments and returns the results
        parser = inputParser;
        parser.addParamValue('BaseMap', '', @(x) isa(x, 'fieldMap') || ...
            ischar(x));
        parser.addParamValue('BaseMapFieldsToIgnore', {}, @iscellstr);
        parser.addParamValue('HedXml', which('HED.xml'), @ischar);
        parser.addParamValue('EventFieldsToIgnore', ...
            {'latency', 'epoch', 'urevent', 'hedtags', 'usertags'}, ...
            @iscellstr);
        parser.addParamValue('PreserveTagPrefixes', false, @islogical);
        parser.parse(varargin{:});
        p = parser.Results;
    end % parseArguments
 
end % tagstudy
