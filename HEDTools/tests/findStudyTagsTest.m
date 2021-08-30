function tests = findStudyTagsTest
tests = functiontests(localfunctions);
end % tagstudyTest

function setupOnce(testCase)
setup_tests;
end

function test_Empty(testCase)
[testCase.TestData.STUDY, testCase.TestData.ALLEEG] = pop_loadstudy('filepath', fullfile(testCase.TestData.testroot, testCase.TestData.studydir), 'filename', testCase.TestData.studyname);
% Unit test for findStudyTags function with no existing tags
fprintf('\nUnit tests for findStudyTags for untagged study\n');
dTags = findStudyTags(testCase.TestData.STUDY, testCase.TestData.ALLEEG);
events = dTags.getMaps();
% value: chan, description, duration, points. categorical: type
testCase.verifyEqual(length(events), 5);
testCase.verifyTrue(~isempty(dTags.getXml()));
fields = dTags.getFields();
testCase.verifyEqual(length(fields), 5);
testCase.verifyTrue(strcmpi(fields{1}, 'chan'));
fieldTagMap = events{1}.getStruct();
testCase.verifyEqual(length(fieldTagMap.values),1);
testCase.verifyEqual(fieldTagMap.values.code,'HED');
testCase.verifyTrue(strcmpi(fields{5}, 'type'));
fieldTagMap = events{5}.getStruct();
testCase.verifyEqual(length(fieldTagMap.values),11);
end

function test_recoverTagging(testCase)  
fprintf('\nUnit tests for findStudyTags when input STUDY is already tagged\n');
[testCase.TestData.STUDY, testCase.TestData.ALLEEG] = pop_loadstudy('filepath', fullfile(testCase.TestData.testroot, testCase.TestData.taggedstudydir), 'filename', testCase.TestData.taggedstudyname);
dTags = findStudyTags(testCase.TestData.STUDY, testCase.TestData.ALLEEG);
events = dTags.getMaps();
testCase.verifyEqual(length(events), 14);
end