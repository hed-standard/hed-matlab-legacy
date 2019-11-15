function tMap = extracttags(events, valueField)
% Extract a tagmap from the usertags in the event structure.
parseArguments();
tMap = tagMap();
positions = arrayfun(@(x) ~isempty(x.(valueField)), events);
values = {events(positions).(valueField)};
tags = {events(positions).('usertags')};
values = cellfun(@num2str, values, 'UniformOutput', false);
uniqueValues = unique(cellfun(@num2str, values, 'UniformOutput', false));
for k = 1:length(uniqueValues)
    if ~isempty(uniqueValues{k})
        theseValues = strcmpi(uniqueValues{k}, values);
        theseTags = tags(theseValues);
        myTagList = tagList(uniqueValues{k});
        if ~isempty(theseTags)
            myTagList.addList(theseTags);
        end
        tMap.addValue(myTagList);
    end
end

    function p = parseArguments()
        % Parses the arguments passed in and returns the results
        p = inputParser();
        p.addRequired('events', @(x) ~isempty(x) && isstruct(x));
        p.addRequired('valueField', @(x) ~isempty(x) && ischar(x));
    end % parseArguments

    function intersection = getIntersectingTags(allTagStrings)
    % Extract intersection of all tag sets
        tagsArray = cell(1, numel(allTagStrings));
        intersection = [];
        for i=1:numel(allTagStrings)
            tagsArray(i) = {tagList.deStringify(allTagStrings{i})};
        end
        firstTags = tagsArray{1};
        for i=1:numel(firstTags)
            isInSet = true;
            for t=2:numel(tagsArray)
                if all(~strcmpi(firstTags{i},tagsArray{t}))
                    isInSet = false;
                    break;
                end
            end
            if isInSet
                intersection = [intersection firstTags(i)];
            end
        end
    end

end % extracttags