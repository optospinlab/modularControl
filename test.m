function [ output_args ] = test( input_args )
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

tic
for ii = 1:10000
    eval('1.00e3');
end
toc

tic
for ii = 1:10000
    str2double('1.00e3');
end
toc

end

