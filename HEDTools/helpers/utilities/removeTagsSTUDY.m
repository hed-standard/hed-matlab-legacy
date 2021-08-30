function [STUDY,ALLEEG,fMap] = removeTagsSTUDY(STUDY,ALLEEG)
    fMap = fieldMap();
    if hasSummaryTags(STUDY)
        fMap = fieldMap.createfMapFromStruct(STUDY.etc.tags);
        STUDY.etc = rmfield(STUDY.etc, 'tags');
    end
    for i=1:length(ALLEEG)
        EEGTemp = ALLEEG(i);
        [EEGTemp, fMapEEG] = removeTagsEEG(EEGTemp);
        ALLEEG(i) = EEGTemp;
        fMap.merge(fMapEEG, 'Merge', {},{});
        pop_saveset(ALLEEG(i), 'filename', ALLEEG(i).filename, 'filepath', ALLEEG(i).filepath); 
    end

    
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