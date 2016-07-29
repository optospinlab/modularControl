function peak = mcPeakFinder(data)
% mcPeakFinder finds peaks in 'data' and returns them in cell-array form.

gauss = @(x, a, b, c)( a*exp(-c.*(x-b).^2));


x = 1:512;
y = gauss(1:512, 20+rand*20, rand*512, 1/(100 + 200*rand)^2) + 10*rand([1, 512]);



end
