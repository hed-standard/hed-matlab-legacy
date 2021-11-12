% Allows a user to tag a study and its associated datasets using a GUI. 
% pop_tagstudy first brings up a GUI to allow the user to set parameters
% for the tagstudy function, and then calls tagstudy to consolidate the
% tags from all of the data files in the study. Depending on the arguments,
% tagstudy may bring up a menu to allow the user to choose which fields
% should be tagged. The tagstudy function may also bring up the CTAGGER GUI
% to allow users to edit the tags.
%
% Usage:
%
%   >>  [STUDY, EEG, fMap, com] = pop_tagstudy(STUDY, EEG, 'key1', value1 ...)
%
% Input:
%
%   Required:
%
%   STUDY
%                    An EEGLAB STUDY structure
%
%   EEG
%                    Structure array containing info of all datasets of a STUDY 
%
%   Optional (key/value):
%
%   'BaseMap'
%                    A fieldMap object or the name of a file that contains
%                    a fieldMap object to be used to initialize tag
%                    information.
%
%   'EventFieldsToIgnore'
%                    A one-dimensional cell array of field names in the
%                    .event substructure to ignore during the tagging
%                    process. By default the following subfields of the
%                    .event structure are ignored: .latency, .epoch,
%                    .urevent, .HED. The user can
%                    over-ride these tags using this name-value parameter.
%
%   'FMapDescription'
%                    The description of the fieldMap object. The
%                    description will show up in the .etc.tags.description
%                    field of any datasets tagged by this fieldMap.
%
%   'FMapSaveFile'
%                    A string representing the file name for saving the
%                    final, consolidated fieldMap object that results from
%                    the tagging process.
%
%   'HEDExtensionsAllowed'
%                    If true (default), the HED can be extended. If
%                    false, the HED can not be extended. The
%                    'ExtensionAnywhere argument determines where the HED
%                    can be extended if extension are allowed.
%
%
%   'HedXML'
%                    Full path to a HED XML file. The default is the
%                    HED.xml file in the hed directory.
%
%   'OverwriteDatasets'
%                    If true, write the the HED tags to the original
%                    datasets.
%
%   'OverwriteUserHed'
%                    If true, overwrite/create the 'HED_USER.xml' file with
%                    the HED from the fieldMap object. The
%                    'HED_USER.xml' file is made specifically for modifying
%                    the original 'HED.xml' file. This file will be written
%                    under the 'hed' directory.
%
%   'PreserveTagPrefixes'
%                    If false (default), tags for the same field value that
%                    share prefixes are combined and only the most specific
%                    is retained (e.g., /a/b/c and /a/b become just
%                    /a/b/c). If true, then all unique tags are retained.
%
%   'PrimaryEventField'
%                    The name of the primary field. Only one field can be
%                    the primary field. A primary field requires a label,
%                    category, and a description tag. The default is the
%                    .type field.
%
%   'SelectEventFields'
%                    If true (default), the user is presented with a
%                    GUI that allow users to select which fields to tag.
%
%   'SeparateUserHedFile'
%                    The full path and file name to write the HED from the
%                    fieldMap object to. This file is meant to be
%                    stored outside of the HEDTools.
%
%   'UseCTagger'
%                    If true (default), the CTAGGER GUI is used to edit
%                    field tags.
%
%   'WriteFMapToFile'
%                    If true, write the fieldMap object to the
%                    specified 'FMapSaveFile' file.
%
%   'WriteSeparateUserHedFile'
%                    If true, write the fieldMap object to the file
%                    specified by the 'SeparateUserHedFile' argument.
%
% Output:
%
%   STUDY
%                    
%   EEG
%                    Structure array containing all datasets of the STUDY
%                    with HED tags
%
%
%   fMap
%                    A fieldMap object that contains the tag map
%                    information
%
%   com
%                    String containing call to tagstudy with all
%                    parameters.
%
% Copyright (C) 2012-2019 Thomas Rognon tcrognon@gmail.com,
% Jeremy Cockfield jeremy.cockfield@gmail.com, and
% Kay Robbins kay.robbins@utsa.edu
% Dung Truong dutruong@ucsd.edu
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 
function [STUDY, EEG, fMap, com] = pop_tagstudy(STUDY, EEG, varargin)

if nargin < 1
    help pop_tagstudy;
    return;
end

fMap = '';
com = '';
p = parseArguments(varargin{:});

% Get input parameters
inputArgs = getkeyvalue({'BaseMap', 'HedXml', 'PreserveTagPrefixes', 'EventFieldsToIgnore'}, varargin{:}); 

