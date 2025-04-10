function [interface, status] = AWG_doRun(interface)
% start waveform output on AWG
% interface: interface struct
% arbConfig: arbConfig struct
% status = 1: errors ocurred
% status = 0: execution was successfull 


if isempty(interface.fp)
    status = 1;
    warning('AWG_doRun: No connection to AWG was established yet (interface is not initialized).');
    
elseif strcmp(interface.fp.Status, 'closed')
    status = 1;
    warning('AWG_doRun: Connection to AWG is closed. Open first connection');
else
    
    channelMapping = [1 0; 0 1];
    % turn on channel coupling only if download to both channels
    % otherwise keep the previous setting. If the user wants de-coupled
    % channels, he has to do that in the SFP or outside this script
    if (length(find(channelMapping(:,1) + channelMapping(:,2))) > 1)
        res = xfprintf(interface.fp, ':INSTrument:COUPle:STATe ON');
    end
    
    if res == 1
        status = res;
        fprintf('Waveform output command failed...\n');
        return;
    end 
    
    %send command for waveform output
    for i = find(channelMapping(:,1) + channelMapping(:,2))'
        res = xfprintf(interface.fp, sprintf(':INIT:IMMediate%d', i));
    end
    
    if res == 1
        status = res;
        fprintf('Waveform output command failed...\n');
    else
        status = 0;
        fprintf('Waveform output started...\n');
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


