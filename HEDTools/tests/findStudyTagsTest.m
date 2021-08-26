function tests = findStudyTagsTest
tests = functiontests(localfunctions);
end % tagstudyTest

function setupOnce(testCase)
setup_tests;
[testCase.TestData.STUDY, testCase.TestData.ALLEEG] = pop_loadstudy('filepath', fullfile(testCase.TestData.testroot, testCase.TestData.studydir), 'filename', testCase.TestData.studyname);
end

function test_Empty(testCase)
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

function test_tagValidStudy(testCase)  
% Unit test for tagstudy with a valid study directory
fprintf('\nUnit tests for tagstudy valid\n');

fprintf(['It should work for the EEGLAB study with both options and' ...
    ' GUI off\n']);
thisStudy = [testCase.TestData.testroot filesep testCase.TestData.studydir filesep ...
    testCase.TestData.studyname];
[fMap1, fPaths1] = tagstudy(thisStudy);
fields1 = fMap1.getFields();
testCase.verifyEqual(length(fields1), 5);
type1 = fMap1.getValues('type');
testCase.verifyEqual(length(type1), 11);
testCase.verifyEqual(length(fPaths1), 10);
end