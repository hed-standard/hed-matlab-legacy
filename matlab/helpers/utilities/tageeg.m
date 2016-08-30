% Allows a user to tag a EEG structure. First all of the tag information
% and potential fields are extracted from EEG.event, EEG.urevent, and
% EEG.etc.tags structures. After existing event tags are extracted and
% merged with an optional input fieldMap, the user is presented with a
% GUI to accept or exclude potential fields from tagging. Then the user is
% presented with the CTagger GUI to edit and tag. Finally, the tags are
% rewritten to the EEG structure.
%
% Usage:
%
%   >>  [EEG, fMap, canceled] = tageeg(EEG)
%
%   >>  [EEG, fMap, canceled] = tageeg(EEG, 'key1', 'value1', ...)
%
% Input:
%
%   Required:
%
%   EEG
%                    The EEG dataset structure that will be tagged. The
%                    dataset will need to have a .event field.
%
%   Optional (key/value):
%
%   'BaseMap'
%                    A fieldMap object or the name of a file that contains
%                    a fieldMap object to be used to initialize tag
%                    information.
%
%   'EditXml'
%                    If false (default), the HED XML cannot be modified
%                    using the tagger GUI. If true, then the HED XML can be
%                    modified using the tagger GUI.
%
%   'ExcludeFields'
%                    A cell array of field names in the .event substructure
%                    to ignore during the tagging process. By default the
%                    following subfields of the event structure are
%                    ignored: .latency, .epoch, .urevent, .hedtags, and
%                    .usertags. The user can over-ride these tags using
%                    this name-value parameter.
%
%   'Fields'
%                    A cell array of field names of the fields to include
%                    in the tagging. If this parameter is non-empty, only
%                    these fields are tagged.
%
%   'PreservePrefix'
%                    If false (default), tags for the same field value that
%                    share prefixes are combined and only the most specific
%                    is retained (e.g., /a/b/c and /a/b become just
%                    /a/b/c). If true, then all unique tags are retained.
%
%   'PrimaryField'
%                    The name of the primary field. Only one field can be
%                    the primary field. A primary field requires a label,
%                    category, and a description. The default is the type
%                    field.
%
%   'SaveMapFile'
%                    A string representing the file name for saving the
%                    final, consolidated fieldMap object that results from
%                    the tagging process.
%
%   'SelectFields'
%                    If true (default), the user is presented with a
%                    GUI that allow users to select which fields to tag.
%
%   'UseGui'
%                    If true (default), the CTAGGER GUI is used to edit
%                    field tags.
%
% Output:
%
%   EEG
%                    The EEG dataset structure that has been tagged. The
%                    tags will be written to the .usertags field under
%                    the .event field.
%
%   fMap
%                    A fieldMap object that stores all of the tags.
%
%   canceled
%                    True if the tagging has been canceled, False if
%                    otherwise.
%
% Copyright (C) 2012-2016 Thomas Rognon tcrognon@gmail.com, 
% Jeremy Cockfield jeremy.cockfield@gmail.com, and
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

function [EEG, fMap, canceled] = tageeg(EEG, varargin)
p = parseArguments(EEG, varargin{:});
canceled = false;

fMap = findtags(EEG, 'PreservePrefix', p.PreservePrefix, ...
    'ExcludeFields', {}, 'Fields', {});
fMap = mergeBaseTags(fMap, p.BaseMap);
[fMap, fields, excluded, canceled] = extractSelectedFields(p, EEG, ...
    fMap);

if p.UseGui && ~canceled
    [fMap, canceled] = editmaps(fMap, 'EditXml', p.EditXml, ...
        'PreservePrefix', p.PreservePrefix, 'ExcludedFields', ...
        excluded, 'Fields', fields);
end

if ~canceled
    EEG = write2EEG(EEG, fMap, p.SaveMapFile, p.PreservePrefix);
    fprintf('Tagging complete\n');
    return;
end
fprintf('Tagging was canceled\n');

    function [fMap, fields, excluded, canceled] = ...
            extractSelectedFields(p, EEG, fMap)
        % Extract the selected fields from the fMap
        if ~p.UseGui
            p.SelectFields = false;
        end
        excluded = intersect(p.ExcludeFields, fieldnames(EEG.event));
        [fMap, fields, excluded, canceled] = selectmaps(fMap, ...
            'ExcludeFields', excluded, 'Fields', p.Fields, ...
            'PrimaryField', p.PrimaryField, 'SelectFields', ...
            p.SelectFields);
    end % extractSelectedFields

    function EEG = write2EEG(EEG, fMap, saveMapFile, preservePrefix)
        % Writes the tags to the EEG dataset structure  
        if ~isempty(saveMapFile) && ...
                ~fieldMap.saveFieldMap(saveMapFile, fMap)
            warning('tageeg:invalidFile', ...
                ['Couldn''t save fieldMap to ' saveMapFile]);
        end
        % Now finish writing the tags to the EEG structure
        EEG = writetags(EEG, fMap, 'PreservePrefix', preservePrefix);
    end % write2EEG

    function fMap = mergeBaseTags(fMap, baseMap)
        % Merge baseMap and fMap tags
        if isa(baseMap, 'fieldMap')
            baseTags = baseMap;
        else
            baseTags = fieldMap.loadFieldMap(baseMap);
        end
        fMap.merge(baseTags, 'Update', {}, fMap.getFields());
    end % mergeBaseTags

    function p = parseArguments(EEG, varargin)
        % Parses the input arguments and returns the results
        parser = inputParser;
        parser.addRequired('EEG', @(x) (isempty(x) || isstruct(EEG)));
        parser.addParamValue('BaseMap', '', ...
            @(x)(isempty(x) || ischar(x) || isa(x, 'fieldMap')));
        parser.addParamValue('EditXml', false, @islogical);
        parser.addParamValue('ExcludeFields', ...
            {'latency', 'epoch', 'urevent', 'hedtags', 'usertags'}, ...
            @(x) (iscellstr(x)));
        parser.addParamValue('Fields', {}, @(x) (iscellstr(x)));
        parser.addParamValue('PreservePrefix', false, @islogical);
        parser.addParamValue('PrimaryField', 'type', @(x) ...
            (isempty(x) || ischar(x)))
        parser.addParamValue('SaveMapFile', '', @(x)(isempty(x) || ...
            (ischar(x))));
        parser.addParamValue('SelectFields', true, @islogical);
        parser.addParamValue('UseGui', true, @islogical);
        parser.parse(EEG, varargin{:});
        p = parser.Results;
    end % parseArguments

end % tageeg