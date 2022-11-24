function str=universalStringConverter(stg,indent,option)
% =========================================================================
% Goal of the function is to convert whatever in string
% Version 1:   Summer 2010                                                             
% Adrien Chopin                        
% -------------------------------------------------------------------------  
% option = 1, which means that cells are read line by line
% instead of columns by columns
% option = 2, which means that cells are read line by line, column by
% colmun whenever they are 2-dim

%define an indent
if ~exist('indent','var')||isempty(indent)==1;indent=0;end
if ~exist('option','var')||isempty(option)==1;option=0;end

%increase the indent for each circular call
indent=indent+5; 
maxindent='                                                          ';
indentChar=maxindent(1:indent);
    %first check for structures 
    if isstruct(stg)
        b=struct2cell(stg);
        n=numel(b);
        names = fieldnames(stg); 
        str=[];
        for i=1:n
            content=b{i};
            contentOk=universalStringConverter(content,indent);
            str=sprintf('%s\n %s%s = %s',str,indentChar,names{i},contentOk);
        end
        stg=str;
    end
    
    %then check for objects
    if isobject(stg)
        names = fieldnames(stg);
        str=[];
        for i=1:numel(names)
           theField=names{i};
           content=universalStringConverter(stg.(theField),indent);
           str=sprintf('%s\n %s%s = %s',str,indentChar,theField,content);
        end
        stg=str;
    end
    
    %then check for cells
    if iscell(stg)
        default =0; %default behavior is to read by index order
        if option==2
            default =1;
        end
        %two case scenario
        %if the cell is 2-dim, just go row by row, column by column
        if default==1 && numel(size(stg))<3
            n=size(stg);
            str=[];
            for i=1:n(1)
                for j=1:n(2)
                    content=stg{i,j};
                    contentOk=universalStringConverter(content,indent);
                    str=sprintf('%s%s\t',str,contentOk);
                end
                str=sprintf('%s\n',str);
            end
            stg=str;
        %go in index order otherwise (option can make it read by column)
        else    
            n=numel(stg);
            str=[];
            inversionList = reshape(1:n,size(stg))';
            for i=1:n
                if option==0
                    content=stg{i};
                else
                    content=stg{inversionList(i)};
                end
                contentOk=universalStringConverter(content,indent);
                str=sprintf('%s\n %s%s',str,indentChar,contentOk);
            end
            stg=str;
        end
    end 

    %then check for matrix > 2D
    if numel(size(stg))>2
      stg=num2str(stg);
    end
    if isnumeric(stg)
      stg=mat2str(stg); 
    end
    
    str=num2str(stg);
end 

function output=cell2str(input)
output=mat2str(cell2mat(input));
end