 load oar8Beams2;% This loads the dose influence matrix saved as "cell" variables, oar


% set the indices for different structures;
% e.g., Target = 6, means the 6th dose-influence matrix, oar{6}.influenceM
% is the one for the target.
Target = 7;
Bladder = 1;
Body = 2;
Rectum = 9;
HelpS1 = 6;
HelpS2 = 14;
HelpS3 = 15;
HelpS4 = 16;

% HelpS? are ring (helper) structures.

% calculate number of beamlets
BeamletNum=size(oar{1}.influenceM,2);

dim = BeamletNum; % the dimensionality of optimization problem

for ii=1:num_oar
    IndexSet{ii}=find(logical(sum(oar{ii}.influenceM,2))==1);   % calculate the index of voxels that belongs to structure ii
 
    
end


% explude voxel indices belong the target from the ring structures.
IndexSet{HelpS1}=setdiff(IndexSet{HelpS1},IndexSet{Target});

IndexSet{HelpS2}=setdiff(IndexSet{HelpS2},IndexSet{Target});

IndexSet{HelpS3}=setdiff(IndexSet{HelpS3},IndexSet{Target});

IndexSet{HelpS4}=setdiff(IndexSet{HelpS4},IndexSet{Target});


IndexSet{Body}=setdiff(IndexSet{Body},IndexSet{Target});

IndexSet{Body}=setdiff(IndexSet{Body},IndexSet{HelpS1});

for ii=1:num_oar

    num_voxel_oar(ii)=length(IndexSet{ii});  % calculate number of voxels for structure ii
    
end



% the following uses CVX to solve TPP1 model.

cvx_begin % Here begins the cvx model
cvx_solver Mosek  %specifies Mosek as the solver. Please comment out this line when Mosek is not available
cvx_precision high

%%% WV is the vector of beamlet intensities
variables WV(dim)

%% PPP measures the infeasibility of satisfying the truncated means constraints
variable PPP

%% z1 to z7 are dummy variables to help calculate the truncated means
variables z1(2,  (Target)) z2(2,num_voxel_oar(Bladder)) z3(2,num_voxel_oar(Rectum))
variables z4(2,num_voxel_oar(HelpS1)) z5(2,num_voxel_oar(HelpS2)) z6(2,num_voxel_oar(HelpS3))
variable z7(num_voxel_oar(Body))

minimize(PPP)

%% TM constraints for PTV
24.0-oar{Target}.influenceM(IndexSet{Target},:)*WV<=z1(1,:)';
z1(1,:)>=0;
sum(z1(1,:))/num_voxel_oar(Target)<= 0.2+0.0058+PPP;

oar{Target}.influenceM(IndexSet{Target},:)*WV-25.3<=z1(2,:)';
z1(2,:)>=0;
sum(z1(2,:))/num_voxel_oar(Target)<= 0.08+0.0063+PPP;



%% TM constraints for Bladder
z2(1,:)>=0;
oar{Bladder}.influenceM(IndexSet{Bladder},:)*WV-25.3<=z2(1,:)';  
sum(z2(1,:))/num_voxel_oar(Bladder)<= 0.003+0.0005+PPP;

z2(2,:)>=0;
oar{Bladder}.influenceM(IndexSet{Bladder},:)*WV-6<=z2(2,:)';
sum(z2(2,:))/num_voxel_oar(Bladder)<= 1.4+0.0206+PPP;

%% TM constraints for Rectum
z3(1,:)>=0;
oar{Rectum}.influenceM(IndexSet{Rectum},:)*WV-24.5<=z3(1,:)';
sum(z3(1,:))/num_voxel_oar(Rectum)<= 0+0.0040+PPP;

z3(2,:)>=0;
oar{Rectum}.influenceM(IndexSet{Rectum},:)*WV-10<=z3(2,:)';
sum(z3(2,:))/num_voxel_oar(Rectum)<= 0.9+0.0202+PPP;

%% TM constraints for Helper Structure 1
z4(1,:)>=0;
oar{HelpS1}.influenceM(IndexSet{HelpS1},:)*WV-23.7<=z4(1,:)';
sum(z4(1,:))/num_voxel_oar(HelpS1)<= 0+1e-4+PPP;

z4(2,:)>=0;
oar{HelpS1}.influenceM(IndexSet{HelpS1},:)*WV-8<=z4(2,:)';
sum(z4(2,:))/num_voxel_oar(HelpS1)<= 8+0.0176+PPP;

%% TM constraints for Helper Structure 2
z5(1,:)>=0;
oar{HelpS2}.influenceM(IndexSet{HelpS2},:)*WV-17<=z5(1,:)';
sum(z5(1,:))/num_voxel_oar(HelpS2)<= 0+2e-4+PPP;

z5(2,:)>=0;
oar{HelpS2}.influenceM(IndexSet{HelpS2},:)*WV-10<=z5(2,:)';
sum(z5(2,:))/num_voxel_oar(HelpS2)<= 0.3+0.0496+PPP;

%% TM constraints for Helper Structure 3
z6(1,:)>=0;
oar{HelpS3}.influenceM(IndexSet{HelpS3},:)*WV-23.5<=z6(1,:)';
sum(z6(1,:))/num_voxel_oar(HelpS3)<= 0+PPP;

z6(2,:)>=0;
oar{HelpS3}.influenceM(IndexSet{HelpS3},:)*WV-10<=z6(2,:)';
sum(z6(2,:))/num_voxel_oar(HelpS3)<= 0.6+0.0525+PPP;

%% TM constraints for Body
oar{Body}.influenceM(IndexSet{Body},:)*WV-19.2<=z7;
z7>=0;
sum(z7)/num_voxel_oar(Body)<= 0+PPP;

WV<=30;
WV>=0;
PPP>=0;
cvx_end % this is the end of cvx model

save     WV PPP % saves the output values to file TTPvalue1