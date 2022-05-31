function [debuggingReport, fixedModels, failedModels]=runDebuggingTools(refinedFolder,testResultsFolder,inputDataFolder,infoFilePath,reconVersion,varargin)
% This function runs a suite of debugging functions on a set of refined
% reconstructions produced by the DEMETER pipeline. Tests are performed
% whether or not the models can produce biomass aerobically and 
% anaerobically, and whether or not unrealistically high ATP is produced
% on the complex medium.
%
% USAGE
%       [debuggingReport, fixedModels, failedModels]=runDebuggingTools(refinedFolder,testResultsFolder,inputDataFolder,infoFilePath,reconVersion,varargin)
%
% INPUTS
% refinedFolder          Folder with refined COBRA models generated by
%                        the refinement pipeline
% testResultsFolder      Folder where the test results are saved
% inputDataFolder        Folder with experimental data and database files
% infoFilePath           File with information on reconstructions to refine
% reconVersion           Name of the refined reconstruction resource
%
% OPTIONAL INPUTS
% numWorkers             Number of workers in parallel pool (default: 2)
% translatedDraftsFolder Folder with  translated draft COBRA models 
%                        generated by KBase pipeline to analyze (will only 
%                        be re-analyzed if folder is provided)
%
% OUTPUT
% debuggingReport         Report of changes that where made to debug the
%                         models, if any
% fixedModels             IDs of models that passed tests after additional
%                         gap-filling
% failedModels            IDs of models that still do not pass one or more
%                         tests
%
% .. Author:
%       - Almut Heinken, 09/2020

% Define default input parameters if not specified
parser = inputParser();
parser.addRequired('refinedFolder', @ischar);
parser.addRequired('testResultsFolder', @ischar);
parser.addRequired('inputDataFolder', @ischar);
parser.addRequired('infoFilePath', @ischar);
parser.addRequired('reconVersion', @ischar);
parser.addParameter('numWorkers', 2, @isnumeric);
parser.addParameter('translatedDraftsFolder', '', @ischar);

parser.parse(refinedFolder,testResultsFolder,inputDataFolder,infoFilePath,reconVersion,varargin{:});
refinedFolder = parser.Results.refinedFolder;
testResultsFolder = parser.Results.testResultsFolder;
inputDataFolder = parser.Results.inputDataFolder;
infoFilePath = parser.Results.infoFilePath;
reconVersion = parser.Results.reconVersion;
numWorkers = parser.Results.numWorkers;
translatedDraftsFolder = parser.Results.translatedDraftsFolder;

%% initialize COBRA Toolbox and parallel pool
global CBT_LP_SOLVER
if isempty(CBT_LP_SOLVER)
    initCobraToolbox
end
solver = CBT_LP_SOLVER;

if numWorkers>0 && ~isempty(ver('parallel'))
    % with parallelization
    poolobj = gcp('nocreate');
    if isempty(poolobj)
        parpool(numWorkers)
    end
end
environment = getEnvironment();

if isfile([testResultsFolder filesep 'failedModels.mat'])
    load([testResultsFolder filesep 'failedModels.mat']);
else
    % get all models that failed at least one test
    failedModels = {};
end
fixedModels = {};

% start from existing progress if available
if isfile([testResultsFolder filesep 'debuggingReport.mat'])
    load([testResultsFolder filesep 'debuggingReport.mat'])
    cnt=size(debuggingReport,1)+1;
else
    debuggingReport = {};
    cnt=1;
end

if isfile([testResultsFolder filesep 'notGrowing.mat'])
    load([testResultsFolder filesep 'notGrowing.mat']);
    failedModels = union(failedModels,notGrowing);
end
if isfile([testResultsFolder filesep 'tooHighATP.mat'])
    load([testResultsFolder filesep 'tooHighATP.mat']);
    failedModels = union(failedModels,tooHighATP);
end
if isfile([testResultsFolder filesep reconVersion '_refined' filesep 'growsOnDefinedMedium_' reconVersion '.txt'])
    FNlist = readInputTableForPipeline([testResultsFolder filesep reconVersion '_refined' filesep 'growsOnDefinedMedium_' reconVersion '.txt']);
    for i=1:size(FNlist,1)
        if isnumeric(FNlist{i,2})
            FNlist{i,2}=num2str(FNlist{i,2});
        end
    end
    failedModels=union(failedModels,FNlist(find(strcmp(FNlist(:,2),'0')),1));
