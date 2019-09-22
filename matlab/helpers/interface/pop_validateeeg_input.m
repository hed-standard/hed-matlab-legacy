% GUI for input needed to create inputs for pop_validateeeg.
%
% Usage:
%
%   >>  [canceled, generateWarnings, hedXML, outDir] = validateeeg_input()
%
%   >>  [canceled, generateWarnings, hedXML, outDir] = ...
%       validateeeg_input('key1', 'value1', ...)
%
% Input:
%
%   Optional:
%
%   'GenerateWarnings'
%                   True to include warnings in the log file in addition
%                   to errors. If false (default) only errors are included
%                   in the log file.
%
%   'HedXml'
%                   The full path to a HED XML file containing all of the
%                   tags. This by default will be the HED.xml file
%                   found in the hed directory.
%
%   'OutputFileDirectory'
%                   The directory where the validation output is written
%                   to. There will be a log file generated for each study
%                   dataset validated.
%
% Output:
%
%   canceled
%                   True if the GUI is canceled. False if otherwise.
%
%   generateWarnings
%                   True to include warnings in the log file in addition
%                   to errors. If false (default) only errors are included
%                   in the log file.
%
%   hedXML
%                   A XML file containing every single HED tag and its
%                   attributes. This by default will be the HED.xml file
%                   found in the hed directory.
%
%   outDir
%                   The directory where the validation output will be
%                   written to if the 'writeOutput' argument is set to
%                   true. There will be log file containing any issues that
%                   were found while validating the HED tags. If there were
%                   issues found then a replace file will be created in
%                   addition to the log file if an optional one isn't
%                   already provided. The default output directory will be
%                   the current directory.
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
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

function [canceled, generateWarnings, hedXML, outDir] = ...
    pop_validateeeg_input(varargin)
