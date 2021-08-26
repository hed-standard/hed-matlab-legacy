function [fMap, canceled] = findStudyTags(STUDY, ALLEEG, varargin)
p = parseArguments(varargin{:});
canceled = 0;

if hasSummaryTags(STUDY)
    fMap = etc2fMap(STUDY, p);
else
    fMap = fieldMap('PreserveTagPrefixes',  p.PreserveTagPrefixes);
    % Find the existing tags from the study datasets
%             studyFields = {};
    categoricalFields = {};
    for k = 1:length(ALLEEG) % Assemble the list
%                 studyFields = union(studyFields, fieldnames(ALLEEG(k).event));
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
    
    function fMap = etc2fMap(STUDY, p)
        % Adds field values to the field maps from the .etc field
        fMap = fieldMap('PreserveTagPrefixes',  p.PreserveTagPrefixes);
        etcFields = getEtcFields(STUDY, p);
        for i = 1:length(etcFields)
            fMap.addValues(etcFields{i}, STUDY.etc.tags.map(i).values);
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
            {'latency', 'epoch', 'urevent', 'HED'}, ...
            @iscellstr);
        parser.addParamValue('PreserveTagPrefixes', false, @islogical);
        parser.parse(varargin{:});
        p = parser.Results;
    end % parseArguments
end % findStudyTags