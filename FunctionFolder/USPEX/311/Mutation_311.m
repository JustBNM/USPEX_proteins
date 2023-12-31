function Mutation_311(Ind_No)

% USPEX Version 9.2.4

global POOL_STRUC
global ORG_STRUC
global OFF_STRUC

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% CREATING Mutants by mutation%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
goodMutant = 0;
goodMutLattice = 0;
count=1;
while goodMutant + goodMutLattice ~= 2
    count=count+1;
    
    IND = chooseGoodComposition(ORG_STRUC.tournament, POOL_STRUC.POPULATION);
    if count > 100 | IND<0
       %disp('failed to do mutation in 100 attempts, switch to Random');
       USPEXmessage(509,'',0);
       Random_311(Ind_No);
       break;
    end
    %toMutate = find (ORG_STRUC.tournament>RandInt(1,1,[0,max(ORG_STRUC.tournament)-1]));
    %IND = toMutate(end);
    MtypeLIST = POOL_STRUC.POPULATION(IND).MtypeLIST;
    numMols   = POOL_STRUC.POPULATION(IND).numMols;
    lattice   = POOL_STRUC.POPULATION(IND).LATTICE;
    numIons   = POOL_STRUC.POPULATION(IND).numIons;
    typesAList= POOL_STRUC.POPULATION(IND).typesAList;
    numBlocks = POOL_STRUC.POPULATION(IND).numBlocks;
    for i = 1:sum(numMols)
       order(i)=POOL_STRUC.POPULATION(IND).MOLECULES(i).order;
    end

    if sum(numMols)<3
       goodMutLattice = 0;
    else
       if ~ORG_STRUC.constLattice
            [MUT_LAT,strainMatrix]= lattice_Mutation(lattice);
            goodMutLattice = latticeCheck(MUT_LAT);
            if ~goodMutLattice
                if count>50
                    MUT_LAT = lattice;
                    goodMutLattice = latticeCheck(MUT_LAT);
                end
            end
       else
        goodMutLattice = 1;
        MUT_LAT=ORG_STRUC.lattice;
       end
   end
  
   if goodMutLattice
%%%%%%%%%Here we just move molecule centers first%%%%%%%%%
        tempMOLS = POOL_STRUC.POPULATION(IND).MOLECULES;
        [MUT_COORD]= move_all_mol_Mutation(tempMOLS, numMols,lattice,order);
        absMUT_COORD= MUT_COORD*MUT_LAT;

        for ind = 1:sum(numMols)
            displacement(ind,:)=absMUT_COORD(ind,:)-tempMOLS(ind).ZMATRIX(1,:);
        end
        for ind = 1:sum (numMols)
            for inder = 1:3
                tempMOLS(ind).MOLCOORS(:,inder) = tempMOLS(ind).MOLCOORS(:,inder) +displacement(ind,inder);
            end
        end
         goodMutant = newMolCheck(tempMOLS,MUT_LAT,MtypeLIST,ORG_STRUC.minDistMatrice);
          if goodMutant+ goodMutLattice == 2
             for inder = 1: sum(numMols)
                 tempMOLS(inder).ZMATRIX = real(NEW_coord2Zmatrix(tempMOLS(inder).MOLCOORS,ORG_STRUC.STDMOL(MtypeLIST(inder)).format));
             end
             OFF_STRUC.POPULATION(Ind_No).MOLECULES = tempMOLS;
             OFF_STRUC.POPULATION(Ind_No).LATTICE =  MUT_LAT;
             OFF_STRUC.POPULATION(Ind_No).numIons = numIons;
             OFF_STRUC.POPULATION(Ind_No).numMols = numMols;
             OFF_STRUC.POPULATION(Ind_No).MtypeLIST = MtypeLIST;
             OFF_STRUC.POPULATION(Ind_No).typesAList = typesAList;
             OFF_STRUC.POPULATION(Ind_No).numBlocks = numBlocks;
             OFF_STRUC.POPULATION(Ind_No).howCome = ' LatMutate ';
            info_parents = struct('parent', {},'N_Moved', {}, 'enthalpy', {});
            info_parents(1).parent=num2str(POOL_STRUC.POPULATION(IND).Number);
            info_parents.enthalpy=POOL_STRUC.POPULATION(IND).enthalpy/sum(numIons);
            info_parents.N_Moved = sum(numMols);
            OFF_STRUC.POPULATION(Ind_No).Parents = info_parents;
            disp(['Structure ' num2str(Ind_No) '  generated by mutation']);
         end
    end
end