end

% load all test result files for experimental data
dInfo = dir([testResultsFolder filesep reconVersion '_refined']);
fileList={dInfo.name};
fileList=fileList';
fileList(~(contains(fileList(:,1),{'.txt'})),:)=[];
fileList(~(contains(fileList(:,1),{'FalseNegatives'})),:)=[];

for i=1:size(fileList,1)
    FNlist = readInputTableForPipeline([[testResultsFolder filesep reconVersion '_refined'] filesep fileList{i,1}]);
    % remove all rows with no cases
    FNlist(cellfun(@isempty, FNlist(:,2)),:)=[];
    failedModels=union(failedModels,FNlist(:,1));
end

% get already debugged reconstructions
dInfo = dir([testResultsFolder filesep 'RevisedModels']);
modelList={dInfo.name};
modelList=modelList';
if size(modelList,1)>0
    modelList(~contains(modelList(:,1),'.mat'),:)=[];
    modelList(:,1)=strrep(modelList(:,1),'.mat','');
    
    % remove models that were already debugged
    [C,IA]=intersect(failedModels(:,1),modelList(:,1));
    if ~isempty(C)
        failedModels(IA,:)=[];
    end
end

% perform debugging tools for each model for which additional curation is
% needed
if length(failedModels)>0

    % define the intervals in which the testing and regular saving will be
    % performed
    if length(failedModels)>200
        steps=100;
    else
        steps=25;
    end

    for i=1:steps:length(failedModels)
        if length(failedModels)-i>=steps-1
            endPnt=steps-1;
        else
            endPnt=length(failedModels)-i;
        end

        gapfilledReactionsTmp = {};
        replacedReactionsTmp = {};
        revisedModelTmp = {};
        parfor j=i:i+endPnt
            restoreEnvironment(environment);
            changeCobraSolver(solver, 'LP', 0, -1);
            try
                model=readCbModel([refinedFolder filesep failedModels{j,1} '.mat']);
            catch
                L=load([refinedFolder filesep failedModels{j,1} '.mat']);
                model = L.model;
            end
            biomassReaction=model.rxns{find(strncmp(model.rxns(:,1),'bio',3)),1};

            % load the relevant test results
            fields = {
                'Carbon_sources_FalseNegatives'
                'Fermentation_products_FalseNegatives'
                'Metabolite_uptake_FalseNegatives'
                'Secretion_products_FalseNegatives'
                'Bile_acid_biosynthesis_FalseNegatives'
                'Drug_metabolism_FalseNegatives'
                };

            Results=struct;

            for k=1:length(fields)
                if isfile([testResultsFolder filesep reconVersion '_refined' filesep fields{k} '_' reconVersion '.txt'])
                    savedResults = readInputTableForPipeline([testResultsFolder filesep reconVersion '_refined' filesep fields{k} '_' reconVersion '.txt']);
                    Results.(fields{k}) = savedResults;
                else
                    Results.(fields{k})={};
                end
            end

            % run the gapfilling suite
            [revisedModel,gapfilledReactions,replacedReactions]=debugModel(model,Results,inputDataFolder,infoFilePath,failedModels{j,1},biomassReaction);
            gapfilledReactionsTmp{j} = gapfilledReactions;
            replacedReactionsTmp{j} = replacedReactions;
            revisedModelTmp{j} = revisedModel;
        end
        for j=i:i+endPnt
            % print the results of the debug gapfilling
            if ~isempty(replacedReactionsTmp{j})
                debuggingReport(cnt,1:size(replacedReactionsTmp{j},2))=replacedReactionsTmp{j};
                cnt=cnt+1;
            end
            if ~isempty(gapfilledReactionsTmp{j})
                for k=1:size(gapfilledReactionsTmp{j},1)
                    debuggingReport(cnt,1:size(gapfilledReactionsTmp{j},2))=gapfilledReactionsTmp{j}(k,:);
                    cnt=cnt+1;
                end
            end
            % save the revised model
            model = revisedModelTmp{j};
            try
                writeCbModel(model, 'format', 'mat', 'fileName', [refinedFolder filesep failedModels{j,1}]);
            catch
                save([refinedFolder filesep failedModels{j,1} '.mat'],'model');
            end
        end
        % regularly save the results
        save([testResultsFolder filesep reconVersion '_refined' filesep 'debuggingReport.mat'],'debuggingReport');
    end
    % run a retest of revised models
    delete([testResultsFolder filesep 'notGrowing.mat'])
    delete([testResultsFolder filesep 'tooHighATP.mat'])
    try
        rmdir([testResultsFolder filesep reconVersion '_refined'],'s')
    end
    if ~isempty(translatedDraftsFolder)
        % plot growth for both draft and refined
        notGrowing = plotBiomassTestResults(refinedFolder,reconVersion,'translatedDraftsFolder',translatedDraftsFolder,'testResultsFolder',testResultsFolder, 'numWorkers', numWorkers);

        % plot ATP production for both draft and refined
        tooHighATP = plotATPTestResults(refinedFolder,reconVersion,'translatedDraftsFolder',translatedDraftsFolder,'testResultsFolder',testResultsFolder, 'numWorkers', numWorkers);
    else
        % plot growth only for refined
        notGrowing = plotBiomassTestResults(refinedFolder,reconVersion,'testResultsFolder',testResultsFolder, 'numWorkers', numWorkers);

        % plot ATP production only for refined
        tooHighATP = plotATPTestResults(refinedFolder,reconVersion,'testResultsFolder',testResultsFolder, 'numWorkers', numWorkers);
    end
    mkdir([testResultsFolder filesep reconVersion '_refined'])
    batchTestAllReconstructionFunctions(refinedFolder,[testResultsFolder filesep reconVersion '_refined'],inputDataFolder,reconVersion,numWorkers);
    plotTestSuiteResults([testResultsFolder filesep reconVersion '_refined'],reconVersion);

    % get all models that still fail at least one test
    stillFailedModels = {};

    if isfile([[testResultsFolder filesep reconVersion '_refined'] filesep 'notGrowing.mat'])
        load([[testResultsFolder filesep reconVersion '_refined'] filesep 'notGrowing.mat']);
        stillFailedModels = union(stillFailedModels,notGrowing);
    end
    if isfile([[testResultsFolder filesep reconVersion '_refined'] filesep 'tooHighATP.mat'])
        load([[testResultsFolder filesep reconVersion '_refined'] filesep 'tooHighATP.mat']);
        stillFailedModels = union(stillFailedModels,tooHighATP);
    end
    if isfile([[testResultsFolder filesep reconVersion '_refined'] filesep 'growsOnDefinedMedium_' reconVersion '_refined.txt'])
        FNlist = table2cell(readtable([[testResultsFolder filesep reconVersion '_refined'] filesep reconVersion '_refined' filesep 'growsOnDefinedMedium_' reconVersion '_refined.txt'], 'ReadVariableNames', false, 'Delimiter', 'tab'));
        stillFailedModels=union(stillFailedModels,FNlist(find(strcmp(FNlist(:,2),'0')),1));
    end

    % load all test result files for experimental data
    dInfo = dir([testResultsFolder filesep reconVersion '_refined']);
    fileList={dInfo.name};
    fileList=fileList';
    fileList(~(contains(fileList(:,1),{'.txt'})),:)=[];
    fileList(~(contains(fileList(:,1),{'FalseNegatives'})),:)=[];

    for i=1:size(fileList,1)
        FNlist = readInputTableForPipeline([testResultsFolder filesep reconVersion '_refined' filesep fileList{i,1}]);
        % remove all rows with no cases
        FNlist(cellfun(@isempty, FNlist(:,2)),:)=[];
        stillFailedModels=union(stillFailedModels,FNlist(:,1));
    end

    fixedModels = setdiff(failedModels,stillFailedModels);
    failedModels = stillFailedModels;

    % save the final results of the debugging tools
    save([testResultsFolder filesep reconVersion '_refined' filesep 'debuggingReport.mat'],'debuggingReport');
    save([testResultsFolder filesep reconVersion '_refined' filesep 'fixedModels.mat'],'fixedModels');
    save([testResultsFolder filesep reconVersion '_refined' filesep 'failedModels.mat'],'failedModels');

    % write debugging report as text file
    writetable(cell2table(debuggingReport),[[testResultsFolder filesep reconVersion '_refined'] filesep 'DebuggingReport_' reconVersion],'FileType','text','WriteVariableNames',false,'Delimiter','tab');

else
    fprintf('All models passed all tests. Exiting debugging tools.\n')
end

end