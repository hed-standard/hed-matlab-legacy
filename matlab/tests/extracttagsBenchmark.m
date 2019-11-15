function extracttagsBenchmark(EEG)
% Benchmark of set-intersection algorithms for extracttags.m
% Take in a tagged EEG structure
events = EEG.event;
fields = fieldnames(events);
allElapsed1 = []; allElapsed2 = [];

for f=1:numel(fields)
    valueField = fields{f};
    fprintf("Processing %s\n", valueField);
    parseArguments();
    positions = arrayfun(@(x) ~isempty(x.(valueField)), events);
    values = {events(positions).(valueField)};
    tags = {events(positions).('usertags')};
    values = cellfun(@num2str, values, 'UniformOutput', false);
    uniqueValues = unique(cellfun(@num2str, values, 'UniformOutput', false));
    elapsedDiff = [];
    
    for k = 1:length(uniqueValues)
        if ~isempty(uniqueValues{k})
            theseValues = strcmpi(uniqueValues{k}, values);
            theseTags = tags(theseValues);

            if ~isempty(theseTags)
                % New algorithm
                myTagList1 = tagList(uniqueValues{k});
                tic
                myTagList1.addList(getIntersectingTags(theseTags));
                elapsedTime1 = toc;
                allElapsed1 = [allElapsed1 elapsedTime1];
                % Original algorithm (before Nov 13)
                myTagList2 = tagList(uniqueValues{k});
                tic
                myTagList2.addString(theseTags{1});
                for j = 2:length(theseTags)
                    newList = tagList(uniqueValues{k});
                    newList.addString(theseTags{j});
                    myTagList2.intersect(newList);
                end
                elapsedTime2 = toc;
                allElapsed2 = [allElapsed2 elapsedTime2];
                
                % Process result
                elapsedDiff = [elapsedDiff (elapsedTime2/elapsedTime1)];
                
                % Check to make sure two results are similar
                isDiff = ~isempty(setdiff(myTagList2.getTags,myTagList1.getTags)) || ~isempty(setdiff(myTagList1.getTags,myTagList2.getTags));
                if isDiff
                    error("Different");
                end
            end
        end
    end
    
    fprintf("Average gain for %s is %f times\n",valueField, mean(elapsedDiff));  
end

fprintf("Total elapsed time for new algorithm: %f\n", sum(allElapsed1));
fprintf("Total elapsed time for old algorithm: %f\n", sum(allElapsed2));


    function p = parseArguments()
        % Parses the arguments passed in and returns the results
        p = inputParser();
        p.addRequired('events', @(x) ~isempty(x) && isstruct(x));
        p.addRequired('valueField', @(x) ~isempty(x) && ischar(x));
    end % parseArguments

    function intersection = getIntersectingTags(allTagStrings)
    % New algorithm to extract intersection of all tag sets
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
end