function [new_Lattice, strainMatrix, new_Coord]= lattice_atom_Mutation(coord, numIons, lattice, order)

% USPEX Version 8.0.0
% Change: no POP_STRUC dependance anymore 
% lattice + atom mutation based on order

global ORG_STRUC

new_Coord = coord;
max_sigma = ORG_STRUC.howManyMut;
N = sum(numIons);

% in this function both the matrice and the parameter represatation is required, so first we prepare the two
if length(lattice) == 6
 lattice = latConverter(lattice);
end
temp_potLat = latConverter(lattice);
new_Lattice=[];
dummy = 1;

[junk, ranking] = sort(order);  % junk = order(ranking)
r1 = order(ranking(1));
rN = order(ranking(N));

if rN > r1
 for i = 1 : N
  rI = order(ranking(i));
  koef = (rN-rI)/(rN-r1);
  deviat_dist = randn(3,1)*max_sigma*koef;

  new_Coord(ranking(i),1) = coord(ranking(i),1) + deviat_dist(1)/temp_potLat(1);
  new_Coord(ranking(i),2) = coord(ranking(i),2) + deviat_dist(2)/temp_potLat(2);
  new_Coord(ranking(i),3) = coord(ranking(i),3) + deviat_dist(3)/temp_potLat(3);

  new_Coord(ranking(i),1) = new_Coord(ranking(i),1) - floor(new_Coord(ranking(i),1));
  new_Coord(ranking(i),2) = new_Coord(ranking(i),2) - floor(new_Coord(ranking(i),2));
  new_Coord(ranking(i),3) = new_Coord(ranking(i),3) - floor(new_Coord(ranking(i),3));
 end
end


while det(new_Lattice)<0.01 | dummy 
    dummy = 0;
    strainMatrix = zeros(3);
    epsilons = randn(6,1)*ORG_STRUC.mutationRate;
    strainMatrix(1,1) = 1+epsilons(1);
    strainMatrix(2,2) = 1+epsilons(2);
    strainMatrix(3,3) = 1+epsilons(3);
    strainMatrix(1,2) = epsilons(4)/2;
    strainMatrix(2,1) = epsilons(4)/2;
    strainMatrix(1,3) = epsilons(5)/2;
    strainMatrix(3,1) = epsilons(5)/2;
    strainMatrix(2,3) = epsilons(6)/2;
    strainMatrix(3,2) = epsilons(6)/2;
 new_Lattice = lattice*strainMatrix;
end

temp_potLat = new_Lattice;

volLat = det(temp_potLat);
if sign(volLat)==-1
   %disp('the determinant of the lattice generated by heredity is negative'); 
   USPEXmessage(515,'',0);
end
    
 % scale the lattice to the volume we asume it approximately to be
       latVol = det(lattice);
ratio = latVol/volLat;
temp_potLat = latConverter(temp_potLat);
temp_potLat(1:3)= temp_potLat(1:3)*(ratio)^(1/3);
new_Lattice = latConverter(temp_potLat);



