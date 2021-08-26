% Create new field and add it to EEG.event
% 
%
% Usage:
%
%   >>  EEG = pop_newfield(EEG, 'NewFieldName', key, value)
%
% Input:
%
%   Required:
%
%   EEG              An EEGLAB EEG structure
%
%   NewFieldName
%                    Name of the new field to be created
%
%   Optional (key/value):
%
%   'EventFieldsToIgnore'
%                    A one-dimensional cell array of field names in the
%                    .event substructure to ignore during the tagging
%                    process. By default the following subfields of the
%                    .event structure are ignored: .latency, .epoch,
%                    .urevent, .HED. The user can
%                    over-ride these tags using this name-value parameter.
%
%
% Output:
%
%   EEG              EEG structure with added new field
%
% Copyright (C) 2020 Dung Truong dutruong@ucsd.edu
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
function EEG = pop_newfield(EEG, newFieldName, varargin)
if nargin < 2
   help pop_newfield
   return
end
p = parseArguments(newFieldName, varargin{:});
json = ['{"newFieldName": ' jsonencode(p.NewFieldName) ', "eventFields": ' fieldValueToJson(EEG,p) '}'];

pathToJar = '/Users/dtyoung/Documents/HED/hed-java/java/field-generator/out/artifacts/field_generator_jar/field-generator.jar';
[status, result] = system(['java -jar ' pathToJar ' ''' json '''']);
if status ~= 0 
    error("error generating new field %s: %s", p.NewFieldName, result);
end

EEG = addNewField(EEG, result, p);

% generate text command
ignoreString = jsonencode(p.EventFieldsToIgnore);
ignoreString = strrep(ignoreString,'[','{');
ignoreString = strrep(ignoreString,']','}');
com = sprintf('EEG = pop_newfield(EEG, %s, ''EventFieldsToIgnore'', %s', newFieldName, ignoreString);

    function EEG = addNewField(EEG, jsonResult, p)
        newFieldMap = jsondecode(jsonResult);
        newFieldValues = fields(newFieldMap); % newFieldMap is a struct whose fields are values of the new field
        for i=1:numel(newFieldValues)
            map = newFieldMap.(newFieldValues{i}); % map of (target) EEG.event fields and their selected values to be associated with the new value

            condition = ones(1,size(EEG.event,2)); % logical array of events with matching specified fields-values

            fieldsList = fields(map); % list of target fields
            for j=1:numel(fieldsList)
                field = fieldsList{j}; % target field
                targetValues = map.(field); % target field values - always string

                % get all events of EEG.event.(field)
                if isnumeric(EEG.event(1).(field))
                   temp = {EEG.event.(field)};
                   values = cellfun(@num2str, temp,'UniformOutput',false);
                else
                   values = {EEG.event.(field)};
                end
                % match mask
                isMatch = ismember(values, targetValues);
                condition = condition & isMatch;
            end

            % assign new field value where matches
            matchEvents = find(condition);
            for e=1:numel(matchEvents)
                EEG.event(matchEvents(e)).(p.NewFieldName) = newFieldValues{i};
            end
        end
    end

    function jsonString = fieldValueToJson(EEG, p)
       jsonObject = [];
       eventFields = fields(EEG.event);

       for i=1:numel(eventFields)
           field = eventFields{i};
           if ~ismember(field, p.EventFieldsToIgnore)
               if isnumeric(EEG.event(1).(field))
                   temp = unique([EEG.event.(field)]);
                   uniqueValues = arrayfun(@num2str, temp,'UniformOutput',false);
                   
               else
                   uniqueValues = unique({EEG.event.(field)});
               end
               jsonObject.(field) = uniqueValues;
           end
       end
       
       jsonString = jsonencode(jsonObject);
    end

    function p = parseArguments(newFieldName, varargin)
        % Parses the input arguments and returns the results
        parser = inputParser;
        parser.addRequired('NewFieldName', @ischar);
        parser.addParamValue('EventFieldsToIgnore', ...
            {'latency', 'epoch', 'urevent', 'HED'}, ...
            @iscellstr);
        parser.parse(newFieldName, varargin{:});
        p = parser.Results;
    end % parseArguments
end