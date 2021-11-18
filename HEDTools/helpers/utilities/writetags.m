% Writes tags to a structure from the fieldMap information. The tags in the
% dataset structure are written to the .etc field and in each individual
% event in the .event field.
%
% Usage:
%
%   >>  eData = writetags(eData, fMap)
%
%   >>  eData = writetags(eData, fMap, 'key1', 'value1', ...)
%
% Input:
%
%   Required:
%
%   eData
%                    A dataset structure that the tag information is to be
%                    written to.
%
%   fMap
%                    A fieldMap object with the tag information.
%
%   Optional (key/value):
%
%   'WriteIndividualTags'
%                    Whether to write assembled HED string for each event
%                    to EEG.event. Default is false; only write summary
%                    tags. Assembling should only be done on demand at analysis
% 
%   'EventFieldsToIgnore'
%                    A cell array containing the field names to exclude.
%
%   'PreserveTagPrefixes'
%                    If false (default), tags associated with same value
%                    that share prefixes are combined and only the most
%                    specific is retained (e.g., /a/b/c and /a/b become
%                    just /a/b/c). If true, then all unique tags are
%                    retained.
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

function eData = writetags(eData, fMap, varargin)
p = parseArguments(eData, fMap, varargin{:});

tFields = setdiff(fMap.getFields(), p.EventFieldsToIgnore); % exclude fields to ignore


if isfield(eData, 'event') && isstruct(eData.event) %p.WriteIndividualTags && 
    tFields = intersect(fieldnames(eData.event), tFields); % only write tags to fields that exist in both fMap in EEG.event
%     eData = writeIndividualTagsAPI(eData, fMap);
    eData = writeIndividualTags(eData, fMap, tFields, ...
        p.PreserveTagPrefixes);
end

eData = writeSummaryTags(fMap, eData, tFields);
    function json = getCTaggerJsonFromfMap(fMap)
        fieldnames = fMap.getFields();
        result = [];
        for i=1:numel(fieldnames)
           field = fieldnames{i};
           result.(field).HED = containers.Map;
           values = fMap.getValues(field);
           for v=1:numel(values)
               code = values{v}.getCode();
