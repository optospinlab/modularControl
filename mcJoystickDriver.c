#include <mex.h>
#define WIN32_LEAN_AND_MEAN
#include <pthread.h>
#include <Windows.h>
#include <mmsystem.h>

#define VERBOSE 1

#define deadZoneTrigger 32
#define deadZoneThumb 4096
    
bool shouldContinue = true;
    
void notifyMatlabOfEvent(mxArray* matlab, int id, int type, int axis, float value) {
    mxArray* src = mxCreateDoubleScalar(id);
    
    const char* fields[] =  {"id", "type", "axis", "value"};
    mwSize dims[1] = { 1 };
    mxArray* event = mxCreateStructArray((mwSize)1, dims, 4, fields);
    mxSetField(event, 0, "id",      mxCreateDoubleScalar(id));      // Event id =       Joystick id
    mxSetField(event, 0, "type",    mxCreateDoubleScalar(type));    // Event type =     { 0=no_connection, 1=button, 2=trigger, 3=axis }
    mxSetField(event, 0, "axis",    mxCreateDoubleScalar(axis));    // Event axis =     { buttons: 1-16, triggers: 1-2, axes: 1-4 }
    mxSetField(event, 0, "value",   mxCreateDoubleScalar(value));   // Event value =    { buttons: 0 or 1, triggers: .125-1, axes: (-1)-(-.125) or .125-1 }
    
    mxArray* plhs[3] = {matlab, src, event};
//     mxArray* plhs[3];
//     plhs[0] = matlab;
//     plhs[1] = src;
//     plhs[2] = event;
    mxArray* prhs[1];
    
    mexCallMATLAB(1, prhs, 3, plhs, "feval");
//     mexCallMATLAB(0, 0, 3, plhs, "feval");
    double* data = mxGetPr(prhs[0]);
    
    shouldContinue = data[0];
    mexPrintf("Continuing? %d\n", shouldContinue);
}

void axesFunc(mxArray* matlab, int id, int axis, int value){
    if (abs(value - 32767) > deadZoneThumb)
        notifyMatlabOfEvent(matlab, id, 3, axis, max((float)-1, (((float)value)-32767.)/32767.));
}

