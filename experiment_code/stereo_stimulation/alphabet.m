function s=alphabet(i)
% If i doesnt exist, gives back an alphabet string
% else, gives back the ith letter of the alphabet
    s='abcdefghijklmnopqrstuvwxyz';
    if exist('i','var')
        s=s(i);
    end
end