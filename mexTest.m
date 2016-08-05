function mexTest()
    f = figure;
    uicontrol(f, 'Style', 'push', 'Callback', @mexTest_Callback);
end

function mexTest_Callback(~,~)
    global joystickOn
    
    if isempty(joystickOn)
        joystickOn = 0
    end
    
    if ~joystickOn
        joystickOn = 1
%         t = timer('TimerFcn', @timerFcn, 'ExecutionMode', 'FixedRate', 'TasksToExecute', 1, 'Period', .01);
%         startat(t, now+.1/(60*60*24));
%         t = timer('TimerFcn', @timerFcn, 'ExecutionMode', 'FixedRate', 'Period', .016);
%         startat(t, now+.1/(60*60*24));
%         start(t);
%         wait(t);
%         delete(t);
%         spmd
        mcJoystickDriver(@keyPress_Callback);
%         end
    else
        joystickOn = 0
    end
    
    disp('here');
%     mcJoystickDriver('0');
end

function timerFcn(~,~)
%     pause(.1);
    mcJoystickDriver(@keyPress_Callback);
%     pause(.1);
end

function shouldContinue = keyPress_Callback(src, event) %
    global joystickOn
%     disp('Calling back!');
    disp(event);
    shouldContinue = joystickOn
end