void* loop(void* argin){
    int i = 0;
    int j = 0;
    int id = -1;
    JOYINFOEX state;
    
    DWORD  dwButtonsPrev = 0;
    DWORD  dwPOVPrev = 0;
    DWORD  dwZposPrev = 0;
    
    mxArray* matlab = (mxArray*)argin;
    
    state.dwSize = sizeof(JOYINFOEX);
    state.dwFlags = JOY_RETURNALL | JOY_RETURNCENTERED;
    
//     while (shouldContinue) {    // Infinite loop
//         mexCallMATLAB(0, NULL, 0, NULL, "drawnow");
//         mexCallMATLAB(0, NULL, 0, NULL, "pause(.016);");
        mexEvalString("drawnow; pause(1);");
//         mexEvalString("disp(.016);");
//         mexCallMATLAB(0, NULL, 0, NULL, "disp('frame');");
//         mexPrintf("here1");
//         if (utIsInterruptPending()){
//             return;
//         }
//         Sleep(16);              // 60Hz
//         while ( id == -1){      // While a controller has not been found, check every 1 second for a controller.
            i = 0;
            while (i < 15 && id == -1){  // Apparently, for loops are not allowed...
                if (joyGetPosEx(i, &state) == JOYERR_NOERROR) { id = i; }
                
                i++;
            }
//              Sleep(1000);
//         }
        
//         mexPrintf("here2");
        if (joyGetPosEx(id, &state) != JOYERR_NOERROR) { // If getting the state was unsuccessful...
            id = -1;                                        // ...return to polling for a connection.
        }
        else {                                              // Otherwise, check for changes in the state.
            //// Buttons ////
            WORD buttonChanged = dwButtonsPrev ^ state.dwButtons;
            if (buttonChanged) {            // If there has been a change in the buttons...
                j = 1;
//                 for (int i = 1; i <= 16; i++)  // ...then check buttons 1 -> 16 too see which changed.
                i = 1;
                while (i <= 32) {   // Apparently, for loops are not allowed...
                    if (buttonChanged & j) {    // If button i has changed,...
                        notifyMatlabOfEvent(matlab, id, 1, i, (state.dwButtons & j) > 0);
                    }
                    j *= 2;
                    i++;
                }
            }
            dwButtonsPrev = state.dwButtons;  // Remember what the button state is so that we can check for changes next time.
            
//             //// Triggers ////
//             if (state.Gamepad.bLeftTrigger > deadZoneTrigger)   // If the left trigger is pressed enough...
//                 notifyMatlabOfEvent(matlab, id, 2, 1, state.Gamepad.bLeftTrigger/255);
//             if (state.Gamepad.bRightTrigger > deadZoneTrigger)  // If the right trigger is pressed enough...
//                 notifyMatlabOfEvent(matlab, id, 2, 2, state.Gamepad.bRightTrigger/255);
            
            if (state.dwPOV != dwPOVPrev){
                notifyMatlabOfEvent(matlab, id, 2, 1, ((float)state.dwPOV)/100.);
                dwPOVPrev = state.dwPOV;
            }
            
            //// Thumb Axes ////
//             mexPrintf("...Axis X with value %d.\n", state.dwXpos);
            axesFunc(matlab, id, 1, state.dwXpos);  //X
            axesFunc(matlab, id, 2, state.dwYpos);  //Y
            axesFunc(matlab, id, 3, state.dwRpos);  //Z
            
            if (state.dwZpos != dwZposPrev){        // Throttle
                notifyMatlabOfEvent(matlab, id, 4, 1, ((float)state.dwZpos)/65535.);
                dwZposPrev = state.dwZpos;
            }
            
//             axesFunc(matlab, id, 3, state.dwZpos);
//             axesFunc(matlab, id, 5, state.dwUpos);
//             axesFunc(matlab, id, 6, state.dwVpos);
        }
//     }
    
    notifyMatlabOfEvent(matlab, -3, 0, 0, 0);
}

/* The gateway function - think of it as main() */
void mexFunction(int nlhs, mxArray *plhs[],         // Number-of/Array-for output (left-side) arguments.
                 int nrhs, const mxArray *prhs[])   // Number-of/Array-for of input (right-side) arguments.
{
    // Will add more...
    
    mexPrintf("number output arguments: %d \n", nlhs);
    
//     notifyMatlabOfEvent(prhs[0], -2, 0, 0, 0);
//     sleep(1);
//     mexPrintf("0\n");
//     notifyMatlabOfEvent(prhs[0], -3, 0, 0, 0);
//             sleep(1);
//     notifyMatlabOfEvent(prhs[0], -3, 4, 5, 5.2);
//             sleep(1);
            
    loop((void*)prhs[0]);
    
//     pthread_attr_t attr;
// //     mexPrintf("1\n");
// 	pthread_attr_init(&attr);
// //     mexPrintf("2\n");
// //     pthread_attr_setdetachstate(&attr,PTHREAD_CREATE_DETACHED);
// //     mexPrintf("3\n");
// 
//     pthread_t thread;
//     int success = pthread_create(&thread, &attr, &loop, (void*)prhs[0]);
// //     mexPrintf("4\n");
//     
// //     pthread_attr_destroy(&attr);
// //     mexPrintf("5\n");
// 
//     if (nlhs == 1) {         // If it is desired, return the thread identifier.
//         if (success) {  plhs[0] = mxCreateDoubleScalar(thread); } 
//         else         {  plhs[0] = 0; }
//     }
// //     mexPrintf("6\n");
    
//     sleep(10);
//     pthread_cancel(&thread);
}

