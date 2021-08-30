%% This script is used to define locations of various test directories
%
% You will need to adjust these paths on your system.

%% Study test setup
% The testing of the studies assumes that you have downloaded the
% sample EEGLAB study which can be found at:
%    ftp://sccn.ucsd.edu/pub/5subjects_full.zip
%
testCase.TestData.testroot = fullfile(fileparts(which('pop_tageegTest')), 'TestData');
testCase.TestData.EEG = pop_loadset(fullfile(testCase.TestData.testroot, 'eeglab_data.set'));
testCase.TestData.EEGtagged = pop_loadset(fullfile(testCase.TestData.testroot, 'eeglab_data_tagged.set'));
testCase.TestData.studydir = '5subjects';
testCase.TestData.studyname = 'n400.study';
testCase.TestData.taggedstudydir = 'BIDS_P3';
testCase.TestData.taggedstudyname = 'BIDS_P3.study';
testCase.TestData.shooterdir = 'ShooterSet';
testCase.TestData.BCI2000dir = 'BCI2000Set';
testCase.TestData.Otherdir = 'Other';
testCase.TestData.EEGLAB = 'EEGLABSet';
testCase.TestData.efile1 = 'BCIT1.csv';
testCase.TestData.efile2 = 'BCIT2.csv';
testCase.TestData.efile3 = 'BCIT3.csv';
testCase.TestData.emptyfile = 'BCITempty.csv';
testCase.TestData.onerow = 'BCIT1Row.csv';
testCase.TestData.badfile = 'badfile';
testCase.TestData.dbfile = 'dbcreds.txt';