%function USPEX()

% unix('./clean; rm -rf results* structures');

% USPEX version 9.4.1
% here we determine what code to use - EA, VCNEB or metadynamics
[nothing, uspexmode] = unix('echo -e $UsPeXmOdE');
[nothing, USPEXPATH] = unix('pwd');
USPEXPATH(end)=[];

if findstr(uspexmode,'exe')
    [nothing, USPEXPATH] = unix('echo -e $USPEXPATH');
    USPEXPATH(end)=[];
else
    try
        [nothing, nothing] = unix('chmod +x FunctionFolder/Tool/*');
        [nothing, nothing] = unix('chmod +x FunctionFolder/spacegroup/random_2d');
        [nothing, nothing] = unix('chmod +x FunctionFolder/spacegroup/random_cell');
        [nothing, nothing] = unix('chmod +x FunctionFolder/spacegroup/random_cell_mol');
        [nothing, nothing] = unix('chmod +x FunctionFolder/spacegroup/findsym_new');
        [nothing, nothing] = unix('chmod +x clean');
        [nothing, nothing] = unix('rm  Specific/get*');
    catch
        % We do nothing here!!
    end
end

%---------------------------------------------------------------
[nothing,homePath] = unix('pwd');
homePath(end) = [];
path(path,homePath);
path(path,[homePath  '/Submission']);
path(path,[USPEXPATH '/FunctionFolder']);
path(path,[USPEXPATH '/FunctionFolder/sys']);
path(path,[USPEXPATH '/FunctionFolder/AbinitCode']);
path(path,[USPEXPATH '/FunctionFolder/symope']);

whichCode=python_uspex([USPEXPATH '/FunctionFolder/getInput.py'], '-f INPUT.txt -b calculationMethod -c 1');
if isempty(whichCode)
    whichCode = 'USPEX'; % default
else
    whichCode(end) = [];
end


if strcmpi(whichCode, 'USPEX')
    path(path,[USPEXPATH '/FunctionFolder/USPEX']);
    path(path,[USPEXPATH '/FunctionFolder/USPEX/src']);
    path(path,[USPEXPATH '/FunctionFolder/USPEX/PhaseDiagram']);
    path(path,[USPEXPATH '/FunctionFolder/USPEX/Spin']);
    Start();
elseif strcmpi(whichCode, 'VCNEB')
    path([USPEXPATH '/FunctionFolder/VCNEB'], path);
    NEB_Start();
elseif strcmpi(whichCode, 'TPS')
    path([USPEXPATH '/FunctionFolder/TPS'], path);
    TPS_Start();
elseif strcmpi(whichCode, 'PSO')
    path(path,[USPEXPATH '/FunctionFolder/PSO']);
    Start_PSO();
elseif strcmpi(whichCode, 'META')
    path(path,[USPEXPATH '/FunctionFolder/METADYNAMICS']);
    META_Start();
elseif strcmpi(whichCode, 'MINHOP')
    path(path,[USPEXPATH '/FunctionFolder/MINHOP']);
    MINHOP_Start();
end
