function [errors, errorTags] = checkRequiredTags(Maps, formattedTags)
% Checks if all required tags are present in the tag list
errors = '';
errorTags = {};
requiredTags = Maps.required.values();
eventLevelTags = formattedTags(cellfun(@isstr, formattedTags));
checkRequiredTags();

    function checkRequiredTags()
        % Checks the tags that are required
        numTags = length(requiredTags);
        for a = 1:numTags
            requiredIndexes = strncmpi(eventLevelTags, requiredTags{a}, ...
                length(requiredTags{a}));
            if sum(requiredIndexes) == 0
                generateErrorMessages(a);
            end
        end
    end % checkRequiredTags

    function generateErrorMessages(requiredIndex)
        % Generates a required tag errors if the required tag isn't present
        % in the tag list
        errors = [errors, generateErrorMessage('required', '', ...
            requiredTags{requiredIndex}, '')];
        errorTags{end+1} = requiredTags{requiredIndex};
    end % generateErrorMessages

end % checkRequiredTags