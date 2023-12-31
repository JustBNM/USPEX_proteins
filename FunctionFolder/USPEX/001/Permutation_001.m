function Permutation_001(Ind_No)

% USPEX Version 6.6.7
global POP_STRUC
global ORG_STRUC
global OFF_STRUC

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% CREATING mutants by permutation %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

goodMutant = 0;
goodMutLattice = 0;
count = 1;
while goodMutant + goodMutLattice  ~= 2
    count = count + 1;
    if count > 50
       %disp('failed to do mutation in 50 attempts, switch to Random');
       USPEXmessage(508,'',0);
       Random_001(Ind_No);
       break;
    end

    toPerMutate = find(ORG_STRUC.tournament>RandInt(1,1,[0,max(ORG_STRUC.tournament)-1]));
    ind = POP_STRUC.ranking(toPerMutate(end));
    % create a PERMUTANT. The swapIons_mutation simply swaps ions
    % of a different type
    LATTICE = POP_STRUC.POPULATION(ind).LATTICE;
    father  = POP_STRUC.POPULATION(ind).COORDINATES;
    numIons = POP_STRUC.POPULATION(ind).numIons;
    order = POP_STRUC.POPULATION(ind).order;
    [PERMUT,noOfSwapsNow] = swapIons_mutation_final(father, numIons, order);
    if noOfSwapsNow > 0
       goodMutant = distanceCheck(PERMUT,LATTICE, numIons, ORG_STRUC.minDistMatrice);
       if goodMutant == 1
          goodMutant = checkConnectivity(PERMUT, LATTICE, numIons);
       end
    end
    goodMutLattice = 1; % since permutation doesn't change it

    if goodMutant + goodMutLattice == 2
        OFF_STRUC.POPULATION(Ind_No).COORDINATES =  PERMUT;
        OFF_STRUC.POPULATION(Ind_No).LATTICE = LATTICE;
        OFF_STRUC.POPULATION(Ind_No).howCome = 'Permutate';

        info_parents = struct('parent', {},'noOfSwapsNow', {}, 'enthalpy', {});
        info_parents(1).parent=num2str(POP_STRUC.POPULATION(ind).Number);
        info_parents.noOfSwapsNow=noOfSwapsNow;
        info_parents.enthalpy=POP_STRUC.POPULATION(ind).Enthalpies(end);
        OFF_STRUC.POPULATION(Ind_No).Parents = info_parents;
        OFF_STRUC.POPULATION(Ind_No).numIons = numIons;
        disp(['Structure ' num2str(Ind_No) ' generated by permutation']);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% END creating mutants %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
