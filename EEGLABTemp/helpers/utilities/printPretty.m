function printPretty(hed_string) 
    tags = strtrim(regexp(hed_string,'[\w\s\/.]+(?=,)|(?=,)[\w\s\/.]+|\(.*?\)','match'));
    for i=1:numel(tags)
        if i < numel(tags)
            fprintf('%s,\n',tags{i});
        else
            fprintf('%s\n',tags{i});
        end
    end
end