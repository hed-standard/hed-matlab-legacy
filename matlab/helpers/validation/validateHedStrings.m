% Validate a strings of HED tags through validation server
% Called by parseeeg.m and validatestudy.m
% This is the only interface with the Python validator
% Expected content of form submission:
%       - Header must contain CSRF Token and Session Cookie
%       - hed_xml_file: XML file to validate the hed strings against
%       - hed_strings: json string containing all HED strings associated with 
%                      event fields or specific events to be validated
%       - check_for_warnings: 1 or 0 indicating if wants to include
%                             warnings in validation result or not
%
% Usage:
%
%   >>  issues = validateHedStrings(hedxml, validatingItems, generateWarnings)
%
% Input:
%
%   Required:
%
%   hedxml
%                    the xml file containing HED schema to validate against
%   validatingItems
%                    struct array of items to be validated
%   generateWarnings
%                    whether to report warnings or not
%
% Output:
%
%   issues
%                    issues associated with the hed strings
%
% Copyright (C) 2019 Dung Truong dt.young112@gmail.com and
% Kay Robbins kay.robbins@utsa.edu
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
function issues = validateHedStrings(hedxml, validatingItems, generateWarnings)
% set up server destination
host = 'http:///localhost:33000';
% host = 'http://34.68.100.24';
% host = 'http://127.0.0.1:5000';
% host = 'http://visual.cs.utsa.edu/hed';

% retrieve CSRF token and cookies
[status, response] = system(['curl -v ' host '/eegvalidation']);
checkError(status,[host '/eegvalidation']);
[csrftoken, cookie] = getCSRFCookies(response);

% prepare data
if isempty(hedxml)
    hed_xml_file = "";
else
     hed_xml_file = ['@' hedxml];
%     hed_xml_file = fileread(hedxml);
end

% submit request to server for validation results
url = [host '/eegsubmit'];
json_text = toJson(validatingItems);
fprintf(['Validating through server at ' host ' ...\n']);
command = sprintf('curl -X POST -H "X-CSRFToken: %s" -H "Cookie: %s" -F hed_xml_file=%s -F hed_strings=''%s;type=application/json'' -F check_for_warnings=%d %s', csrftoken, cookie, hed_xml_file, json_text, generateWarnings, url);
[status, response] = system(command);

checkError(status,command);

% retrieve issues
issues = parseResponseForIssues(response);

fprintf("Finished.\n");

    %%%
    % Check if system command return error status
    %%%
    function checkError(status, command)  
        if status ~= 0
            serverError(['Failed to execute curl command: ' command]);
        end
    end

    % Get CSRF token and session cookies from server response
    function [csrftoken, cookie] = getCSRFCookies(str)
        try
            csrfIdx = strfind(str,"csrf_token");
            tmp = str(csrfIdx(1)+strlength("csrf_token")+1:end);
            csrftoken = regexp(tmp,'".*?"','match');
            csrftoken = csrftoken{1}(2:end-1);

            cookieIdx = strfind(str,"Set-Cookie");
            tmp = str(cookieIdx(1)+strlength("Set-Cookie")+2:end);
            cookie = regexp(tmp,'session.*?;','match');
            cookie = cookie{1}(1:end-1);
        catch 
            serverError(str);
        end
    end
    
    % Retrieve issues from response
    function issues = parseResponseForIssues(result)
        try
%             result_splitted = splitlines(result);
%             validation_result = result_splitted{end};
            json = jsondecode(result);
            issues = json.issues;
        catch
            serverError(result);
        end   
    end

    %%%
    % Build json string to be submitted to the validation server
    % json format is in sync with validation server's expectation
    %
    function json_text = toJson(validatingItems)
        json_text = '{';
        for i=1:numel(validatingItems)
            item = validatingItems(i);
            json_text = [json_text '"' item.value '": {"type":"' item.type '", "typeValue":"' item.typeName ,'", "hed_string":' jsonencode(item.hedString) '}']; %jsonencode(hedStrings)
            if i ~= numel(validatingItems)
                json_text = [json_text ','];
            end
        end
        json_text = [json_text '}'];
    end

    function serverError(submissionContent)
%         setpref('Internet','SMTP_Server','mail');
%         setpref('Internet','E_mail','eeglab@ucsd.edu');
%         sendmail('dt.young112@gmail.com','HEDTools error', submissionContent);
        ME = MException('validateHedString:serverError', ...
            'An error occur while trying to validate HED strings using validator server.\n Please try again later or submit your error to EEGLAB developer');
        throw(ME);
    end
end