function tests = findtagsTest
tests = functiontests(localfunctions);
end % findEEGHedEventsTest

function setupOnce(testCase)
setup_tests;
latestHed = 'HED.xml';
testCase.TestData.xml = fileread(latestHed);
s1(1) = tagList('square');
s1(1).add({'/Attribute/Visual/Color/Green', ...
    '/Item/2D shape/Rectangle/Square'});
s1(2) = tagList('rt');
s1(2).add('/Event/Category/Participant response');
s2(1) = tagList('1');
s2(1).add('/Attribute/Object orientation/Rotated/Degrees/3 degrees');
s2(2) = tagList('2');
s2(2).add('/Attribute/Object orientation/Rotated/Degrees/1.5 degrees');
testCase.TestData.map1 = fieldMap('XML', testCase.TestData.xml);
testCase.TestData.map1.addValues('type', s1);
testCase.TestData.map2 = fieldMap('XML', testCase.TestData.xml);
testCase.TestData.map2.addValues('position', s2);
testCase.TestData.noTagsFile = 'EEGEpoch.mat';
testCase.TestData.oneTagsFile = 'fMapOne.mat';
testCase.TestData.otherTagsFile = 'fMapTwo.mat';
% testCase.TestData.xmlSchema = fileread('HED Schema 2.026.xsd');
testCase.TestData.data.etc.tags.xml = fileread(latestHed);
testCase.TestData.data.etc.tags = testCase.TestData.map1.getStruct();
end

function testValidValues(testCase)  
% Unit test for findtags
fprintf('\nUnit tests for findtags\n');
% fprintf('It should work if EEG has an empty .etc field\n');
% EEG1 = rmfield(EEG1, 'etc');
% EEG2 = testCase.TestData.EEGEpoch;
% EEG2.etc = '';
% dTags2 = findtags(EEG2);
% events2 = dTags2.getMaps();
% testCase.verifyEqual(length(events2), 2);
% testCase.verifyTrue(~isempty(dTags2.getXml()));
% fprintf('It should work if EEG has a non-structure .etc field\n');
% EEG3 = testCase.TestData.EEGEpoch;
% EEG3.etc = 'This is a test';
% dTags3 = findtags(EEG3);
% events3 = dTags3.getMaps();
% testCase.verifyEqual(length(events3), 2);
% testCase.verifyTrue(~isempty(dTags3.getXml()));
% fprintf('It should work if the EEG has already been tagged\n');
% dTags4 = findtags(testCase.TestData.data);
% events4 = dTags4.getMaps();
% testCase.verifyEqual(length(events4), 1);
% testCase.verifyTrue(~isempty(dTags4.getXml()));
% fields4 = dTags4.getFields();
% testCase.verifyEqual(length(fields4), 1);
% testCase.verifyTrue(strcmpi(fields4{1}, 'type'));
% 
% fprintf('It should tag a data set that has a map but no events\n');
% dTags = findtags(testCase.TestData.data);
% testCase.verifyTrue(isa(dTags, 'fieldMap'));
% fields = dTags.getFields();
% testCase.verifyEqual(length(fields), 1);
% for k = 1:length(fields)
%     testCase.verifyTrue(isa(dTags.getMap(fields{k}), 'tagMap'));
% end

end

function testRecoverTagging(testCase)
fprintf('When EEG has .etc.tags, create corresponding fMap\n');
dTags = findtags(testCase.TestData.EEGtagged);
events = dTags.getMaps();
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

% function testMultipleFields(testCase)  
% % Unit test for findtags
% fprintf('\nUnit tests for findtags with multiple field combinations\n');
% fprintf('It should tag when the epoch field is not excluded\n');
% testCase.verifyTrue(~isfield(testCase.TestData.EEGEpoch.etc, 'tags'));
% dTags = findtags(testCase.TestData.EEGEpoch, 'EventFieldsToIgnore', {'latency', 'urevent'});
% values1 = dTags.getMaps();
% testCase.verifyEqual(length(values1), 3);
% e1 = values1{1}.getStruct();
% testCase.verifyTrue(strcmpi(e1.field, 'epoch'));
% testCase.verifyEqual(length(e1.values), 80);
% e2 = values1{2}.getStruct();
% testCase.verifyTrue(strcmpi(e2.field, 'position'));
% testCase.verifyEqual(length(e2.values), 2);
% e3 = values1{3}.getStruct();
% testCase.verifyTrue(strcmpi(e3.field, 'type'));
% testCase.verifyEqual(length(e3.values), 2);
% end

function testEmpty(testCase)  
% Unit test for findtags
% It should return a tag map for an EEG structure that
% hasn''t been tagged (no etc.tags and no HED column)
% verify the EEG doesn't contain etc.tags
testCase.verifyTrue(~isfield(testCase.TestData.EEG.etc, 'tags'));
% categorical field selection window should show up
dTags = findtags(testCase.TestData.EEG);
fprintf(['If both are categorical \n']);
% if no modification, there will be two categorical fields 'position' and 'type', 
% each containing two field levels, in the returned fMap
events = dTags.getMaps();
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

fprintf(['If one field is value field \n']);
% only type is selected, 'position' will have one field level 'HED' in the returned fMap
dTags = findtags(testCase.TestData.EEG);
events = dTags.getMaps();
fieldTagMap = events{1}.getStruct();
testCase.verifyTrue(strcmpi(fieldTagMap.field, 'position'));
testCase.verifyEqual(length(fieldTagMap.values),1);
testCase.verifyEqual(fieldTagMap.values.code, 'HED');
fieldTagMap = events{2}.getStruct();
testCase.verifyEqual(length(fieldTagMap.values),2);
end

% function testFindTags(testCase)
% % Unit test for fieldMap getTags method
% fprintf('\nUnit tests for fieldMap getTags method\n');
% fprintf('It should get the right tags for fields that exist \n');
% fMap = findtags(testCase.TestData.data);
% tags1 = fMap.getTags('type', 'square');
% testCase.verifyEqual(length(tags1{1}), 2);
% end
