function tests = pop_tageegTest
tests = functiontests(localfunctions);
end % pop_tageegTest

function setupOnce(testCase)
setup_tests;
end

function test_noguitagging(testCase)
    % test using pop_tageeg with nogui option
    % no base map provided. Return skeleton fMap
    [EEG, fMap] = pop_tageeg(testCase.TestData.EEG);
    % result is similar to using findTags, but with etc.tags in EEG
    % structure
    events = fMap.getMaps();
    testCase.verifyEqual(length(events), 2);
    testCase.verifyTrue(~isempty(dTags.getXml()));
    fields = dTags.getFields();
    testCase.verifyEqual(length(fields), 2);
    testCase.verifyTrue(strcmpi(fields{1}, 'position'));
    testCase.verifyTrue(strcmpi(fields{2}, 'type'));
    fieldTagMap = events{1}.getStruct();
    testCase.verifyEqual(length(fieldTagMap.values),2);
    fieldTagMap = events{2}.getStruct();
    testCase.verifyEqual(length(fieldTagMap.values),2);
    
    testCase.verifyTrue(isfield(EEG.etc, 'tags'));
    events = EEG.etc.tags;
    testCase.verifyEqual(length(events), 2);
    testCase.verifyTrue(~isempty(dTags.getXml()));
    fields = dTags.getFields();
    testCase.verifyEqual(length(fields), 2);
    testCase.verifyTrue(strcmpi(fields{1}, 'position'));
    testCase.verifyTrue(strcmpi(fields{2}, 'type'));
    fieldTagMap = events{1}.getStruct();
    testCase.verifyEqual(length(fieldTagMap.values),2);
    fieldTagMap = events{2}.getStruct();
    testCase.verifyEqual(length(fieldTagMap.values),2);
end

function test_valid(testCase)
% Unit test for pop_tageeg
fprintf('Testing pop_tageeg....REQUIRES USER INPUT\n');
fprintf(['\nIt should not return anything when the cancel button' ...
    ' is pressed\n']);
fprintf('DO NOT CLICK OR SET ANYTHING\n');
fprintf('PRESS THE CANCEL BUTTON\n');
[EEG1, com] = pop_tageeg(testCase.TestData.EEGEpoch);
testCase.verifyTrue(~isfield(EEG1.etc, 'tags'));
testCase.verifyTrue(~isfield(EEG1.event(1), 'usertags'));
testCase.verifyTrue(isempty(com));

fprintf('\nIt should return a command when tagged\n');
fprintf('SET TO USE GUI\n');
fprintf('DO NOT CLICK OR SET ANYTHING\n');
fprintf('PRESS THE OKAY BUTTON\n');
fprintf('REMOVE ALL FIELDS FROM TAGGING\n');
fprintf('PRESS THE OKAY BUTTON\n');
[EEG1, com] = pop_tageeg(testCase.TestData.EEGEpoch);
testCase.verifyTrue(isfield(EEG1.etc, 'tags'));
testCase.verifyTrue(isfield(EEG1.event(1), 'usertags'));
testCase.verifyTrue(~isempty(com));
end