function [char, magn, str] = getMagn(num)
% getMagn returns the character corresponding to the magnitude (rounded to nearest 3) of num. Also returned is magn, the
%   calculated magnitude of num. It also returns the number in '###.## c' form where c is the character corresponding to the
%   magnitude.
% Status: Finished and commented. Only issue is that it won't handle numbers above Yotta or below yocto.

    if num == 0                             % log10 can't handle zero, so a special case...
        char = '';
        magn = 1;
        str = '0.00 ';
        return;
    elseif num > 0
        m = ceil((log10(num) - 2)/3);       % Each magnitude has its range in (.1, 100].
    else
        m = ceil((log10(-num) - 2)/3);      % log10 can't handle negative numbers, so a special case...
    end

    chars = 'YZEPTGMk munpfazy';            % https://en.wikipedia.org/wiki/Order_of_magnitude#Uses

    char = chars(9-m);                      % This will break if m is out of range.
    if char == ' '
        char = '';      
    end

    magn = 1000^(-m);
    
    str = [num2str(num*magn, '%.2f') ' ' char];
end