%                if ~isempty(str2num(code))
%                    code = ['x' code];
%                end
               if ~isempty(values{v}.getTags())
                   if strcmp(code,'HED')
                       result.(field).HED = tagList.stringify(values{v}.getTags());
                   else
                       result.(field).HED(code) = tagList.stringify(values{v}.getTags());
                   end
               else
                   result.(field).HED(code) = "";
               end
           end
        end
        json = jsonencode(result);
        json = strrep(json, '"',"'");
    end
    function eData = writeIndividualTagsAPI(eData, fMap)
        json_text = getCTaggerJsonFromfMap(fMap);
        fid = fopen('events.json','w');
        fprintf(fid,'%s',json_text);
        fclose(fid);
        writetable(struct2table(eData.event), 'temp_events.txt', 'Delimiter', '\t')
        events_text = fileread('temp_events.txt');
        host = 'https://hedtools.ucsd.edu/hed';
        csrf_url = [host '/services']; 
        services_url = [host '/services_submit'];
        [cookie, csrftoken] = getSessionInfo(csrf_url);
        header = ["Content-Type" "application/json"; ...
                  "Accept" "application/json"; 
                  "X-CSRFToken" csrftoken; "Cookie" cookie];

        options = weboptions('MediaType', 'application/json', 'Timeout', 120, ...
                             'HeaderFields', header);
        
        request = struct('service', 'events_assemble', ...
                  'schema_version', '8.0.0', ...
                  'json_string', json_text, ...
                  'events_string', events_text, ...
                  'check_warnings_assemble', 'on', ...
                  'defs_expand', 'on');
        response = webwrite(services_url, request, options);
        response = jsondecode(response);      
        
        if isfield(response, 'results') && ~isempty(response.results)
            results = response.results;
            fprintf('[%s] status %s: %s\n', response.service, results.msg_category, results.msg);
            fprintf('HED version: %s\n', results.schema_version);
            fprintf('\nReturn data for service %s [command: %s]:\n', ...
                response.service, results.command);
            data = results.data;
            if ~iscell(data)
                fprintf('%s\n', data);
                fid = fopen("temp.txt","w");
                fprintf(fid, data);
                fclose(fid);
                res = importtsv('temp.txt');
                system('temp.txt');
            else
                for k = 1:length(data)
                    if ~isempty(data{k})
                        fprintf('[%d]: %s\n', k, data{k});
                    end
                end
            end

            %% Output the spreadsheet if available
            if  isfield(results, 'spreadsheet')
                fprintf('\n----Spreadsheet result----\n');
                fprintf(results.spreadsheet);
            end
        end
    end

    % Import tsv file
    % ---------------
    function res = importtsv(fileName)

    res = loadtxt( fileName, 'verbose', 'off', 'delim', 9);

    for iCol = 1:size(res,2)
        % search for NaNs in numerical array
        indNaNs = cellfun(@(x)strcmpi('n/a', x), res(:,iCol));
        if ~isempty(indNaNs)
            allNonNaNVals = res(find(~indNaNs),iCol);
            allNonNaNVals(1) = []; % header
            testNumeric   = cellfun(@isnumeric, allNonNaNVals);
            if all(testNumeric)
                res(find(indNaNs),iCol) = { NaN };
            elseif ~all(~testNumeric)
                % Convert numerical value back to string
                res(:,iCol) = cellfun(@num2str, res(:,iCol), 'uniformoutput', false);
            end
        end
    end

    end
    function eData = writeIndividualTags(eData, fMap, eFields, ...
            preserveTagPrefixes)
        % Write tags to individual events in HED field (this needs to
        % be optimized)
        for k = 1:length(eData.event)
            uTags = {};
            for l = 1:length(eFields)
                tags = fMap.getTags(eFields{l}, ...
                    num2str(eData.event(k).(eFields{l})));
                uTags = mergetaglists(uTags, tags, preserveTagPrefixes);
            end
            eData.event(k).HED = sorttags(tagList.stringify(uTags));
        end
    end % writeIndividualTags


    function eData = writeSummaryTags(fMap, eData, tFields)
        % Write summary tags in etc fields
        if isfield(eData, 'etc') && ~isstruct(eData.etc)
            eData.etc.other = eData.etc;
        end
        eData.etc.tags = '';   % clear the tags
        if isempty(tFields)
            map = '';
        else
            map(length(tFields)) = struct('field', '', 'values', '');
%             if isfield(eData, 'event') && isstruct(eData.event)
%                 for k = 1:length(tFields)
%                     map(k) = removeMapValues(fMap, eData, tFields{k});
%                 end
%             else
                for k = 1:length(tFields)
                    map(k) = fMap.getMap(tFields{k}).getStruct();
                end
%             end
        end
        eData.etc.tags = struct('description', fMap.getDescription(), ...
            'xml', fMap.getXml(), 'map', map);
    end % writeSummaryTags

    function map = removeMapValues(fMap, eData, tField)
        % Remove the values from the fMap that are not found in the dataset
        map = fMap.getMap(tField).getStruct();
        mapCodes = cellfun(@num2str, {map.values.code}, ...
            'UniformOutput', false);
        fieldCodes = unique(cellfun(@num2str, {eData.event.(tField)}, ...
            'UniformOutput', false));
        positions = ~ismember(mapCodes, fieldCodes);
        map.values(:, positions) = [];
    end % removeMapValues

    function p = parseArguments(eData, fMap, varargin)
        % Parses the input arguments and returns the results
        parser = inputParser;
        parser.addRequired('eData', @(x) (isempty(x) || isstruct(x)));
        parser.addRequired('fMap', @(x) (~isempty(x) && isa(x, ...
            'fieldMap')));
        parser.addParamValue('WriteIndividualTags', false, @islogical);
        parser.addParamValue('EventFieldsToIgnore', {}, @(x) (iscellstr(x)));
        parser.addParamValue('PreserveTagPrefixes', false, @islogical);
        parser.parse(eData, fMap, varargin{:});
        p = parser.Results;
    end % parseArguments

end %writetags