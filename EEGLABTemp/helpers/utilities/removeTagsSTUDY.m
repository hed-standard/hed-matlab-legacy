function [STUDY,EEG,fMap] = removeTagsSTUDY(STUDY,EEG)
    fprintf('Clearing STUDY tags... \n');
    fMap = fieldMap();
    if hasSummaryTags(STUDY)
        fMap = fieldMap.createfMapFromStruct(STUDY.etc.tags);
        STUDY.etc = rmfield(STUDY.etc, 'tags');
    end
    for i=1:length(EEG)
        EEGTemp = EEG(i);
        [EEGTemp, fMapEEG] = removeTagsEEG(EEGTemp);
        EEG(i) = EEGTemp;
        fMap.merge(fMapEEG, 'Merge', {},{});
        pop_saveset(EEG(i), 'filename', EEG(i).filename, 'filepath', EEG(i).filepath); 
    end    
    fprintf('Done.\n')
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
    
end % removeTagsSTUDY