
% eegplugin_hedtools makes a HEDTools plugin for EEGLAB
%
% Usage:
%   >> eegplugin_hedtools(fig, trystrs, catchstrs)
%
%% Description
% eegplugin_hedtools(fig, trystrs, catchstrs) makes a HEDTools
%    plugin for EEGLAB. The plugin automatically
%    extracts the items and the current tagging structure from the
%    current EEG structure in EEGLAB.
%
%    The fig, trystrs, and catchstrs arguments follow the
%    convention for plugins to EEGLAB. The fig argument holds the figure
%    number of the main EEGLAB GUI. The trystrs and catchstrs arguments
%    hold the try and catch strings for EEGLAB menu callbacks.
%
% Place the HEDTools folder in the |plugins| subdirectory of EEGLAB.
% EEGLAB should detect the plugin on start up.
%
%
% See also: eeglab
%
% Copyright (C) 2012-2013 
% Jeremy Cockfield, UTSA, jeremy.cockfield@gmail.com
% Kay Robbins, UTSA, kay.robbins@utsa.edu
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
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1.07  USA

function vers = eegplugin_hedtools(fig, trystrs, catchstrs)
vers = 'HEDTools3.3.2';
% Check the number of input argumentsedit 
if nargin < 3
    error('eegplugin_hedtools requires 3 arguments');
end

% Find the path of the current directory
addhedpaths(true);

% Find 'Memory and other options' in the figure 
parentMenu = findobj(fig, 'Label', 'Edit', 'Type', 'uimenu');
positionMenu = findobj(fig, 'Label', 'Event values', 'Type', 'uimenu');
% if isempty(positionMenu)
%     positionMenu = findobj(fig, 'Label', 'Memory and other options', 'Type', 'uimenu');
% end
position = get(positionMenu, 'Position') + 1;

%% Adding HEDTools submenu items to 'File'. Order of insertion in script is opposite to order of appearance in 'File' menu
%% Add validation submenu to 'Edit'            
callbackCmd = [trystrs.no_check ...
                'if exist(''STUDY'',''var'') && exist(''CURRENTSTUDY'',''var'') && length(EEG) > 1 && CURRENTSTUDY == 1, ' ...
                    '[~, LASTCOM] = pop_validatestudy(STUDY, EEG);' ...
                'else ' ...
                    '[~, LASTCOM] = pop_validateeeg(EEG);' ...
                'end;' ...
                catchstrs.add_to_hist];
            
uimenu(parentMenu, 'Label', 'Validate event HED tags', ...
    'Separator', 'off', 'Position', position, 'userdata', 'startup:off;study:on', 'Callback', callbackCmd);


%% Add Tagging submenu to 'Edit'
callbackCmd = [trystrs.no_check ...
                'if exist(''STUDY'',''var'') && exist(''CURRENTSTUDY'',''var'') && length(EEG) > 1 && CURRENTSTUDY == 1, ' ...
                    '[STUDY, EEG, fMap, LASTCOM] = pop_tagstudy(STUDY, EEG);' ...
                'else ' ...
                    '[EEG, fMap, LASTCOM] = pop_tageeg(EEG);' ...
                    'if ~isempty(LASTCOM) && ~isempty(EEG.event),' ...
                        '[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET);' ...
                        'eeglab redraw;' ...
                    'end;' ...
                'end;' ...
                catchstrs.add_to_hist];
uimenu(parentMenu, 'Label', 'Add/Edit event HED tags', ...
    'Separator', 'off', 'Position', position, 'userdata', 'startup:off;study:on', 'Callback', callbackCmd);
%% Add Clear tagging submenu to 'Edit'
callbackCmd = [trystrs.no_check ...
                'if exist(''STUDY'',''var'') && exist(''CURRENTSTUDY'',''var'') && length(EEG) > 1 && CURRENTSTUDY == 1, ' ...
                    '[STUDY, EEG, fMap] = removeTagsSTUDY(STUDY, EEG);' ...
                'else ' ...
                    '[EEG, fMap] = removeTagsEEG(EEG);' ...
                    'if ~isempty(EEG.event),' ...
                        '[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET);' ...
                        'eeglab redraw;' ...
                    'end;' ...
                'end;' ...
                catchstrs.add_to_hist];
uimenu(parentMenu, 'Label', 'Clear HED tags', ...
    'Separator', 'off', 'Position', position, 'userdata', 'startup:off;study:on', 'Callback', callbackCmd);
% Find 'Remove baseline' in the figure 
parentMenu = findobj(fig, 'Label', 'Tools');
positionMenu = findobj(fig, 'Label', 'Remove epoch baseline', 'Type', 'uimenu');
if isempty(positionMenu)
    positionMenu = findobj(fig, 'Label', 'Remove baseline', 'Type', 'uimenu');
end
position = get(positionMenu, 'Position');

% Processing for 'Extract epochs by tags'
finalcmd = '[EEG, ~, LASTCOM] = pop_epochhed(EEG);';
ifeegcmd = 'if ~isempty(LASTCOM) && ~isempty(EEG)';
savecmd = '[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET);';
redrawcmd = 'eeglab redraw;';
rmbasecmd = '[EEG, LASTCOM] = pop_rmbase(EEG);';
finalcmd =  [trystrs.no_check finalcmd ifeegcmd savecmd ...
    redrawcmd 'end;' rmbasecmd ifeegcmd savecmd redrawcmd ...
    'end;' catchstrs.add_to_hist];

% Add 'Extract epochs by tags' to 'Tools'
uimenu(parentMenu, 'Label', 'Extract epochs by tags', ...
    'Position', position, 'userdata', 'startup:off;study:off', 'Callback', finalcmd);

end
