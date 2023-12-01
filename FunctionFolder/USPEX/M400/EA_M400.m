function EA_M400()
% $Rev: 1120 $
% $Author: mrakitin $
% $Date: 2015-08-20 21:51:42 +0400 (Thu, 20 Aug 2015) $

global ORG_STRUC
global POP_STRUC
global OFF_STRUC
global USPEX_STRUC
global ANTISEEDS

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%     Evolutionary Algorithm    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fpath = [ORG_STRUC.resFolder '/' ORG_STRUC.log_file];
fp = fopen(fpath, 'a+');

while POP_STRUC.generation < ORG_STRUC.numGenerations + 0.5
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Step 2:        Local Relaxation    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    while 1 % this eternal cycle is needed for non parallel calculations, parallelized one will /break out of it
        ReadJobs_M400();
        SubmitJobs_M400();
        
        if (ORG_STRUC.platform > 0) | (ORG_STRUC.numParallelCalcs > 1)
            if sum([POP_STRUC.POPULATION(:).Done])~= length(POP_STRUC.POPULATION)
                [nothing, nothing] = unix('rm still_running');
                fclose ('all');
                quit
            else
                break;
            end
        else
            if sum([POP_STRUC.POPULATION(:).Done]) == length(POP_STRUC.POPULATION)
                break; % break out of eternal cycle when non parallel calculations finished for given generation
            end
        end
    end
    
    disp('status = Local optimisation finished')
    disp(' ')
    fprintf(fp, [alignLine('-', 0) '\n']);
    fprintf(fp, [alignLine('Local optimization finished') '\n']);
    fprintf(fp, [alignLine('-', 0) '\n']);
    fprintf(fp, [alignLine( sprintf('SUMMARY of Generation %d', POP_STRUC.generation) ) '\n'] );
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Step 3:  Fitness                 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    good_and_fit = 0;
    for fit_loop = 1 : length(POP_STRUC.POPULATION)
        if POP_STRUC.POPULATION(fit_loop).Enthalpies(end) < 90000
            good_and_fit = good_and_fit + 1;
        end
    end
    
    if good_and_fit < floor(length(POP_STRUC.POPULATION)/3)
        fprintf(fp,'Too many structures have errors or failed the constraints after optimization.\n');
        fprintf(fp,'Please check the input files. The calculation has to stop.\n');
        fprintf(fp,'Possible reasons: badly tuned optimization parameters or unreasonable contraints.\n');
        quit;
    elseif good_and_fit/length(POP_STRUC.POPULATION) < ORG_STRUC.bestFrac
        fprintf(fp,'Some structures have errors or failed the constraints after optimisation,\n');
        fprintf(fp,'bestFrac parameter will be lowered for this generation to discard such structures.\n');
        fprintf(fp,'Please check the input files. Results may not be reliable. \n');
        fprintf(fp,'Possible reasons: high bestFrac, bad optimization parameters or unreasonable contraints.\n');
    end
    
    if ~((ORG_STRUC.pickedUP == 1) & (ORG_STRUC.pickUpGen == POP_STRUC.generation))
        fitness = CalcFitness_M400();
        cor_coefficient = Correlation(fitness);
        fprintf(fp, [alignLine( sprintf('Correlation coefficient = %.4f', cor_coefficient) ) '\n'] );
        
        fitness = AntiSeedsCorrection(fitness);
        fitness = FitnessRankingCorrection(fitness);
        WriteGenerationOutput_M400(fitness);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Step 4:  If stop this calculation                 %%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    ToStop = 0;
    if POP_STRUC.generation >= ORG_STRUC.numGenerations
        ToStop = 1;
    elseif POP_STRUC.generation >= ORG_STRUC.stopCrit
        same_in = SameBest();
        if same_in == ORG_STRUC.stopCrit - 1
            fprintf(fp,'Halting criteria achieved: %d\n', POP_STRUC.bodyCount);
            ToStop = 1;
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Step 5: Selection and Variation               %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ToStop==1
        Finish();
    else
        fprintf(fp, [alignLine('-', 0) '\n']);
        fprintf(fp, [alignLine('Proceeding to Selection Process') '\n']);
        fprintf(fp, [alignLine('-', 0) '\n']);
        fprintf(fp,'\n');
        
        WriteGenerationBackup();
        
        update_STUFF_M400('INPUT.txt', good_and_fit/length(POP_STRUC.POPULATION), POP_STRUC.ranking);
        CreateCalcFolder();
        
        OFF_STRUC = POP_STRUC;
        OFF_STRUC.POPULATION = [];
        OFF_STRUC(1).POPULATION = POP_STRUC.POPULATION(1); %just make it has same structure
        OFF_STRUC.POPULATION(1) = QuickStart(OFF_STRUC.POPULATION);
        
        % some generations only softmutated, if needed
        if POP_STRUC.generation < ORG_STRUC.numGenerations
            if (ORG_STRUC.softMutOnly(POP_STRUC.generation+1) == 1)
                ORG_STRUC.howManyMutations = 0;
                ORG_STRUC.howManyPermutations = 0;
                ORG_STRUC.howManyRand = 0;
                ORG_STRUC.howManyAtomMutations = length(POP_STRUC.ranking) - POP_STRUC.bad_rank;
                ORG_STRUC.howManyOffsprings = 0;
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        Operation = {'Heredity_M400', 'Random_M400', 'Mutation_M400', 'SecSwitch', 'ShiftBorder'};
        Num_Opera = [ORG_STRUC.howManyOffsprings, ORG_STRUC.howManyRand, ...
            ORG_STRUC.howManyRotations,  ORG_STRUC.howManySecSwitch, ...
            ORG_STRUC.howManyShiftBorder];
        count = 0;
        for i = 1 : length(Num_Opera)
            for j = 1:Num_Opera(i)
                count = count + 1;
                eval([Operation{i} '(' num2str(count) ')']);
            end
        end
        
        disp(' ');
        disp('Variation operators applied, applying elitist scheme')
        
        OFF_STRUC.generation = POP_STRUC.generation + 1;
        POP_STRUC.generation = POP_STRUC.generation + 1;
        
        fprintf(fp, [alignLine('-', 0) '\n']);
        fprintf(fp, [alignLine('Variation operators applied') '\n']);
        fprintf(fp, [alignLine('-', 0) '\n']);
        fprintf(fp,'        %4d structures produced by heredity        \n', ORG_STRUC.howManyOffsprings);
        fprintf(fp,'        %4d structures produced by random          \n', ORG_STRUC.howManyRand);
        fprintf(fp,'        %4d structures produced by rotmutation     \n', ORG_STRUC.howManyRotations);
        fprintf(fp,'        %4d structures produced by secondary switch\n', ORG_STRUC.howManySecSwitch);
        fprintf(fp,'        %4d structures produced by shift border    \n', ORG_STRUC.howManyShiftBorder);
        addon_diff = KeepBestStructures();
        fprintf(fp,'        %4d structures kept as best from the previous generation\n', addon_diff);
        
        POP_STRUC = OFF_STRUC;
        num = pick_Seeds();
        fprintf(fp,'        %4d Seeds structures are added from Seeds/POSCARS_%3d \n', num, POP_STRUC.generation);
        fprintf(fp, [alignLine('-', 0) '\n']);
        fprintf(fp, [alignLine('Proceeding to the new generation relaxation') '\n']);
        fprintf(fp, [alignLine('-', 0) '\n']);
        fprintf(fp,'        %4d parallel calculations are performed simutaneously\n', ORG_STRUC.numParallelCalcs);
        fprintf(fp, [alignLine('-', 0) '\n']);
        
	%%% Удаление gatheredPDB для ускорения работы
        % Цикл для проверки, все ли структуры в поколении отрелаксированы
	cd(ORG_STRUC.resFolder)
        Done_status = 1;
        for i = 1 : length(POP_STRUC.POPULATION)
            if POP_STRUC.POPULATION(i).Done == 0
                Done_status=0;
            end
        end
        if Done_status == 1 
            [nothing, nothing] = unix(['cat gatheredPDB >> all_gatheredPDB']);
	    [nothing, nothing] = unix(['rm -f old_gatheredPDB']);
            [nothing, nothing] = unix(['mv gatheredPDB old_gatheredPDB']);
        end
	cd ..

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%% THE NEW POPULATION
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        fprintf(fp, [alignLine( sprintf('Generation %d', POP_STRUC.generation) ) '\n'] );
        fprintf(fp,'  ID   Origin      Composition  Enthalpy      Volume(A^3)  KPOINTS  SYMMETRY\n');
        fprintf(fp,'                               (kcal/mol)\n');
        WriteGenerationStart();
        Start_POP_M400();
        
        safesave ('Current_POP.mat', POP_STRUC)
        safesave ('Current_ORG.mat', ORG_STRUC)
        disp(' ');
        disp('New generation produced');
    end
end

fclose(fp);
