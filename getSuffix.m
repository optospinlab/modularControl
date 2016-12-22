function str = getSuffix(num)
% getSuffix returns the (rounded) number followed by the appropriate {'st', 'nd', 'rd', 'th'}.

    num = round(num);

    if num >= 11 && num <= 13
        str = [num2str(num) 'th'];
        return;
    end

    switch mod(num, 10)
        case 1
            str = [num2str(num) 'st'];
        case 2
            str = [num2str(num) 'nd'];
        case 3
            str = [num2str(num) 'rd'];
        otherwise
            str = [num2str(num) 'th'];
    end
end




