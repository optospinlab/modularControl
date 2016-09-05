classdef mcPID < handle
% Simple PID of the form: y = mcPID.compute(x), where y is the output and x is the feedback var
    
    properties
        Kp = 0;
        Ki = 0;
        Kd = 0;
        
        ePrev = 0;
        int = 0;
        
        xt = 0;
        y = 0;
        
        yInfo = [];
        yIsAxis = false;
    end
    
    methods
        function pid = mcPID(vargin)
            if isa(vargin, 'mcAxis')
                pid.yInfo = vargin;
                pid.yInfoIsAxis = true;
            else
                switch nargin
                    case 0
                        pid.xt = 0;
                        pid.yInfo.limits = [-Inf, Inf];
                    case 1
                        pid.xt = vargin;
                        pid.yInfo.limits = [-Inf, Inf];
                    case 2
                        pid.xt = vargin{1};
                        pid.yInfo.limits = vargin{2};
                end
            end
        end
        
        function setTarget(pid, xt)
            pid.xt = xt;
        end
        
        function y = compute(pid, x)
            e = pid.xt - x;
            pid.int = pid.int + e;
            
            pid.y = pid.y + pid.Kp*e + pid.Kd*(pid.ePrev - e) + pid.Ki*pid.int;
            
            pid.ePrev = e;
            
            if  pid.y < min(limits)
                pid.y = min(limits);
            end
            if  pid.y > max(limits)
                pid.y = max(limits);
            end
            
            y = pid.y;
        end
    end
    
end

