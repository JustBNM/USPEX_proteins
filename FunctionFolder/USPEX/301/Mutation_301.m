function Mutation_301(Ind_No)

%This routine to mutate the parent structure according to a given gaussian distribution.
%If it fails for 1000 times, will return the same structure
%last updated by Qiang Zhu, 2013/10/09

global POOL_STRUC
global  ORG_STRUC
global  OFF_STRUC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% CREATING Mutants by atom positions mutation%%%%%%%%%%%%%%%%%
goodAtomMutant = 0;
goodMutLattice = 0;

safeguard = 0;
count = 1;
while goodAtomMutant + goodMutLattice ~= 2
    count = count + 1;
    
    ind = chooseGoodComposition(ORG_STRUC.tournament, POOL_STRUC.POPULATION);
    if (count>50) | (ind<0)
        %disp('failed to do mutation in 50 attempts, switch to Random');
        USPEXmessage(508,'',0);
        Random_301(Ind_No);
        break;
    end
    
    %toMutate = find(ORG_STRUC.tournament>RandInt(1,1,[0,max(ORG_STRUC.tournament)-1]));
    %ind = toMutate(end);
    coor    = POOL_STRUC.POPULATION(ind).COORDINATES;
    lat     = POOL_STRUC.POPULATION(ind).LATTICE;
    numIons = POOL_STRUC.POPULATION(ind).numIons;
    order   = POOL_STRUC.POPULATION(ind).order;
    numBlocks = POOL_STRUC.POPULATION(ind).numBlocks;
    %goodComposition = CompositionCheck(numBlocks);
    
    %if goodComposition
    MUT_COORD      = move_all_atom_Mutation(coor, numIons, lat, order, ORG_STRUC.howManyMut*(1-safeguard/100));
    goodAtomMutant = distanceCheck (MUT_COORD, lat, numIons, ORG_STRUC.minDistMatrice);
    
    %-- Do you really need the safeguard?? --%
    if safeguard == 100
        goodAtomMutant = 1; % to avoid eternal cycle
        MUT_COORD = coor; %if all attempts fail. will use the original structure
    end
    safeguard = safeguard + 1;
    %end
    
    %N_Moved = sum(numIons);
    goodMutLattice = 1; % since we don't change it
    if goodAtomMutant + goodMutLattice == 2
        disp(['Structure ' num2str(Ind_No) '  generated by mutation']);

        info_parents           = struct('parent', {},'N_Moved', {}, 'enthalpy', {});
        info_parents(1).parent = num2str(POOL_STRUC.POPULATION(ind).Number);
        info_parents.N_Moved   = sum(numIons);
        info_parents.enthalpy  = POOL_STRUC.POPULATION(ind).enthalpy;
        
        OFF_STRUC.POPULATION(Ind_No).Parents     = info_parents;
        OFF_STRUC.POPULATION(Ind_No).COORDINATES = MUT_COORD;
        OFF_STRUC.POPULATION(Ind_No).LATTICE     = lat;
        OFF_STRUC.POPULATION(Ind_No).numIons     = numIons;
        OFF_STRUC.POPULATION(Ind_No).numBlocks   = numBlocks;
        OFF_STRUC.POPULATION(Ind_No).howCome     = 'CoorMutate';
    end
end

%%%%%%%%%%%%%%% END creating mutants%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

