function [interface, status] = AWG_doStop(interface)
%stops waveform output
%interface: interface struct
% status = 1: errors ocurred
% status = 0: execution was successfull


if isempty(interface.fp)
    status = 1;
    warning('AWG_doStop: No connection to AWG was established yet (interface is not initialized).');
    
elseif strcmp(interface.fp.Status, 'closed')
    status = 1;
    warning('AWG_doStop: Connection to AWG is closed. Open connection!');
    
else
    
    channelMapping = [1 0; 0 1];

    for i = find(channelMapping(:,1) + channelMapping(:,2))'
        res = xfprintf(interface.fp, sprintf(':ABORt%d', i));
    end
    
    if res ==1
        status = res;
    else
        status = 0;
        fprintf('waveform output stopped...\n');
    end
    
end

end


function retVal = xfprintf(f, s, ignoreError)
% Send the string s to the instrument object f
% and check the error status
% if ignoreError is set, the result of :syst:err is ignored
% returns 0 for success, 1 for errors

    retVal = 0;
% set debugScpi=1 in MATLAB workspace to log SCPI commands
    if (evalin('base', 'exist(''debugScpi'', ''var'')'))
        fprintf('cmd = %s\n', s);
    end
    fprintf(f, s);
    
     while 1
        if strcmp(f.TransferStatus, 'idle') % wait till transfer is done
            break;
        end
    end
    
    query(f, '*opc?'); % check if command is completed
    
    result = query(f, ':syst:err?');
    if (isempty(result))
        %fclose(f);
        errordlg({'The M8190A firmware did not respond to a :SYST:ERRor query.' ...
            'Please check that the firmware is running and responding to commands.'}, 'Error');
        retVal = 1;
        return;
    end
    if (~exist('ignoreError', 'var') || ignoreError == 0)
        while (~strncmp(result, '0,No error', 10) && ~strncmp(result, '0,"No error"', 12))
            errordlg({'M8190A firmware returns an error on command:' s 'Error Message:' result});
            result = query(f, ':syst:err?');
            retVal = 1;
        end
    end
end

