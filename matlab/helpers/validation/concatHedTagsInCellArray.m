% Concats the HED tags in a cell array of character vectors.
%
% Usage:
%
%   >>  tagPrefixMap = combineCellHedTags(specificColumns)

% Input:
%
%   Required:
%
%   hedTagArray
%                   A cell array of character vectors.
%
%   hedTagColumns
%                   A integer array containing the indices in the
%                   hedTagArray that contains HED tags.
%
% Output:
%
%   hedString
%                   A HED string consisting of the concatenated tags in the
%                   cell array of character vectors.
%
% Copyright (C) 2017
% Jeremy Cockfield jeremy.cockfield@gmail.com
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

function hedString = concatHedTagsInCellArray(hedTagArray, hedTagColumns)
parseInputArguments(hedTagArray, hedTagColumns);
nonEmptyTagIndices = hedTagColumns(ismember(hedTagColumns, ...
    find(~cellfun(@isempty, hedTagArray)))); 
hedString = strjoin(hedTagArray(nonEmptyTagIndices), ',');

    function parsedArguments = parseInputArguments(hedTagArray, ...
            hedTagColumns)
        % Parses the input arguments and returns them in a structure
        parser = inputParser();
        parser.addRequired('hedTagArray', @iscellstr);
        parser.addRequired('hedTagColumns', @isvector);
        parser.parse(hedTagArray, hedTagColumns);
        parsedArguments = parser.Results;
    end % parseInputArguments

end % concatHedTagsInCellArray

