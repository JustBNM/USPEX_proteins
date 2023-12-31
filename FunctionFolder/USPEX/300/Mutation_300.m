function Mutation_300(Ind_No)

%This routine to mutate the parent structure according to a given gaussian distribution.
%If it fails for 1000 times, will return the same structure
%last updated by Qiang Zhu, 2013/10/09

global POP_STRUC
global ORG_STRUC
global OFF_STRUC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% CREATING Mutants by atom positions mutation%%%%%%%%%%%%%%%%%

goodAtomMutant = 0;
goodMutLattice = 0;
safeguard = 0;
count = 1;
while goodAtomMutant + goodMutLattice ~= 2
    count = count + 1;
    if count > 50
        %disp('failed to do mutation in 50 attempts, switch to Random');
        USPEXmessage(508,'',0);
        Random_300(Ind_No);
        break;
    end
    
    toMutate = find(ORG_STRUC.tournament>RandInt(1,1,[0,max(ORG_STRUC.tournament)-1]));
    ind = POP_STRUC.ranking(toMutate(end));
    coor = POP_STRUC.POPULATION(ind).COORDINATES;
    lat  = POP_STRUC.POPULATION(ind).LATTICE;
    numIons = POP_STRUC.POPULATION(ind).numIons;
    order = POP_STRUC.POPULATION(ind).order;
    
    % create a MUTANT.
    [MUT_COORD]= move_all_atom_Mutation(coor, numIons, lat, order, ORG_STRUC.howManyMut*(1-safeguard/100));
    N_Moved = sum(numIons);
    goodAtomMutant = distanceCheck (MUT_COORD, lat, numIons, ORG_STRUC.minDistMatrice);
    goodAtomMutant = ( goodAtomMutant & (CompositionCheck(numIons/ORG_STRUC.numIons)) );
    goodMutLattice = 1; % since we don't change it
    
    if safeguard == 100
        goodAtomMutant = 1; % to avoid eternal cycle
        MUT_COORD = coor; %if all attempts fail. will use the original structure
    end
    
    safeguard = safeguard + 1;
    
    if goodAtomMutant + goodMutLattice == 2
        
        OFF_STRUC.POPULATION(Ind_No).COORDINATES = MUT_COORD;
        OFF_STRUC.POPULATION(Ind_No).LATTICE = lat;
        OFF_STRUC.POPULATION(Ind_No).numIons = numIons;
        OFF_STRUC.POPULATION(Ind_No).howCome = 'CoorMutate';
        
        info_parents = struct('parent', {},'N_Moved', {}, 'enthalpy', {});
        info_parents(1).parent = num2str(POP_STRUC.POPULATION(ind).Number);
        info_parents.N_Moved = N_Moved;
        info_parents.enthalpy = POP_STRUC.POPULATION(ind).Enthalpies(end)/sum(numIons);
        OFF_STRUC.POPULATION(Ind_No).Parents = info_parents;
        disp(['Structure ' num2str(Ind_No) '  generated by mutation']);
    end
    
end

%%%%%%%%%%%%%%% END creating mutants%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

