function saveAll(fileMat,fileName)
%fileMat is the file to convert, which is in a mat format
%fileName is the future txt file
    load(fileMat);
    file = fopen(fileName, 'a');
    fprintf(file, ['All data saved at: ', dateTime,'\n']);
    variableList=who;
    for i=1:numel(variableList)
        variableName=variableList{i};
        if strcmp(variableName,'err')==0 %avoids a bug
            content=eval(variableName);
            str=char(universalStringConverter(content));
            fprintf(file,sprintf('%s : %s \n',variableName, str));    
        end
    end
    fclose(file);
end