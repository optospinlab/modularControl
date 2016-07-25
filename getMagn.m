function [char, magn] = getMagn(num)
    chars = 'TZEPTGMkm unpfazy';

    m = floor(log10(num)/3);

    char = chars(9-m);
    if char == ' '
        char = '';
    end

    magn = 1000^m;
end