function [EEG,fMap] = removeTagsEEG(EEG)
    fMap = [];
    fprintf('Clearing EEG tags... ');
    if hasSummaryTags(EEG)
        fMap = fieldMap.createfMapFromStruct(EEG.etc.tags);
        EEG.etc = rmfield(EEG.etc, 'tags');
    end
    if isfield(EEG.event, 'HED')
        fMap = findtags(EEG);
        EEG = pop_editeventfield(EEG, 'HED', []);
    end

    function summaryFound = hasSummaryTags(EEG)
        % Returns true if there are summary tags found in the .etc field
        summaryFound = isfield(EEG, 'etc') && ...
            isstruct(EEG.etc) && ...
            isfield(EEG.etc, 'tags') && ...
            isstruct(EEG.etc.tags) && ...
            isfield(EEG.etc.tags, 'map') && ...
            isstruct(EEG.etc.tags.map) && ...
            isfield(EEG.etc.tags.map, 'field');
    end % hasSummaryTags
    

end % removeTagsEEG