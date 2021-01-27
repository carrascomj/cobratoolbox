function [TruePositives, FalseNegatives] = testDrugMetabolism(model, microbeID, biomassReaction)
% Performs an FVA and reports those drug metabolites (exchange reactions)
% that can be taken up and/or secreted by the model and should be secreted according to
% data (true positives) and those bile acid metabolites that cannot be secreted by
% the model but should be secreted according to in vitro data (false
% negatives).
%
% INPUT
% model             COBRA model structure
% microbeID         Microbe ID in carbon source data file
% biomassReaction   Biomass objective functions (low flux through BOF
%                   required in analysis)
%
% OUTPUT
% TruePositives     Cell array of strings listing all drug metabolites
%                   (exchange reactions) that can be taken up and/or secreted by the model
%                   and in in vitro data.
% FalseNegatives    Cell array of strings listing all drug metabolites
%                   (exchange reactions) that cannot be taken up and/or secreted by the model
%                   but should be secreted according to in vitro data.
%
% Almut Heinken, April 2020

global CBT_LP_SOLVER
if isempty(CBT_LP_SOLVER)
    initCobraToolbox
end
solver = CBT_LP_SOLVER;

fileDir = fileparts(which('ReactionTranslationTable.txt'));
metaboliteDatabase = readtable([fileDir filesep 'MetaboliteDatabase.txt'], 'Delimiter', 'tab','TreatAsEmpty',['UND. -60001','UND. -2011','UND. -62011'], 'ReadVariableNames', false);
metaboliteDatabase=table2cell(metaboliteDatabase);

