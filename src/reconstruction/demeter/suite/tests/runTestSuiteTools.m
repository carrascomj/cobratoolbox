function testResultsFolder = runTestSuiteTools(refinedFolder, varargin)
% This function initialzes the test suite on all reconstructions in
% that should be refined through the semi-automatic refinement pipeline.
%
% USAGE:
%
%    testResultsFolder = runTestSuiteTools(refinedFolder, varargin)
%
%
% REQUIRED INPUTS
% refinedFolder             Folder with refined COBRA models generated by the
%                           refinement pipeline
% OPTIONAL INPUTS
% testResultsFolder         Folder where the test results are saved
% infoFilePath              File with information on reconstructions to refine
%                           (default: AGORA2_infoFile.xlsx)
% inputDataFolder           Folder with experimental data and database files to
%                           load (default: semiautomaticrefinement/input)
% reconVersion              Name of the refined reconstruction resource
%                           (default: "Reconstructions")
% numWorkers                Number of workers in parallel pool (default: 2)
% createReports             Boolean defining if a report for each
%                           reconstruction should be created (default: false).
% reportsFolder             Folder where reports should be saved
% translatedDraftsFolder    Folder with  translated draft COBRA models generated by KBase
%                           pipeline to analyze (will only be analyzed if
%                           folder is provided)
% OUTPUT
% testResultsFolder         Folder where the test results are saved
%
% .. Authors:
%       - Almut Heinken, 09/2020

% Define default input parameters if not specified
parser = inputParser();
parser.addRequired('refinedFolder', @ischar);
parser.addParameter('testResultsFolder', [pwd filesep 'TestResults']', @ischar);
parser.addParameter('infoFilePath', 'AGORA2_infoFile.xlsx', @ischar);
parser.addParameter('inputDataFolder', '', @ischar);
parser.addParameter('numWorkers', 2, @isnumeric);
parser.addParameter('reconVersion', 'Reconstructions', @ischar);
parser.addParameter('createReports', false, @islogical);
parser.addParameter('reportsFolder', '', @ischar);
parser.addParameter('translatedDraftsFolder', '', @ischar);

parser.parse(refinedFolder, varargin{:});

refinedFolder = parser.Results.refinedFolder;
testResultsFolder = parser.Results.testResultsFolder;
infoFilePath = parser.Results.infoFilePath;
inputDataFolder = parser.Results.inputDataFolder;
numWorkers = parser.Results.numWorkers;
reconVersion = parser.Results.reconVersion;
createReports = parser.Results.createReports;
reportsFolder = parser.Results.reportsFolder;
translatedDraftsFolder = parser.Results.translatedDraftsFolder;

mkdir(testResultsFolder)

currentDir=pwd;
cd(inputDataFolder)

if ~isempty(translatedDraftsFolder)
    % Draft reconstructions
    mkdir([testResultsFolder filesep reconVersion '_draft'])
    testAllReconstructionFunctions(translatedDraftsFolder,[testResultsFolder filesep reconVersion '_draft'],reconVersion,numWorkers);   plotTestSuiteResults([testResultsFolder filesep reconVersion '_draft'],reconVersion);
end

% Refined reconstructions
mkdir([testResultsFolder filesep reconVersion '_refined'])
testAllReconstructionFunctions(refinedFolder,[testResultsFolder filesep reconVersion '_refined'],reconVersion,numWorkers);
plotTestSuiteResults([testResultsFolder filesep reconVersion '_refined'],reconVersion);
% prepare a report and highlight debugging efforts still needed
% printRefinementReport(testResultsFolder,reconVersion)

% Give an individual report of each reconstruction if desired.
% Note: this is time-consuming.
% Requires LaTeX and pdflatex installation (e.g., MiKTex package)

% automatically create reports if there are less than ten organisms
dInfo = dir(refinedFolder);
modelList={dInfo.name};
modelList=modelList';
modelList(~contains(modelList(:,1),'.mat'),:)=[];

if size(modelList) < 10
    createReports=true;
end

if createReports
    
    if isempty(reportsFolder)
        cd(currentDir)
        mkdir([currentDir filesep 'modelReports'])
        reportsFolder=[currentDir filesep 'modelReports' filesep];
    end
    
    cd(reportsFolder)
    if ~isempty(infoFilePath)
        infoFile = readtable(infoFilePath, 'ReadVariableNames', false);
        infoFile = table2cell(infoFile);
        
        dInfo = dir(refinedFolder);
        modelList={dInfo.name};
        modelList=modelList';
        modelList(~contains(modelList(:,1),'.mat'),:)=[];
        
        ncbiCol=find(strcmp(infoFile(1,:),'NCBI Taxonomy ID'));
        if isempty(ncbiCol)
            warning('No NCBI Taxonomy IDs provided. This section in the report will be skipped.')
        end
        
        for i = 1:length(modelList)
            model=readCbModel([refinedFolder filesep modelList{i}]);
            biomassReaction = model.rxns{strncmp('bio', model.rxns, 3)};
            if ~isempty(ncbiCol)
                ncbiID = infoFile(find(strcmp(infoFile(:,1),strrep(modelList{i},'.mat',''))),ncbiCol);
            else
                ncbiID='';
            end
            [outputFile] = reportPDF(model, strrep(modelList{i},'.mat',''), biomassReaction, reportsFolder, ncbiID);
        end
    else
        warning('No organism information provided. Report generation skipped.')
    end
end

cd(currentDir)

end
