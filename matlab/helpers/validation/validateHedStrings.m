function issues = validateHedStrings(hedxml, hedStrings, generateWarnings)
host = 'http://localhost:33000';
uri = [host '/eegvalidation'];
fprintf(['Validating through server at ' uri ' ...\n']);
if isempty(hedxml)
    hed_xml_file = "";
else
    hed_xml_file = ['@' hedxml];
end
command = sprintf('curl -X POST -F hed_xml_file=%s -F hed_strings=''{"hed_strings":%s};type=application/json'' -F check_for_warnings=%d %s', hed_xml_file, jsonencode(hedStrings), generateWarnings,uri);
[status, result] = system(command);
if status == 0
    result_splitted = splitlines(result);
    validation_result = result_splitted{end};
    json = jsondecode(validation_result);
    issues = json.issues;
    fprintf("Finished\n");
else
    error('Error from validation server');
end
end