function issues = validateHedStrings(hedxml, hedStrings, generateWarnings)
% set up server destination
host = 'http://localhost:33000';
url = [host '/eegvalidation'];

% retrieve CSRF token
%  spreadsheetform = urlread([host '/validation']);
%  csrftoken = getCSRFToken(spreadsheetform);

% prepare data
if isempty(hedxml)
    hed_xml_file = "";
else
     hed_xml_file = ['@' hedxml];
%     hed_xml_file = fileread(hedxml);
end

% submit request to server for validation results
try
    fprintf(['Validating through server at ' url ' ...\n']);
    command = sprintf('curl -X GET -F hed_xml_file=%s -F hed_strings=''{"hed_strings":%s};type=application/json'' -F check_for_warnings=%d %s', hed_xml_file, jsonencode(hedStrings), generateWarnings, url);
    [status, result] = system(command);
catch
    ME = MException('validateHedString:serverError', ...
        'server error while processing request');
    throw(ME);
end

% parse result
if status == 0
    result_splitted = splitlines(result);
    validation_result = result_splitted{end};
    json = jsondecode(validation_result);
    issues = json.issues;
    fprintf("Finished.\n");
else
    ME = MException('validateHedString:serverError', ...
        'Failed to validate hed strings');
    throw(ME);
end

%     function csrftoken = getCSRFToken(str)
%         csrfIdx = strfind(str,"csrf_token");
%         tmp = str(csrfIdx(1)+strlength("csrf_token")+1:end);
%         csrftoken = regexp(tmp,'".*?"','match');
%         csrftoken = csrftoken{1}(2:end-1);
%     end
end