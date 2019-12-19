% Validate a strings of HED tags through validation server
% called by parseeeg.m
%
% Usage:
%
%   >>  issues = validateHedStrings(hedxml, hedStrings, generateWarnings)
%
% Input:
%
%   Required:
%
%   hedxml
%                    the xml file containing HED schema to validate against
%   hedStrings
%                    strings of hed tags
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
function issues = validateHedStrings(hedxml, hedStrings, generateWarnings)
% set up server destination
% host = 'http://visualtest.cs.utsa.edu/hed';
host = 'http://localhost:33000';
% host = 'http://127.0.0.1:5000';
host = 'http://34.68.100.24';
url = [host '/eegsubmit'];

% retrieve CSRF token and cookies
[~,response] = system(['curl -v ' host '/eegvalidation']);
[csrftoken, cookie] = getCSRFCookies(response);

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
    command = sprintf('curl -X POST -H "X-CSRFToken: %s" -H "Cookie: %s" -F hed_xml_file=%s -F hed_strings=''{"hed_strings":%s};type=application/json'' -F check_for_warnings=%d %s', csrftoken, cookie, hed_xml_file, jsonencode(hedStrings), generateWarnings, url);
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
    % Get CSRF token and session cookies from server response
    function [csrftoken, cookie] = getCSRFCookies(str)
        csrfIdx = strfind(str,"csrf_token");
        tmp = str(csrfIdx(1)+strlength("csrf_token")+1:end);
        csrftoken = regexp(tmp,'".*?"','match');
        csrftoken = csrftoken{1}(2:end-1);

        cookieIdx = strfind(str,"Set-Cookie");
        tmp = str(cookieIdx(1)+strlength("Set-Cookie")+2:end);
        cookie = regexp(tmp,'session.*?;','match');
        cookie = cookie{1}(1:end-1);
    end
end