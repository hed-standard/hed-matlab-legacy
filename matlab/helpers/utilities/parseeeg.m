% This function takes in a EEG event structure containing HED tags
% and validates them against a HED schema. The validatetsv function calls
% this function to parse the tab-separated file and generate any issues
% found through the validation.
%
% Usage:
%
%   >>  [issues, replaceTags, success] = parseeeg(hedXml, events, ...
%        generateWarnings)
%
% Input:
%
%       hedXml
%                   The full path to a HED XML file containing all of the
%                   tags. This by default will be the HED.xml file
%                   found in the hed directory.
%
%       events
%                   The EEG event structure containing the HED tags
%                   associated with a particular study.
%
%       generateWarnings
%                   True to include warnings in the log file in addition
%                   to errors. If false (default) only errors are included
%                   in the log file.
%
% Output:
%
%       issues
%                   A cell array containing all of the issues found through
%                   the validation. Each cell corresponds to the issues
%                   found on a particular line.
%
%       replaceTags
%                   A cell array containing all of the tags that generated
%                   issues. These tags will be written to a replace file.
%
%       success
%                   True if the validation finishes without throwing any
%                   exceptions, false if otherwise.
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

function issues = parseeeg(hedXml, EEG, generateWarnings)
p = parseArguments(hedXml, EEG, generateWarnings);
issues = validateEventsTags(p);

    function p = parseArguments(hedXml, EEG, generateWarnings)
        % Parses the arguements passed in and returns the results
        parser = inputParser;
        parser.addRequired('hedXml', @(x) (~isempty(x) && ischar(x)));
        parser.addRequired('EEG', @(x) (~isempty(x) && isstruct(x)));
        parser.addRequired('generateWarnings', @islogical);
        parser.parse(hedXml, EEG, generateWarnings);
        p = parser.Results;
    end % parseArguments

    function issues = validateEventsTags(p)
        % Extract the HED tags from the EEG event structure array and validate them
        p.issues = {};
        p.replaceTags = {};
        p.issueCount = 1;
        validatingItems = struct([]);
        
        % get HED string items to be validated from fMap
        fMap = findtags(p.EEG, 'HedXml', p.hedXml);
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
        
        % get HED string items to be validated from the dataset's
        % event.hedtags field if exist
        events = p.EEG.event;
        numberEvents = length(events);
        if isfield(events, 'hedtags')
            for a = 1:numberEvents
                if ~isempty(events(a).hedtags)
                    item.type = 'eventSpecific';
                    if ~isempty(p.EEG.setname)
                        item.typeName = p.EEG.setname;
                    else
                        item.typeName = p.EEG.filename;
                    end
                    item.value = num2str(a);
                    item.hedString = concattags(events(a));       
                    validatingItems = [validatingItems item];
                end
            end 
        end
        
        % validate
        try
            issues = validateHedStrings(p.hedXml,validatingItems,p.generateWarnings);
        catch ME
            if ME.identifier == "validateHedString:serverError"
                throw(ME);
            else
                throw(MException('parseeeg:cannotRead', ...
                'Unable to read event %d', a));
            end
        end
    end % readStructTags

    function hedString = cellArray2String(cellArr)
        hedString = '';
        for i=1:numel(cellArr)
            hedString = [hedString cellArr{i}];
            if i < numel(cellArr)
                hedString = [hedString ', '];
            end
        end
    end
end % parseeeg