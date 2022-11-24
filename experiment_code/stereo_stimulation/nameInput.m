function [nameId,choice]=nameInput
%safely ask for a name to save file;
%if file already exists, dont erases it but prompts for creating another one
nameId = input('Enter subject ID:  ', 's');

if exist([cd,filesep,nameId,'.mat'],'file')
    choice = str2double(input('SID exists already... add numbers (new sbject: 1) or use it (load data: 2)?', 's'));
    if choice==1
     str=floor(now);
     nameId = [nameId '_' num2str(str)];
     disp(['New ID: ',nameId])
    end
else
    choice=1;
end