% Call function with menu
fprintf('Begin tagging...\n');
if p.UseGui    
    % Create fMap from EEG.event of each EEG set in EEG.
    [fMap, canceled] = findStudyTags(STUDY, EEG);
    if canceled
        fprintf('Tagging was canceled\n');
        return;
    end
    % If a base map is provided, merge it with the fMap
    if isfield(p,'BaseMap')
        fMap = mergeBaseTags(fMap, p.BaseMap);
    end
    
    % Add annotation using CTagger
    [fMap, canceled] = useCTagger(fMap);
    
    if canceled
        fprintf('Tagging was canceled\n');
        return;
    end
    fprintf('Tagging complete\n');
    
    % Write tags to EEG
    fprintf('Saving tags... ');
    % Write tag map to STUDY
    STUDY = writetags(STUDY, fMap, 'WriteIndividualTags', false);
    % Write tag map to each dataset
    for k = 1:length(EEG)
	    EEG(k) = writetags(EEG(k), fMap, 'PreserveTagPrefixes', ...
           p.PreserveTagPrefixes, 'WriteIndividualTags', false);
    end
    fprintf('Done.\n');

    % Save HED if modified
    if fMap.getXmlEdited()
        savehedInputArgs = getkeyvalue({'OverwriteUserHed', ...
            'SeparateUserHedFile', 'WriteSeparateUserHedFile'}, ...
            varargin{:});
        [fMap, overwriteUserHed, separateUserHedFile, ...
            writeSeparateUserHedFile] = pop_savehed(fMap, ...
            savehedInputArgs{:});
        savehedOutputArgs = {'OverwriteUserHed', overwriteUserHed, ...
            'SeparateUserHedFile', separateUserHedFile, ...
            'WriteSeparateUserHedFile', writeSeparateUserHedFile};
        inputArgs = [inputArgs savehedOutputArgs];
    end

    % if there's bids-matlab-tools and if there's BIDS.eventInfoDesc in
    % STUDY then prompt user to update HED tags in there as well
    if isfield(STUDY,'BIDS') && isfield(STUDY.BIDS,'eInfoDesc') && isfield(STUDY.BIDS,'eInfo') && exist('pop_eventinfo', 'file') == 2
        uilist = { ...
            { 'Style', 'text', 'string', 'BIDS event information found in the STUDY', 'fontweight', 'bold'  }, ...
            { 'Style', 'text', 'string', 'Would you like to update it with HED?'}, ...
            };
        geometry = { [1] [1]};
        geomvert =   [1  1 ];
        [~,~,isOk,~] = inputgui( 'geometry', geometry, 'geomvert', geomvert, 'uilist', uilist, 'title', 'Warning');
        if isempty(isOk)
            disp('HED annotation not added to BIDS event info\n')
        else
            [EEG, STUDY,~] = pop_eventinfo(EEG,STUDY,'default');
            disp('HED annotation added to BIDS event info')
        end
    end
        
    saveheddatasetsOutputArgs = {'OverwriteDatasets', true};
    for i=1:length(EEG)
       pop_saveset(EEG(i), 'filename', EEG(i).filename, 'filepath', EEG(i).filepath); 
    end
    % Build command string
    inputArgs = [inputArgs saveheddatasetsOutputArgs];
else % Call function without menu  % nargin > 1 && ~p.UseGui
    inputArgs = getkeyvalue({'BaseMap', 'DoSubDirs', ...
        'EventFieldsToIgnore', 'HedXml', 'PreserveTagPrefixes'}, ...
        varargin{:});
    fMap = tagstudy(EEG, inputArgs{:});
end

fprintf('Tagging completed.\n');
com = char(['pop_tagstudy(' logical2str(p.UseGui) ...
    ', ' keyvalue2str(inputArgs{:}) ');']);
 
%% Helper functions
    function fMap = mergeBaseTags(fMap, baseTags)
        % Merge baseMap and fMap tags
        if ~isa(baseTags, 'fieldMap')
            baseTags = fieldMap.loadFieldMap(baseTags);
        end
        fMap.merge(baseTags, 'Update', {}, {});
    end % mergeBaseTags

    function p = parseArguments(varargin)
        % Parses the input arguments and returns the results
        parser = inputParser;
        parser.addOptional('UseGui', true, @islogical);
        parser.addParamValue('BaseMap', '', @(x) isa(x, 'fieldMap') || ...
            ischar(x));
        parser.addParamValue('EventFieldsToIgnore', ...
            {'latency', 'epoch', 'urevent', 'HED'}, ...
            @iscellstr);
        parser.addParamValue('FMapDescription', '', @ischar);
        parser.addParamValue('FMapSaveFile', '', @(x)(isempty(x) || ...
            (ischar(x))));
        parser.addParamValue('HedExtensionsAllowed', true, @islogical);
        parser.addParamValue('HedXml', which('HED.xml'), @ischar);
        parser.addParamValue('OverwriteUserHed', '', @islogical);
        parser.addParamValue('OverwriteDatasets', false, @islogical);
        parser.addParamValue('PreserveTagPrefixes', false, @islogical);
        parser.addParamValue('PrimaryEventField', 'type', @(x) ...
            (isempty(x) || ischar(x)))
        parser.addParamValue('SelectEventFields', true, @islogical);
        parser.addParamValue('SeparateUserHedFile', '', @(x) ...
            (isempty(x) || (ischar(x))));
        parser.addParamValue('UseCTagger', true, @islogical);
        parser.addParamValue('WriteFMapToFile', false, @islogical);
        parser.addParamValue('WriteSeparateUserHedFile', false, ...
            @islogical);
        parser.parse(varargin{:});
        p = parser.Results;
    end % parseArguments
 
end % pop_tagstudy
