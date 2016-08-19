% selectmaps
% Allows a user to select the fields to be used
%
% Usage:
%   >>  [fMap, excluded] = selectmaps(fMap)
%   >>  [fMap, excluded] = selectmaps(fMap, 'key1', 'value1', ...)
%
% Description
% [fMap, excluded] = selectmaps(fMap) removes the fields that are excluded
% by the user during selection.
%
% [fMap, excluded] = selectmaps(fMap, 'key1', 'value1', ...) specifies
% optional name/value parameter pairs:
%   'selectFields'   If true (default), the user is presented with a GUI
%                    that allows users to select which fields to tag.
%
% Function documentation:
% Execute the following in the MATLAB command window to view the function
% documentation for selectmaps:
%
%    doc selectmaps
%
% See also: pop_tageeg, pop_tagstudy, pop_tagdir, pop_tagcsv
%
% Copyright (C) Kay Robbins, Jeremy Cockfield, and Thomas Rognon, UTSA,
% 2011-2015, kay.robbins.utsa.edu jeremy.cockfield.utsa.edu
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

function [fMap, fields, excluded, canceled] = selectmaps(fMap, varargin)
p = parseArguments(fMap, varargin{:});
canceled = false;
selectFields = p.selectFields;
primaryField = p.primaryField;
fields = intersect(p.Fields, fMap.getFields(), 'stable');
excluded = setdiff(p.ExcludeFields, fields);
if isempty(fields) && selectFields
    [fields, excluded, canceled] = selectFields2Tag(fields, excluded, ...
        primaryField);
end
fMap = removeExcludedFields(fMap, excluded);
fMap.setPrimaryMap(primaryField);

    function [fields, excluded, canceled] = selectFields2Tag(fields, ...
            excluded, primaryField)
        % Select fields to tag with a menu
        canceled = false;
        [fields, primaryField] = putPrimaryFirst(primaryField, fields);
        [loader, submitted] = showSelectionMenu(excluded, fields, ...
            primaryField);
        excludeUser = cell(loader.getExcludeFields());
        primaryField = char(loader.getPrimaryField());
        if ~submitted
            canceled = true;
            return;
        end
        fields = cell(loader.getTagFields());
        excluded = setdiff(union(excluded, excludeUser), fields);
    end % selectFields2Tag

    function fMap = removeExcludedFields(fMap, excluded)
        % Remove the excluded fields from the fMap
        for k = 1:length(excluded)
            fMap.removeMap(excluded{k});
        end
    end % removeExcludedFields

    function [loader, submitted] = showSelectionMenu(excluded, fields, ...
            primaryField)
        % Show a java field selection menu
        fprintf('\n---Now select the fields you want to tag---\n');
        title = 'Please select the fields that you would like to tag';
        loader = javaObject('edu.utsa.tagger.FieldSelectLoader', title, ...
            excluded, fields, primaryField);
        [notified, submitted] = checkMenuStatus(loader);
        while (~notified)
            pause(0.5);
            [notified, submitted] = checkMenuStatus(loader);
        end
    end % showSelectionMenu

    function [notified, submitted] = checkMenuStatus(loader)
        % Check the status of the java field selection menu
        notified = loader.isNotified();
        submitted = loader.isSubmitted();
    end % checkMenuStatus

    function [fields, primaryField] = putPrimaryFirst(primaryField, ...
            fields)
        % Moves the primary field to the beginning of the list of fields
        if sum(strcmp(fields, primaryField)) == 0
            primaryField = '';
        else
            pos = find(strcmp(fields, primaryField));
            temp = fields{pos};
            fields{pos} = fields{1};
            fields{1} = temp;
        end
    end % putPrimaryFirst

    function p = parseArguments(fMap, varargin)
        % Parses the input arguments and returns the results
        parser = inputParser;
        parser.addRequired('fMap', @(x) (~isempty(x) && ...
            isa(x, 'fieldMap')));
        parser.addParamValue('ExcludeFields', {}, ...
            @(x) (iscellstr(x)));
        parser.addParamValue('Fields', {}, @(x) (iscellstr(x)));
        parser.addParamValue('primaryField', 'type', @(x) ...
            (isempty(x) || ischar(x)))
        parser.addParamValue('selectFields', true, @islogical);
        parser.parse(fMap, varargin{:});
        p = parser.Results;
    end % parseArguments

end % selectmaps