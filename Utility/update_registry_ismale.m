%This function calls the MySQL procedure which sets the ismale parameter in
%the registry
%
%-Chuck 2026

function update_registry_ismale(ratname,ismale)

%check that inputs are properly formatted
if numel(ratname) ~= 4 || ~ischar(ratname)
    disp('ERROR: ratname input must be a 4 character string')
    return;
end
if ismale ~= 1 && ismale ~= 0
    disp('ERROR: ismale input must be a 0 or a 1');
    return;
end

%do the call to bdata
bdata('call ratinfo.update_registry_ismale("{Si}","{S}")',ismale,ratname);
pause(0.1);

%pull the value from the registry and display it so we know it worked
val = bdata(['select ismale from ratinfo.rats where ratname="',ratname,'"']);
disp(['Registry value for ',ratname,' ismale now equals ',num2str(val)]);


