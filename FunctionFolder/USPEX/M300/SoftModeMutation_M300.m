function SoftModeMutation_M300(Ind_No)

global POP_STRUC
global ORG_STRUC
global OFF_STRUC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%  CREATING Mutants by atom positions mutation  %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
goodAtomMutant = 0;

toMutate = find(ORG_STRUC.tournament>RandInt(1,1,[0,max(ORG_STRUC.tournament)-1]));
ind = POP_STRUC.ranking(toMutate(end));

GB_order  =  POP_STRUC.POPULATION(ind).GB_order;
GB_LATTICE = POP_STRUC.POPULATION(ind).GB_LATTICE;
GB_numIons = POP_STRUC.POPULATION(ind).GB_numIons;
GB_atyp    = POP_STRUC.POPULATION(ind).GB_typesAList;
father = POP_STRUC.POPULATION(ind).GB_COORDINATES;
N = sum(GB_numIons);
bulk_lat    =ORG_STRUC.bulk_lat;
bulk_pos    =ORG_STRUC.bulk_pos;
bulk_atyp   =ORG_STRUC.bulk_atyp';
bulk_numIons=ORG_STRUC.bulk_ntyp;
numIons = GB_numIons + bulk_numIons;
FINGERPRINT = POP_STRUC.POPULATION(ind).FINGERPRINT;
flag = 0;
for j = 1 : length(POP_STRUC.SOFTMODEParents)
    dist_ij = cosineDistance(FINGERPRINT, POP_STRUC.SOFTMODEParents(j).fingerprint, ORG_STRUC.weight);
    if dist_ij < ORG_STRUC.toleranceFing
        flag=1;
        ID=j;
        break;    %since we already run out of all the choices, exit 
    end        % Loop: cosine_dist
end          % Loop: comparison with parent database

[freq, eigvector] = calcSoftModes(ORG_STRUC.NvalElectrons, ORG_STRUC.valences, GB_numIons, GB_LATTICE, father );
 freq = diag(freq);
[freq, IX] = sort(freq);
non_zero=0;

if flag == 1
   M2 = sum(eigvector(:,IX(POP_STRUC.SOFTMODEParents(ID).Softmode_num)).^2);
   M4 = sum(eigvector(:,IX(POP_STRUC.SOFTMODEParents(ID).Softmode_num)).^4);
   participation_ratio = M2/M4; % for more details see, f.e., S.Elliott book
   last_good = POP_STRUC.SOFTMODEParents(ID).Softmode_Fre;

   for i = 1:length(freq)
       M2 = sum(eigvector(:,IX(i)).^2);
       M4 = sum(eigvector(:,IX(i)).^4);
       pr1 = M2/M4;
       if (freq(i) > (1.05)*last_good) | ((freq(i) >= last_good) & (abs(1-participation_ratio/pr1) > 0.05))
          non_zero = i;
          break
       end
   end
else
   for i = 1:length(freq)        % first non zero element, should usually be 4       
       if freq(i) > 0.0000001
          non_zero = i;
          break;
       end
    end
end


if non_zero >0
   loop = 0;
   current_freq = non_zero;
   good_freq = non_zero;
   for f = good_freq : non_zero + round((3*N-non_zero)/2)  % about middle of the freq spectra if we ignore the degeneracy
       if loop==1
          break
       else
         for i = 0 : 20
            if rand > 0.5
              [MUT_LAT, MUT_COORD, deviation] = move_along_SoftMode_Mutation(father, GB_numIons, GB_LATTICE, eigvector(:,IX(f)), 1-i/21);
            else
              [MUT_LAT, MUT_COORD, deviation] = move_along_SoftMode_Mutation(father, GB_numIons, GB_LATTICE, -1*eigvector(:,IX(f)), 1-i/21);
            end
           [lat, candidate, typesAList, chanAList] = makeGB(numIons, GB_LATTICE, MUT_COORD, GB_atyp, bulk_lat, bulk_pos, bulk_atyp, ORG_STRUC.vacuumSize(1));
            goodAtomMutant = distanceCheck(candidate, lat, numIons, ORG_STRUC.minDistMatrice);
            if goodAtomMutant == 1
               loop=1;
               break;
            elseif (i == 21) & (f == non_zero + round((3*N-non_zero)/2))
              break;
            end
         end
      end  %if loop==1
      good_freq=good_freq+1;
   end  %% Outer loop, freq++ 

   if goodAtomMutant == 1   % we start to create this
        OFF_STRUC.POPULATION(Ind_No).Bulk_LATTICE=bulk_lat;
        OFF_STRUC.POPULATION(Ind_No).Bulk_COORDINATES=bulk_pos;
        OFF_STRUC.POPULATION(Ind_No).Bulk_typesAList=bulk_atyp;
        OFF_STRUC.POPULATION(Ind_No).Bulk_numIons=bulk_numIons;
        OFF_STRUC.POPULATION(Ind_No).numIons = numIons;
        OFF_STRUC.POPULATION(Ind_No).LATTICE = lat;
        OFF_STRUC.POPULATION(Ind_No).COORDINATES = candidate;
        OFF_STRUC.POPULATION(Ind_No).typesAList = typesAList;
        OFF_STRUC.POPULATION(Ind_No).chanAList=chanAList;
        OFF_STRUC.POPULATION(Ind_No).GB_COORDINATES = MUT_COORD;
        OFF_STRUC.POPULATION(Ind_No).GB_LATTICE = GB_LATTICE;
        OFF_STRUC.POPULATION(Ind_No).GB_numIons = GB_numIons;
        OFF_STRUC.POPULATION(Ind_No).GB_typesAList = GB_atyp;
        info_parents = struct('parent', {},'mut_degree', {},'mut_mode',{},'mut_fre',{}, 'enthalpy', {});
        info_parents(1).parent = num2str(POP_STRUC.POPULATION(ind).Number);
        info_parents.mut_degree = deviation;
        info_parents.mut_mode=f;
        info_parents.mut_fre=freq(f);
        info_parents.enthalpy = POP_STRUC.POPULATION(ind).Enthalpies(end)/sum(numIons);
        OFF_STRUC.POPULATION(Ind_No).Parents = info_parents;
        OFF_STRUC.POPULATION(Ind_No).howCome = 'softmutate';

        disp(['Structure ' num2str(Ind_No) '  generated by softmutation']);

       if flag == 1
          POP_STRUC.SOFTMODEParents(ID).Softmode_Fre=freq(f);
          POP_STRUC.SOFTMODEParents(ID).Softmode_num=f;
       else
          POP_STRUC.SOFTMODEParents(end+1).lattice=MUT_LAT;
          POP_STRUC.SOFTMODEParents(end).coordinates=father;
          POP_STRUC.SOFTMODEParents(end).fingerprint=FINGERPRINT;
          POP_STRUC.SOFTMODEParents(end).Softmode_Fre=freq(f);
          POP_STRUC.SOFTMODEParents(end).Softmode_num=f;
          POP_STRUC.SOFTMODEParents(end).numIons = GB_numIons;
       end
   else
      Mutation_M300(Ind_No);
   end
else
   Mutation_M300(Ind_No);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%   END creating mutants   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
