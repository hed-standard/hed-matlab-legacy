function [fMap, canceled] = useCTagger(fMap, EEG)
    canceled = 0;
    fieldStruct = fMap.getStruct();
    fields = {fieldStruct.map.field};
    json = "";
    
    if isfield(EEG, 'etc') && isfield(EEG.etc,'tags')
        json = getCTaggerJsonFromSummary(EEG.etc.tags);
    else
    %% Defining GUI elements
        geometry = {[1] ...
                    [1] ...
                    [1 1]};
        uilist = {...
            {'Style', 'text', 'string', 'Select categorical fields:'} ...
            {'Style', 'listbox', 'string', fields, 'tag', 'listboxCB', 'HorizontalAlignment','left', 'Max',2,'Min',0} ...
            { 'style', 'pushbutton' , 'string', 'Cancel', 'tag', 'cancel', 'callback', @cancelCallback},...
            { 'style', 'pushbutton' , 'string', 'Done', 'tag', 'ok', 'callback', @doneCallback}};

        % Draw supergui
        [~,~, handles] = supergui( 'geomhoriz', geometry, 'geomvert',[1 8 1], 'uilist', uilist, 'title', 'Select field to use for tagging -- pop_tageeg()');
        figure_handle = get(handles{1},'parent');
        waitfor(figure_handle);
    end
    if ~canceled
        [hedMap, canceled] = loadCTagger();
        if ~canceled
            fMap.merge(hedMap, 'Merge',{},{});   
        end
    end
    function [result, canceled] = loadCTagger()
       canceled = false;
       notified = false;
        loader = javaObject('TaggerLoader', json);
        while (~notified)
            pause(0.5);
            notified = loader.isNotified();
        end
        if loader.isCanceled()
            canceled = true;
            result = [];
        else
            cMap = jsondecode(char(loader.getHEDJson()));
            result = ctaggerMapTofMap(cMap);
        end
    end
    function map = ctaggerMapTofMap(ctaggerMap)
        map = fieldMap();
        cFields = fieldnames(ctaggerMap);
        for f=1:numel(cFields)
            field = cFields{f};
            HED = ctaggerMap.(field).HED;
            if isstruct(HED)
                codes = fieldnames(HED);
                for c=1:numel(codes)
                    codeMap = tagList(codes{c});
                    codeMap.addString(HED.(codes{c}));
                    map.addValues(field,codeMap);
                end
            else
                codeMap = tagList('HED');
                codeMap.addString(HED);
                map.addValues(field,codeMap);
            end
        end
    end
    function cancelCallback(~, ~)
        canceled = 1;
        close(gcbf);
    end
    function doneCallback(~, ~)
        canceled = 0;
        listbox = get(findobj('tag','listboxCB'));
        selected = listbox.Value;
        fMap = setValueFields(fMap,selected);
        json = getCTaggerJson(selected);
        close(gcbf);
    end
    function fMap = setValueFields(fMap,selected)
        fMapFields = fMap.getFields();
        for i=1:numel(fMapFields)
            field = fMapFields{i};
            if ~any(i == selected)
                codeMap = tagList('HED');
                codeMap.addString("");
                fMap.addValues(field,codeMap);
            end
        end
    end
    function json = getCTaggerJsonFromSummary(summary)
        map = summary.map;
        result = [];
        for i=1:numel({map.field})
           result.(map(i).field).HED = [];
           for v=1:numel({map(i).values.code})
               code = map(i).values(v).code;
               if ~isempty(str2num(code))
                   code = ['x' code];
               end
               if ~isempty(map(i).values(v).tags)
                   result.(map(i).field).HED.(code) = tagList.stringify(map(i).values(v).tags);
               else
                   result.(map(i).field).HED.(code) = "";
               end
           end
        end
        json = jsonencode(result);
        json = strrep(json, '"',"'");
    end
    function json = getCTaggerJson(selected)
        map = fieldStruct.map;
        result = [];
        for i=1:numel({map.field})
           if (any(i == selected))
               result.(map(i).field).HED = [];
               for v=1:numel({map(i).values.code})
                   code = map(i).values(v).code;
                   if ~isempty(str2num(code))
                       code = ['x' code];
                   end
                   if ~isempty(map(i).values(v).tags)
                       result.(map(i).field).HED.(code) = tagList.stringify(map(i).values(v).tags);
                   else
                       result.(map(i).field).HED.(code) = "";
                   end
               end
           else % value fields
               codes = {map(i).values.code};
               if any(strcmp(codes, 'HED')) && ~isempty(map(i).values(strcmp(codes,'HED')).tags)
                   result.(map(i).field).HED = tagList.stringify(map(i).values(strcmp(codes,'HED')).tags);
               else
                   result.(map(i).field).HED = "";
               end
           end
        end
        json = jsonencode(result);
        json = strrep(json, '"',"'");
    end
end