% read drug metabolism table
drugTable = readtable('drugTable.txt', 'Delimiter', '\t');
drugExchanges = {'eALP','EX_r788(e)','EX_r406(e)','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','';'cALP','EX_r788(e)','EX_r406(e)','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','';'cAzNAD','EX_bzd(e)','EX_abz_ala_b(e)','EX_5asa(e)','EX_olsa(e)','EX_neopront(e)','EX_sanilamide(e)','EX_ssz(e)','EX_sulfp(e)','EX_tab(e)','EX_pront(e)','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','';'cAzNADP','EX_bzd(e)','EX_abz_ala_b(e)','EX_5asa(e)','EX_olsa(e)','EX_neopront(e)','EX_sanilamide(e)','EX_ssz(e)','EX_sulfp(e)','EX_tab(e)','EX_pront(e)','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','';'eBGal','EX_gal(e)','EX_fru(e)','EX_lactl(e)','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','';'cBGal','EX_lactl(e)','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','';'cBRV','EX_brv(e)','EX_srv(e)','EX_bvu(e)','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','';'cCda','EX_dfduri(e)','EX_dfdcytd(e)','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','';'eCda','EX_dfduri(e)','EX_dfdcytd(e)','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','';'cCgr','EX_digoxin(e)','EX_digitoxin(e)','EX_dihydro_digitoxin(e)','EX_dihydro_digoxin(e)','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','';'cCodA','EX_5fura(e)','EX_fcsn(e)','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','';'eCodA','EX_5fura(e)','EX_fcsn(e)','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','';'cDpdNAD','EX_dh5fura(e)','EX_5fura(e)','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','';'cDpdNADP','EX_dh5fura(e)','EX_5fura(e)','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','';'eDpdNADP','EX_dh5fura(e)','EX_5fura(e)','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','';'cHpd','EX_4hphac(e)','EX_pcresol(e)','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','';'TdcA','EX_34dhphe(e)','EX_dopa(e)','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','';'Dadh','EX_mtym(e)','EX_dopa(e)','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','';'cNAT','EX_5asa(e)','EX_isnzd(e)','EX_acisnzd(e)','EX_ac5asa(e)','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','';'eNAT','EX_5asa(e)','EX_isnzd(e)','EX_acisnzd(e)','EX_ac5asa(e)','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','';'eNit','EX_nzp(e)','EX_chlphncl(e)','EX_nchlphncl(e)','EX_7a_czp(e)','EX_anzp(e)','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','';'cNit','EX_nzp(e)','EX_chlphncl(e)','EX_nchlphncl(e)','EX_7a_czp(e)','EX_anzp(e)','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','','';'eUidA','EX_1hibup_S(e)','EX_1hibupglu_S(e)','EX_1hmdgluc(e)','EX_1ohmdz(e)','EX_2hatvacid(e)','EX_2hatvacidgluc(e)','EX_2hatvlac(e)','EX_2hatvlacgluc(e)','EX_2hibup_S(e)','EX_2hibupglu_S(e)','EX_2oh_cbz(e)','EX_2oh_cbz_glc(e)','EX_2oh_mtz(e)','EX_2oh_mtz_glc(e)','EX_3meacmp(e)','EX_3hibup_S(e)','EX_3hibupglu_S(e)','EX_3oh_cbz(e)','EX_3oh_cbz_glc(e)','EX_3oh_dlor(e)','EX_3oh_dlor_glc(e)','EX_3oh_mdea(e)','EX_3oh_mdea_glc(e)','EX_3oh_mxn(e)','EX_3oh_mxn_glc(e)','EX_4dh_tpno(e)','EX_4dh_tpno_1glc(e)','EX_4hmdgluc(e)','EX_4oh_dcf(e)','EX_4oh_dcf_glc(e)','EX_4oh_kp(e)','EX_4oh_kp_glc(e)','EX_4oh_levole(e)','EX_4oh_levole_glc(e)','EX_4oh_meth(e)','EX_4oh_meth_glc(e)','EX_4oh_propl(e)','EX_4oh_propl_glc(e)','EX_4oh_trz(e)','EX_4oh_trz_glc(e)','EX_4oh_vcz(e)','EX_4oh_vcz_glc(e)','EX_4ohmdz(e)','EX_5oh_sulfp(e)','EX_5oh_sulfp_glc(e)','EX_5ohfvs(e)','EX_5ohfvsglu(e)','EX_6bhglz(e)','EX_6bhglzglc(e)','EX_6ohfvs(e)','EX_6ohfvsglu(e)','EX_7bhglz(e)','EX_7bhglzglc(e)','EX_7oh_efv(e)','EX_7oh_efv_glc(e)','EX_814dioh_efv(e)','EX_814dioh_efv_glc(e)','EX_8oh_efv(e)','EX_8oh_efv_glc(e)','EX_ac_amn_b_gly(e)','EX_ac_amn_b_gly_glc(e)','EX_acmp(e)','EX_acmp_glc(e)','EX_acmpglu(e)','EX_alpz_4oh(e)','EX_alpz_4oh_glc(e)','EX_alpz_aoh(e)','EX_alpz_aoh_glc(e)','EX_am14(e)','EX_am14_glc(e)','EX_am1ccs(e)','EX_am1cglc(e)','EX_am5(e)','EX_am5_glc(e)','EX_am6(e)','EX_am6_glc(e)','EX_amio(e)','EX_amio_c(e)','EX_amio_c_glc(e)','EX_amio_glc(e)','EX_amn_b_gly(e)','EX_amn_b_gly_glc(e)','EX_amntd_m6(e)','EX_amntd_m6_glc(e)','EX_atvacid(e)','EX_atvacylgluc(e)','EX_atvethgluc(e)','EX_atvlac(e)','EX_atvlacgluc(e)','EX_bhpm(e)','EX_bhpm_glc(e)','EX_bilr_355(e)','EX_bilr_M10(e)','EX_bilr_M12(e)','EX_bilr_M14(e)','EX_bilr_M15(e)','EX_bilr_M16(e)','EX_bilr_M7(e)','EX_bsn(e)','EX_bsn_glc(e)','EX_bz(e)','EX_bz_glc(e)','EX_caribup_s(e)','EX_caribupglu_S(e)','EX_cbz(e)','EX_cbz_glc(e)','EX_cd6168(e)','EX_cd6168_glc(e)','EX_chlphncl(e)','EX_chlphncl_glc(e)','EX_clcxb(e)','EX_clcxb_c(e)','EX_clcxb_c_glc(e)','EX_clcxb_glc(e)','EX_clobi_c(e)','EX_clobi_glc(e)','EX_crvsm1(e)','EX_crvsm23(e)','EX_cvm1gluc(e)','EX_cvm23gluc(e)','EX_daa(e)','EX_daa_glc(e)','EX_dcf(e)','EX_dcf_glc(e)','EX_ddea(e)','EX_ddea_glc(e)','EX_des_astzl(e)','EX_des_astzl_glc(e)','EX_digoxin(e)','EX_digoxin_glc(e)','EX_dlb(e)','EX_dlb_glc(e)','EX_dnpz_5des(e)','EX_dnpz_6des(e)','EX_dnpz_m11(e)','EX_dnpz_m12(e)','EX_dnpz_m13(e)','EX_dnpz_m14(e)','EX_dnpz_m9(e)','EX_doh_etr(e)','EX_doh_etr_glc(e)','EX_doh_vcz(e)','EX_doh_vcz_glc(e)','EX_dxo(e)','EX_dxo_glc(e)','EX_efv(e)','EX_efv_glc(e)','EX_eltr(e)','EX_eltr_glc(e)','EX_eltr_m3(e)','EX_eltr_m4(e)','EX_eztmb(e)','EX_eztmb_glc(e)','EX_fvs(e)','EX_fvsgluc(e)','EX_fvstet(e)','EX_fvstetglu(e)','EX_glc3meacp(e)','EX_gltmn(e)','EX_gltmn_glc(e)','EX_gmfl(e)','EX_gmfl_glc(e)','EX_gmfl_mI(e)','EX_gmfl_mI_glc(e)','EX_gmfl_mII(e)','EX_gmfl_mII_glc(e)','EX_gmfl_mIII(e)','EX_gmfl_mIII_glc(e)','EX_gtacmp(e)','EX_hst(e)','EX_hst_3_glc(e)','EX_hst_3_s(e)','EX_hst_37_diglc(e)','EX_hst_3glc_7s(e)','EX_hst_7_glc(e)','EX_hst_7_s(e)','EX_hst_7glc_3s(e)','EX_ibup_S(e)','EX_ibupgluc(e)','EX_imn(e)','EX_imn_glc(e)','EX_inv(e)','EX_inv_m1(e)','EX_isosorbide_5mn(e)','EX_isosorbide_5mn_glc(e)','EX_kprofen(e)','EX_kprofen_glc(e)','EX_lst4exp(e)','EX_lstn(e)','EX_lstn1gluc(e)','EX_lstnm4(e)','EX_lstnm7(e)','EX_mdz(e)','EX_mdz_glc(e)','EX_mdzglc(e)','EX_miso(e)','EX_miso_glc(e)','EX_mrphn(e)','EX_mrphn_3glc(e)','EX_mrphn_6glc(e)','EX_mtz(e)','EX_mtz_glc(e)','EX_N_oh_phtn(e)','EX_N_oh_phtn_glc(e)','EX_nsldp_m5(e)','EX_nsldp_m5_glc(e)','EX_nverp(e)','EX_nverp_glc(e)','EX_odsm_egltmn(e)','EX_odsm_egltmn_glc(e)','EX_odsm_gltmn(e)','EX_odsm_gltmn_glc(e)','EX_oh_etr(e)','EX_oh_etr_glc(e)','EX_oh_pbl(e)','EX_oh_pbl_glc(e)','EX_phppa(e)','EX_phppa_glc(e)','EX_phtn_glc(e)','EX_prob(e)','EX_prob_glc(e)','EX_pront(e)','EX_pront_glc(e)','EX_propl(e)','EX_propl_glc(e)','EX_prx_mI(e)','EX_prx_mI_glc(e)','EX_prx_mII(e)','EX_prx_mII_glc(e)','EX_ptvst(e)','EX_ptvstgluc(e)','EX_pvs(e)','EX_pvsgluc(e)','EX_R_6oh_warf(e)','EX_R_6oh_warf_glc(e)','EX_R_7oh_warf(e)','EX_R_7oh_warf_glc(e)','EX_R_8oh_warf(e)','EX_R_8oh_warf_glc(e)','EX_r406(e)','EX_r406_glc(e)','EX_r529(e)','EX_r529_glc(e)','EX_rep(e)','EX_rep_glc(e)','EX_rpn_104557(e)','EX_rpn_104557_cb_glc(e)','EX_rpn_96990(e)','EX_rpn_96990_glc(e)','EX_rpn_oh(e)','EX_rpn_oh_glc(e)','EX_rsv(e)','EX_rsvgluc(e)','EX_S_4oh_warf(e)','EX_S_4oh_warf_glc(e)','EX_S_6oh_warf(e)','EX_S_6oh_warf_glc(e)','EX_sb_611855(e)','EX_sb_y(e)','EX_sch_488128(e)','EX_sch_57871(e)','EX_sch_57871_glc(e)','EX_sfnd_1689(e)','EX_sfnd_1689_glc(e)','EX_sftz(e)','EX_sftz_glc(e)','EX_simvgluc(e)','EX_smap(e)','EX_smap_glc(e)','EX_smvacid(e)','EX_sn38(e)','EX_sn38g(e)','EX_spz(e)','EX_spz_glc(e)','EX_spz_sfn(e)','EX_spz_sfn_glc(e)','EX_stg(e)','EX_stg_m3(e)','EX_stg_m4(e)','EX_tat(e)','EX_tgz(e)','EX_tgz_glc(e)','EX_thsacmp(e)','EX_tlf_a(e)','EX_tlf_a_1a(e)','EX_tlf_a_1b(e)','EX_tlf_a_1x(e)','EX_tlf_a_2(e)','EX_tlf_a_2a(e)','EX_tlf_a_3(e)','EX_tlf_a_4(e)','EX_tlf_a_m1(e)','EX_tlf_a_m2(e)','EX_tlf_a_m3(e)','EX_tlf_a_m4(e)','EX_tlf_a_m4a(e)','EX_tlf_a_m5(e)','EX_tlf_a_m5a(e)','EX_tlf_a_m5b(e)','EX_tlf_a_m6(e)','EX_tlf_a_m9(e)','EX_tlms(e)','EX_tlms_glc(e)','EX_tmacmp(e)','EX_tolcp(e)','EX_tolcp_ac(e)','EX_tolcp_ac_glc(e)','EX_tolcp_am(e)','EX_tolcp_am_glc(e)','EX_tolcp_glc(e)','EX_tpno_1glc_4g(e)','EX_tpno_4g(e)','EX_tpno_4glc(e)','EX_tpnoh(e)','EX_tsacmgluc(e)';'cUidA','EX_1hibup_S(e)','EX_1hibupglu_S(e)','EX_1hmdgluc(e)','EX_1ohmdz(e)','EX_2hatvacid(e)','EX_2hatvacidgluc(e)','EX_2hatvlac(e)','EX_2hatvlacgluc(e)','EX_2hibup_S(e)','EX_2hibupglu_S(e)','EX_2oh_cbz(e)','EX_2oh_cbz_glc(e)','EX_2oh_mtz(e)','EX_2oh_mtz_glc(e)','EX_3meacmp(e)','EX_3hibup_S(e)','EX_3hibupglu_S(e)','EX_3oh_cbz(e)','EX_3oh_cbz_glc(e)','EX_3oh_dlor(e)','EX_3oh_dlor_glc(e)','EX_3oh_mdea(e)','EX_3oh_mdea_glc(e)','EX_3oh_mxn(e)','EX_3oh_mxn_glc(e)','EX_4dh_tpno(e)','EX_4dh_tpno_1glc(e)','EX_4hmdgluc(e)','EX_4oh_dcf(e)','EX_4oh_dcf_glc(e)','EX_4oh_kp(e)','EX_4oh_kp_glc(e)','EX_4oh_levole(e)','EX_4oh_levole_glc(e)','EX_4oh_meth(e)','EX_4oh_meth_glc(e)','EX_4oh_propl(e)','EX_4oh_propl_glc(e)','EX_4oh_trz(e)','EX_4oh_trz_glc(e)','EX_4oh_vcz(e)','EX_4oh_vcz_glc(e)','EX_4ohmdz(e)','EX_5oh_sulfp(e)','EX_5oh_sulfp_glc(e)','EX_5ohfvs(e)','EX_5ohfvsglu(e)','EX_6bhglz(e)','EX_6bhglzglc(e)','EX_6ohfvs(e)','EX_6ohfvsglu(e)','EX_7bhglz(e)','EX_7bhglzglc(e)','EX_7oh_efv(e)','EX_7oh_efv_glc(e)','EX_814dioh_efv(e)','EX_814dioh_efv_glc(e)','EX_8oh_efv(e)','EX_8oh_efv_glc(e)','EX_ac_amn_b_gly(e)','EX_ac_amn_b_gly_glc(e)','EX_acmp(e)','EX_acmp_glc(e)','EX_acmpglu(e)','EX_alpz_4oh(e)','EX_alpz_4oh_glc(e)','EX_alpz_aoh(e)','EX_alpz_aoh_glc(e)','EX_am14(e)','EX_am14_glc(e)','EX_am1ccs(e)','EX_am1cglc(e)','EX_am5(e)','EX_am5_glc(e)','EX_am6(e)','EX_am6_glc(e)','EX_amio(e)','EX_amio_c(e)','EX_amio_c_glc(e)','EX_amio_glc(e)','EX_amn_b_gly(e)','EX_amn_b_gly_glc(e)','EX_amntd_m6(e)','EX_amntd_m6_glc(e)','EX_atvacid(e)','EX_atvacylgluc(e)','EX_atvethgluc(e)','EX_atvlac(e)','EX_atvlacgluc(e)','EX_bhpm(e)','EX_bhpm_glc(e)','EX_bilr_355(e)','EX_bilr_M10(e)','EX_bilr_M12(e)','EX_bilr_M14(e)','EX_bilr_M15(e)','EX_bilr_M16(e)','EX_bilr_M7(e)','EX_bsn(e)','EX_bsn_glc(e)','EX_bz(e)','EX_bz_glc(e)','EX_caribup_s(e)','EX_caribupglu_S(e)','EX_cbz(e)','EX_cbz_glc(e)','EX_cd6168(e)','EX_cd6168_glc(e)','EX_chlphncl(e)','EX_chlphncl_glc(e)','EX_clcxb(e)','EX_clcxb_c(e)','EX_clcxb_c_glc(e)','EX_clcxb_glc(e)','EX_clobi_c(e)','EX_clobi_glc(e)','EX_crvsm1(e)','EX_crvsm23(e)','EX_cvm1gluc(e)','EX_cvm23gluc(e)','EX_daa(e)','EX_daa_glc(e)','EX_dcf(e)','EX_dcf_glc(e)','EX_ddea(e)','EX_ddea_glc(e)','EX_des_astzl(e)','EX_des_astzl_glc(e)','EX_digoxin(e)','EX_digoxin_glc(e)','EX_dlb(e)','EX_dlb_glc(e)','EX_dnpz_5des(e)','EX_dnpz_6des(e)','EX_dnpz_m11(e)','EX_dnpz_m12(e)','EX_dnpz_m13(e)','EX_dnpz_m14(e)','EX_dnpz_m9(e)','EX_doh_etr(e)','EX_doh_etr_glc(e)','EX_doh_vcz(e)','EX_doh_vcz_glc(e)','EX_dxo(e)','EX_dxo_glc(e)','EX_efv(e)','EX_efv_glc(e)','EX_eltr(e)','EX_eltr_glc(e)','EX_eltr_m3(e)','EX_eltr_m4(e)','EX_eztmb(e)','EX_eztmb_glc(e)','EX_fvs(e)','EX_fvsgluc(e)','EX_fvstet(e)','EX_fvstetglu(e)','EX_glc3meacp(e)','EX_gltmn(e)','EX_gltmn_glc(e)','EX_gmfl(e)','EX_gmfl_glc(e)','EX_gmfl_mI(e)','EX_gmfl_mI_glc(e)','EX_gmfl_mII(e)','EX_gmfl_mII_glc(e)','EX_gmfl_mIII(e)','EX_gmfl_mIII_glc(e)','EX_gtacmp(e)','EX_hst(e)','EX_hst_3_glc(e)','EX_hst_3_s(e)','EX_hst_37_diglc(e)','EX_hst_3glc_7s(e)','EX_hst_7_glc(e)','EX_hst_7_s(e)','EX_hst_7glc_3s(e)','EX_ibup_S(e)','EX_ibupgluc(e)','EX_imn(e)','EX_imn_glc(e)','EX_inv(e)','EX_inv_m1(e)','EX_isosorbide_5mn(e)','EX_isosorbide_5mn_glc(e)','EX_kprofen(e)','EX_kprofen_glc(e)','EX_lst4exp(e)','EX_lstn(e)','EX_lstn1gluc(e)','EX_lstnm4(e)','EX_lstnm7(e)','EX_mdz(e)','EX_mdz_glc(e)','EX_mdzglc(e)','EX_miso(e)','EX_miso_glc(e)','EX_mrphn(e)','EX_mrphn_3glc(e)','EX_mrphn_6glc(e)','EX_mtz(e)','EX_mtz_glc(e)','EX_N_oh_phtn(e)','EX_N_oh_phtn_glc(e)','EX_nsldp_m5(e)','EX_nsldp_m5_glc(e)','EX_nverp(e)','EX_nverp_glc(e)','EX_odsm_egltmn(e)','EX_odsm_egltmn_glc(e)','EX_odsm_gltmn(e)','EX_odsm_gltmn_glc(e)','EX_oh_etr(e)','EX_oh_etr_glc(e)','EX_oh_pbl(e)','EX_oh_pbl_glc(e)','EX_phppa(e)','EX_phppa_glc(e)','EX_phtn_glc(e)','EX_prob(e)','EX_prob_glc(e)','EX_pront(e)','EX_pront_glc(e)','EX_propl(e)','EX_propl_glc(e)','EX_prx_mI(e)','EX_prx_mI_glc(e)','EX_prx_mII(e)','EX_prx_mII_glc(e)','EX_ptvst(e)','EX_ptvstgluc(e)','EX_pvs(e)','EX_pvsgluc(e)','EX_R_6oh_warf(e)','EX_R_6oh_warf_glc(e)','EX_R_7oh_warf(e)','EX_R_7oh_warf_glc(e)','EX_R_8oh_warf(e)','EX_R_8oh_warf_glc(e)','EX_r406(e)','EX_r406_glc(e)','EX_r529(e)','EX_r529_glc(e)','EX_rep(e)','EX_rep_glc(e)','EX_rpn_104557(e)','EX_rpn_104557_cb_glc(e)','EX_rpn_96990(e)','EX_rpn_96990_glc(e)','EX_rpn_oh(e)','EX_rpn_oh_glc(e)','EX_rsv(e)','EX_rsvgluc(e)','EX_S_4oh_warf(e)','EX_S_4oh_warf_glc(e)','EX_S_6oh_warf(e)','EX_S_6oh_warf_glc(e)','EX_sb_611855(e)','EX_sb_y(e)','EX_sch_488128(e)','EX_sch_57871(e)','EX_sch_57871_glc(e)','EX_sfnd_1689(e)','EX_sfnd_1689_glc(e)','EX_sftz(e)','EX_sftz_glc(e)','EX_simvgluc(e)','EX_smap(e)','EX_smap_glc(e)','EX_smvacid(e)','EX_sn38(e)','EX_sn38g(e)','EX_spz(e)','EX_spz_glc(e)','EX_spz_sfn(e)','EX_spz_sfn_glc(e)','EX_stg(e)','EX_stg_m3(e)','EX_stg_m4(e)','EX_tat(e)','EX_tgz(e)','EX_tgz_glc(e)','EX_thsacmp(e)','EX_tlf_a(e)','EX_tlf_a_1a(e)','EX_tlf_a_1b(e)','EX_tlf_a_1x(e)','EX_tlf_a_2(e)','EX_tlf_a_2a(e)','EX_tlf_a_3(e)','EX_tlf_a_4(e)','EX_tlf_a_m1(e)','EX_tlf_a_m2(e)','EX_tlf_a_m3(e)','EX_tlf_a_m4(e)','EX_tlf_a_m4a(e)','EX_tlf_a_m5(e)','EX_tlf_a_m5a(e)','EX_tlf_a_m5b(e)','EX_tlf_a_m6(e)','EX_tlf_a_m9(e)','EX_tlms(e)','EX_tlms_glc(e)','EX_tmacmp(e)','EX_tolcp(e)','EX_tolcp_ac(e)','EX_tolcp_ac_glc(e)','EX_tolcp_am(e)','EX_tolcp_am_glc(e)','EX_tolcp_glc(e)','EX_tpno_1glc_4g(e)','EX_tpno_4g(e)','EX_tpno_4glc(e)','EX_tpnoh(e)','EX_tsacmgluc(e)'};
drugExchanges=cell2table(drugExchanges);