p = parseArguments(varargin{:});
hedXMLCtrl = '';
outDirCtrl = '';
canceled = true;
generateWarnings = p.GenerateWarnings;
hedXML = p.HedXml;
outDir = p.OutputFileDirectory;
title = 'Inputs for validating HED tags in a EEG .set dataset';
fig = createFigure(title);
addFigureComponents(fig);
movegui(fig);
uiwait(fig);

    function addBrowserComponents(browserPanel)
        % Adds components to the browser panel
        addBrowserLabels(browserPanel);
        addBrowserEditBoxes(browserPanel);
        addBrowserButtons(browserPanel);
    end % addBrowserComponents

    function addBrowserButtons(browserPanel)
        % Adds button components to the browser panel
        uicontrol('Parent', browserPanel, ...
            'string', 'Browse', ...
            'style', 'pushbutton', ...
            'TooltipString', 'Press to bring up file chooser', ...
            'Units', 'normalized',...
            'Callback', {@browseHedXMLCallback, ...
            'Browse for HED XML file'}, ...
            'Position', [0.775 .8 0.21 0.2]);
        uicontrol('Parent', browserPanel, ...
            'string', 'Browse', ...
            'style', 'pushbutton', ...
            'TooltipString', 'Press to bring up file chooser', ...
            'Units', 'normalized',...
            'Callback', {@browseOutputDirectoryCallback, ...
            'Browse for ouput directory'}, ...
            'Position', [0.775 .5 0.21 0.2]);
    end % addBrowserButtons

    function addBrowserEditBoxes(browserPanel)
        % Adds edit box components to the browser panel
        hedXMLCtrl = uicontrol('Parent', browserPanel, ...
            'Style', 'edit', ...
            'BackgroundColor', 'w', ...
            'HorizontalAlignment', 'Left', ...
            'Tag', 'HEDXMLEB', ...
            'String', hedXML, ...
            'TooltipString', 'The HED XML file.', ...
            'Units','normalized',...
            'Callback', {@hedEditBoxCallback}, ...
            'Position', [0.15 0.8 0.6 0.2]);
        outDirCtrl = uicontrol('Parent', browserPanel, ...
            'Style', 'edit', ...
            'BackgroundColor', 'w', ...
            'HorizontalAlignment', 'Left', ...
            'Tag', 'OutputDirEB', ...
            'String', outDir, ...
            'TooltipString', ['A directory where the validation output' ...
            ' is written to.'], ...
            'Units','normalized',...
            'Callback', {@outputDirectoryEditBoxCallback}, ...
            'Position', [0.15 0.5 0.6 0.2]);
    end % addBrowserEditBoxes

    function addBrowserLabels(browserPanel)
        % Adds label components to the browser panel
        uicontrol('Parent', browserPanel, ...
            'Style','text', ...
            'BackgroundColor',[.66,.76,1],...
            'ForegroundColor', [0 0 0.4],...
            'String', 'HED file', ...
            'Units','normalized',...
            'HorizontalAlignment', 'Left', ...
            'Position', [0.015 0.75 0.1 0.2]);
        uicontrol('parent', browserPanel, ...
            'BackgroundColor',[.66,.76,1],...
            'ForegroundColor', [0 0 0.4],...
            'Style', 'Text', ...
            'Units', 'normalized', ...
            'String', 'Output directory', ...
            'HorizontalAlignment', 'Left', ...
            'Position', [0.015 0.4 0.12 0.3]);
    end % addBrowserLabels

    function addFigureComponents(fig)
        % Adds components to the figure
        [browserPanel, optionPanel, sumissionPanel] = ...
            createPanels(fig);
        addBrowserComponents(browserPanel);
        addOptionComponents(optionPanel);
        addSubmissionComponents(fig, sumissionPanel);
    end % addFigureComponents

    function addOptionComponents(optionPanel)
        % Adds components to the option panel
        uicontrol('Parent', optionPanel, ...
            'Style', 'CheckBox', ...
            'BackgroundColor',[.66,.76,1],...
            'ForegroundColor', [0 0 0.4],...
            'String', 'Include warnings in log file', ...
            'Enable', 'on', ...
            'Tooltip', ['Check to include warnings in the log file in' ...
            ' addition to errors. If unchecked only errors are' ...
            ' included in the log file'], ...
            'Value', generateWarnings, ...
            'Units','normalized', ...
            'Callback', @genearteWarningsCallback, ...
            'Position', [0.1 0.4 0.8 0.3]);
    end % addOptionComponents

    function addSubmissionComponents(fig, submissionPanel)
        % Adds components to the submission panel
        uicontrol('Parent', submissionPanel, ...
            'Style', 'pushbutton', ...
            'String', 'Okay', ...
            'Enable', 'on', ...
            'Tooltip', 'Okay dataset tagging', ...
            'Units','normalized', ...
            'Callback', {@okayButtonCallback, fig}, ...
            'Position',[0.21 0.1 0.21 .5]);
        uicontrol('Parent', submissionPanel, ...
            'Style', 'pushbutton', ...
            'String', 'Cancel', ...
            'Enable', 'on', ...
            'Tooltip', 'Cancel dataset tagging', ...
            'Units','normalized', ...
            'Callback', {@cancelButtonCallback, fig}, ...
            'Position',[0.44 0.1 0.21 .5]);
        uicontrol('Parent', submissionPanel, ...
            'Style', 'pushbutton', ...
            'Tag', 'HelpButton', ...
            'String', 'Help', ...
            'Enable', 'on', ...
            'Tooltip', 'Help for dataset tagging', ...
            'Units', 'normalized', ...
            'Callback', @helpButtonCallback, ...
            'Position',[0.67 0.1 0.21 .5]);
    end % addSubmissionComponents

    function [browserPanel, optionPanel, sumissionPanel] = ...
            createPanels(fig)
        % Creates the panels in the figure
        browserPanel = uipanel(fig, ...
            'BorderType','none', ...
            'BackgroundColor',[.66,.76,1],...
            'ForegroundColor', [0 0 0.4],...
            'FontSize', 12,...
            'Position',[0 .575 1 .4]);
        optionPanel = uipanel(fig, ...
            'BackgroundColor',[.66,.76,1],...
            'ForegroundColor', [0 0 0.4],....
            'FontSize', 12,...
            'Title','Additional options', ...
            'Position',[0.15 0.3 0.6 0.2]);
        sumissionPanel = uipanel(fig, ...
            'BorderType','none', ...
            'BackgroundColor',[.66,.76,1],...
            'ForegroundColor', [0 0 0.4],...
            'FontSize', 12,...
            'Position', [0.37 .025 .7 .15]);
    end % createPanels

    function browseHedXMLCallback(src, eventdata, myTitle) %#ok<INUSL>
        % Callback for 'Browse' button that sets the 'HED' editbox
        [tFile, tPath] = uigetfile({'*.xml', 'XML files (*.xml)'}, ...
            myTitle);
        if tFile ~= 0
            hedXML = fullfile(tPath, tFile);
            set(findobj('Tag', 'HEDXMLEB'), 'String', hedXML);
        end
    end % browseHedXMLCallback

    function browseOutputDirectoryCallback(~, ~, myTitle)
        % Callback for browse button to set the output directory editbox
        startPath = get(findobj('Tag', 'OutputDirEB'), 'String');
        if isempty(startPath) || ~ischar(startPath) || ~isdir(startPath)
            startPath = pwd;
        end
        dName = uigetdir(startPath, myTitle);
        if dName ~=0
            set(findobj('Tag', 'OutputDirEB'), 'String', dName);
            outDir = dName;
        end
    end % browseOutputDirectoryCallback

    function cancelButtonCallback(~, ~, fig)
        % Callback for the cancel button
        canceled = true;
        close(fig);
    end % cancelButtonCallback

    function fig = createFigure(title)
        % Creates the figure with the given title
        fig = figure( ...
            'Color', [.66,.76,1], ...
            'MenuBar', 'none', ...
            'Name', title, ...
            'NextPlot', 'add', ...
            'NumberTitle','off', ...
            'Resize', 'on', ...
            'Tag', title, ...
            'Toolbar', 'none', ...
            'Visible', 'off', ...
            'WindowStyle', 'modal');
    end % createFigure

    function genearteWarningsCallback(src, ~)
        % Callback for generate warnings checkbox
        generateWarnings = get(src, 'Max') == get(src, 'Value');
    end % genearteWarningsCallback

    function hedEditBoxCallback(src, ~)
        % Callback for user directly editing the HED XML editbox
        xml = get(src, 'String');
        hedXML = xml;
    end % hedEditBoxCallback

    function helpButtonCallback(~, ~)
        % Callback for the okay button
        helpdlg(sprintf(['Validates the HED tags in a .set EEG dataset' ...
            ' against a HED schema. \n\n***Main Options***' ...
            ' \n\nHED file - A XML file containing every single' ...
            ' HED tag and its attributes. This by default will be' ...
            ' the HED.xml file found in the hed directory.' ...
            ' \n\nOutput directory - The directory where the output' ...
            ' files will be written to. There will be log file' ...
            ' containing any issues that were found while' ...
            ' validating the HED tags. If there were issues found then' ...
            ' a replace file will be created in addition to the' ...
            ' log file if an optional one isn''t already provided.' ...
            ' The default output directory will be the current' ...
            ' directory.\n\n***Additional Options***' ...
            ' \n\nInclude warnings in log file - Check to include' ...
            ' warnings in the log file in addition to errors. If' ...
            ' unchecked only errors are included in the log file.']), ...
            'Input Description')
    end % helpButtonCallback

    function okayButtonCallback(~, ~, fig)
        % Callback for the 'Okay' button
        if ~exist(get(hedXMLCtrl, 'String'), 'file')
            errordlg('HED file does not exist', 'Invalid Input', 'modal');
        elseif isempty(get(hedXMLCtrl, 'String'))
            errordlg('HED file is empty', 'Input required', 'modal');
        elseif isempty(get(outDirCtrl, 'String'))
            errordlg('Output directory is empty', 'Input required', ...
                'modal');
        else
            canceled = false;
            close(fig);
        end
    end % okayButtonCallback

    function p = parseArguments(varargin)
        % Parses the input arguments and returns the results
        parser = inputParser;
        parser.addParamValue('GenerateWarnings', false, ...
            @(x) validateattributes(x, {'logical'}, {}));
        parser.addParamValue('HedXml', which('hed.xml'), ...
            @(x) (~isempty(x) && ischar(x)));
        parser.addParamValue('OutputFileDirectory', pwd, @ischar);
        parser.parse(varargin{:});
        p = parser.Results;
    end % parseArguments

    function outputDirectoryEditBoxCallback(src, ~)
        % Callback for user directly editing the output directory edit box
        directory = get(src, 'String');
        if exist(directory, 'dir')
            outDir = directory;
        else
            errordlg(['Output directory is invalid. Setting the output' ...
                ' directory back to the previous directory.'], ...
                'Invalid output directory', 'modal');
            set(src, 'String', outDir);
        end
    end % outputDirectoryEditBoxCallback

end % pop_validateeeg_input