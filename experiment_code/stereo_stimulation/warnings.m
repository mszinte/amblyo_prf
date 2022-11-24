function warnings(errorText,dispItNow)
%Warning manager: stocks all the warnings and display it when asked.
%--------------------------------------------------------------------------
%Usage: warnings(errorText,dispItNow): add errorText to the book. If
%       dispItNow=1, disp it at this moment.
%
%        warnings    =>  display all the book
%--------------------------------------------------------------------------
%written nov09 by Adrien Chopin
%To contact me: adrien.chopin@gmail.com
%--------------------------------------------------------------------------

global errorbook
if iscell(errorbook)==0
    errorbook=cell(1);
    errorbook(1,1:2)={'Date and Time' '   Error Book'};
end
if nargin>0
    %if a text is provided, add it to the book
    %time of the error:
    t=dateTime;
    errorbook(end+1,1:2)={t(16:end) ['; Warning: ',errorText]};
    %and disp it too
    if dispItNow==1
        fprintf('\n%s.\n\n',errorText)
    end

else %if the function is called without arg, display the errorbook
    if numel(errorbook)>2
        for i=1:size(errorbook,1)
            errorText=[];
            for j=1:size(errorbook,2)
                errorText=[errorText,char(errorbook(i,j))];
            end
            fprintf('\n%s.',errorText)
        end
        fprintf('\n')
    end
end