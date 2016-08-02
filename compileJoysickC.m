function compileJoysickC()
% compileJoystickC, as the name sugests, compiles the C code in mcJoystickDriver.c into .mexw64 form. winmm.lib and
%   mcJoystickDriver.c must be in the same directory for this to work properly.
% Status: Finished.
    mex mcJoystickDriver.c -lwinmm -v
end