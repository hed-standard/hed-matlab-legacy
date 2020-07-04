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
%                   A cell array containing all of the issues found through
%                   the validation. Each cell corresponds to the issues
%                   found with the corresponding HED string. If there's no issues,
%                   the cell is empty. Otherwise, cell contains a struct array, 
%                   each has a code-message pair describing the issue code
%                   and the issue content
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
host = 'http://visualtest.cs.utsa.edu/hed';
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
    % Submit a POST request to the server at 'url', providing the list of HED strings and some other options
    % List of HED strings is converted to JSON format
    command = sprintf('curl -X POST -H "X-CSRFToken: %s" -H "Cookie: %s" -F hed_xml_file=%s -F hed_strings=''%s;type=application/json'' -F check_for_warnings=%d %s', csrftoken, cookie, hed_xml_file, jsonencode(hedStrings), generateWarnings, url);
    [status, result] = system(command);
catch
    ME = MException('validateHedString:serverError', ...
        'server error while processing request');
    throw(ME);
end

% parse result
if status == 0
    % result is a json object {issues: []}
    % The value is a list of validation results for each event HED string
    % If there's no error, validation result is an empty list
    % else it's a list of dictionaries, each dictionary is an error/warning
    json = jsondecode(result);
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
