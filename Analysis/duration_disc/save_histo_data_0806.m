function [] = save_histo_data_0806()

global Solo_datadir;
fname = [Solo_datadir filesep 'Data' filesep 'Shraddha' filesep 'Histo' filesep 'scoring_0806.mat'];
fprintf(1,'%s\n', fname);

% ------------------------------------------------------------------------
% Output of Applescript histology analysis suite
% ------------------------------------------------------------------------
% -- LEFT hemisphere: Output of App
ACx_lesionyesno__LEFT = { ...
    'Eaglet', '111001110111000001110000111000000', ...
    'Gryphon', '000001110011110111001111100000000', ...
    'Legolas', '101011100000111100011100111110000', ...
    'Sauron', '101001110111111001110000111011100', ...
    'Boromir', '000011100001111100011111101111000', ...
    'Bilbo', '000000111111111001110111011111100', ...
    'Lory', '000111111001111100011100000000000', ...
    'Gandalf', '111001111101111110011100111111100', ...
    'Aragorn', '000011100001111000011110111111100', ...
    'Gimli', '111111100111111100001110111011100' ...
    };
%---	RIGHT hemisphere:
ACx_lesionyesno__RIGHT = { ...
    'Eaglet', '111110111000011110111011111000000', ...
    'Gryphon', '000011111011110111001110000111000', ...
    'Legolas', '101111000111011000011100111110000', ...
    'Sauron', '000011111111111110011110011100000', ...
    'Boromir', '000000000111111000011111100011111', ...
    'Bilbo', '000111001111111000111011101111110', ...
    'Lory', '010111110001111000111001110000000', ...
    'Gandalf', '000011101111111110001110011111000', ...
    'Aragorn', '000011100011111110011101111111111', ...
    'Gimli', '111111100111001111100011111100000' ...
    };

% --- combined for both hemispheres
PFC_lesion_yesno = ...
    {'Celeborn','000111011010000000000', ...
    'Wraith', '000111101000000000100', ...
    'Shelob', '000001010101000000000', ...
    'Nazgul', '000011001000000100000', ...
    'Treebeard', '000101001000000000000', ...
    'Hudson', '000010110110000000000', ...
    'Sherlock', '000111101011000000000', ...
    'Shadowfax', '000011011010000000000', ...
    'Moria',  '001001001000011000000', ...
    'Evenstar',  '001010100100010000000', ...
    'Watson','000111101000010000000'...
    };
PFC_task = 'ddddddppppp';

% ------------------------------------------------------------------------
% Manually added information distinguishing "no data" (N) from "no lesion"
% (X)
% ------------------------------------------------------------------------
% -- LEFT hemisphere: Output of App
ACx_NXmarked__LEFT = { ...
    'Eaglet', '111NN111N111NNNNN111NNNN111NNNNXX', ...
    'Gryphon', 'NNNNN111NN1111N111NN11111NNXNNNXX', ...
    'Legolas', '1N1N111NNNNN1111NNN111NN11111NNNN', ...
    'Sauron', '1N1NN111N111111NN111NNNN111N111NN', ...
    'Boromir', 'XNNN111NNNX11111NNN111111N1111NNN', ...
    'Bilbo', 'NNNNNN111111111NN111N111N111111NN', ...
    'Lory', 'NNN111111NN11111NNN111NNNXNNXNNNN', ...
    'Gandalf', '111NN11111N111111NN111NN1111111NN', ...
    'Aragorn', 'NNNN111NNNN1111NNNN1111N1111111NN', ...
    'Gimli', '1111111NN1111111NNNN111N111N111NN' ...
    };

ACx_NXmarked__RIGHT = { ...
    'Eaglet', '11111N111NNNN1111N111N11111NXXNNX', ...
    'Gryphon', 'NNNX11111N1111N111NN111NNNN111NNN', ...
    'Legolas', '1N1111NNN111N11NNNN111NN11111NNNN', ...
    'Sauron', 'NNNN1111111111111NN1111NN111NNNXN', ...
    'Boromir', 'XNNNNXNNN111111NNNN111111NNN11111', ...
    'Bilbo', 'NNN111NN1111111NNN111N111N111111N', ...
    'Lory', 'N1N11111NNN1111NNN111NN111NNXNNNN', ...
    'Gandalf', 'NNNN111N111111111NNN111NN11111NXN', ...
    'Aragorn', 'NNNN111NNN1111111NN111N1111111111', ...
    'Gimli', '1111111NN111NN11111NNN111111NNNNN' ...
    };


% ------------------------------------------------------------------------
% Output of Matlab scripts that use Applescript (automatic) or
% Applescript-enhanced (manual distinguishing of N and X cases)
% ------------------------------------------------------------------------
% run of lesion_coverage.m -- " 'N'o Data" sections not added
%   1 - 'L' for left-only lesion
%   2 - 'R' for right-only lesion
%   3 - 'B' for lesion in both hemisphere
%   4 - 'X' for no lesion in either hemisphere ---> "no data" (N) not
%   distinguished from "no lesion" (X)
ACx_lesion_coverage_scriptgen = 0;
ACx_lesion_coverage_scriptgen.Eaglet= 'BBBRRLBBRLLLXRRRRLBBRXRRBBBXXXXXX';
ACx_lesion_coverage_scriptgen.Gryphon= 'XXXXRBBBRXBBBBXBBBXXBBBLLXXRRRXXX';
ACx_lesion_coverage_scriptgen.Legolas= 'BXBRBBLXXRRRLBBLXXXBBBXXBBBBBXXXX';
ACx_lesion_coverage_scriptgen.Sauron= 'LXLXRBBBRBBBBBBRRLLBRRRXLBBRLLLXX';
ACx_lesion_coverage_scriptgen.Boromir= 'XXXXLLLXXRRBBBBLXXXBBBBBBXLLBBRRR';
ACx_lesion_coverage_scriptgen.Bilbo= 'XXXRRRLLBBBBBBBXXLBBRLBBRLBBBBBRX';
ACx_lesion_coverage_scriptgen.Lory= 'XRXBBBBBLXXBBBBLXXRBBLXRRRXXXXXXX';
ACx_lesion_coverage_scriptgen.Gandalf= 'LLLXRBBLBBRBBBBBBXXLBBRXLBBBBBLXX';
ACx_lesion_coverage_scriptgen.Aragorn= 'XXXXBBBXXXRBBBBRRXXBBBLRBBBBBBBRR';
ACx_lesion_coverage_scriptgen.Gimli= 'BBBBBBBXXBBBLLBBRRRXLLBRBBBRLLLXX';

ACx_task = 'dddddppppp';


save(fname, ...
    'ACx_lesionyesno__LEFT', 'ACx_lesionyesno__RIGHT', ...      % Applescript-generated
    'PFC_lesion_yesno',...                                      % Applescript-generated
    'ACx_NXmarked__LEFT', 'ACx_NXmarked__RIGHT',  ... % Manual marking of Applescript output
    'ACx_lesion_coverage_scriptgen' , ...                       % Matlab remarking of Applescript-generated
    'ACx_task',   'PFC_task'...                                 % manual
    );