% find microbe index in drug metabolism table
mInd = find(ismember(drugTable.MicrobeID, microbeID));
if isempty(mInd)
    warning(['Microbe "', microbeID, '" not found in drug metabolite data file.'])
    TruePositives = {};
    FalseNegatives = {};
else
    % perform FVA to identify uptake metabolites
    % set BOF
    if ~any(ismember(model.rxns, biomassReaction)) || nargin < 3
        error(['Biomass reaction "', biomassReaction, '" not found in model.'])
    end
    model = changeObjective(model, biomassReaction);
    % set a low lower bound for biomass
%     model = changeRxnBounds(model, biomassReaction, 1e-3, 'l');
    % list exchange reactions
    exchanges = model.rxns(strncmp('EX_', model.rxns, 3));
    % open all exchanges
    model = changeRxnBounds(model, exchanges, -1000, 'l');
    model = changeRxnBounds(model, exchanges, 1000, 'u');
    rxns = drugExchanges(table2array(drugTable(mInd, 2:end)) == 1, 2:end);
    
    TruePositives = {};  % true positives (flux in vitro and in silico)
    FalseNegatives = {};  % false negatives (flux in vitro not in silico)
    
    % flux variability analysis on reactions of interest
    rxns = unique(table2cell(rxns));
    rxns = rxns(~cellfun('isempty', rxns));
    if ~isempty(rxns)
        rxnsInModel=intersect(rxns,model.rxns);
        rxnsNotInModel=setdiff(rxns,model.rxns);
        if isempty(rxnsInModel)
            % all exchange reactions that should be there are not there -> false
            % negatives
            FalseNegatives = rxns;
            TruePositives= {};
        else
            if ~isempty(ver('distcomp')) && any(strcmp(solver,'ibm_cplex'))
                [minFlux, maxFlux, ~, ~] = fastFVA(model, 0, 'max', solver, ...
                    rxnsInModel, 'S');
            else
                FBA=optimizeCbModel(model,'max');
                if FBA.stat ~=1
                    warning('Model infeasible. Testing could nbot be performed.')
                    minFlux=zeros(length(rxnsInModel),1);
                    maxFlux=zeros(length(rxnsInModel),1);
                else
                    [minFlux, maxFlux] = fluxVariability(model, 0, 'max', rxnsInModel);
                end
            end
            % active flux
            uptFlux = rxnsInModel(minFlux < -1e-6);
            secrFlux = rxnsInModel(maxFlux > 1e-6);
            flux=union(uptFlux,secrFlux);
            % which drug metabolite shoudl be taken up/secreted according to in vitro data
            drugData = find(table2array(drugTable(mInd, 2:end)) == 1);
            % check all exchanges corresponding to each drug
            for i = 1:length(drugData)
                tableData = table2array(drugExchanges(drugData(i), 2:end));
                allEx = tableData(~cellfun(@isempty, tableData));
                TruePositives = union(TruePositives, intersect(allEx, flux));
                FalseNegatives = union(FalseNegatives, setdiff(allEx, flux));
                % add any that are not in model to the false negatives
                if ~isempty(rxnsNotInModel)
                    FalseNegatives=union(FalseNegatives,rxnsNotInModel);
                end
            end
        end
    end
end

% replace reaction IDs with metabolite names
if ~isempty(TruePositives)
    TruePositives = TruePositives(~cellfun(@isempty, TruePositives));
    TruePositives=strrep(TruePositives,'EX_','');
    TruePositives=strrep(TruePositives,'(e)','');
    
    for i=1:length(TruePositives)
        TruePositives{i}=metaboliteDatabase{find(strcmp(metaboliteDatabase(:,1),TruePositives{i})),2};
    end
end

% warn about false negatives
if ~isempty(FalseNegatives)
    FalseNegatives = FalseNegatives(~cellfun(@isempty, FalseNegatives));
    FalseNegatives=strrep(FalseNegatives,'EX_','');
    FalseNegatives=strrep(FalseNegatives,'(e)','');
    for i = 1:length(FalseNegatives)
        FalseNegatives{i}=metaboliteDatabase{find(strcmp(metaboliteDatabase(:,1),FalseNegatives{i})),2};
        warning(['Microbe "' microbeID, '" cannot take up or secrete drug metabolite "', FalseNegatives{i}, '".'])
    end
end

end
