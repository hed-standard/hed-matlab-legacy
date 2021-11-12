function [fMap, canceled] = useCTagger(fMap)
    json = getCTaggerJsonFromfMap(fMap);
    
    % start CTagger
    [hedMap, canceled] = loadCTagger(json);
    
    % merge result
    if ~canceled
        fMap.merge(hedMap, 'Replace',{},{});   
    end
    
    
    function [result, canceled] = loadCTagger(json)
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
                    code = codes{c};
                    % strip the prefix 'x' if exists in number code
                    startIndex = regexp(code,'^x\d*$');
                    if ~isempty(startIndex)
                        code = code(2:end);
                    end
                    codeMap = tagList(code);
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
    function json = getCTaggerJsonFromfMap(fMap)
        fieldnames = fMap.getFields();
        result = [];
        for i=1:numel(fieldnames)
           field = fieldnames{i};
           result.(field).HED = containers.Map;
           values = fMap.getValues(field);
           for v=1:numel(values)
               code = values{v}.getCode();
%                if ~isempty(str2num(code))
%                    code = ['x' code];
%                end
               if ~isempty(values{v}.getTags())
                   result.(field).HED(code) = tagList.stringify(values{v}.getTags());
               else
                   result.(field).HED(code) = "";
               end
           end
        end
        json = jsonencode(result);
        json = strrep(json, '"',"'");
    end
end