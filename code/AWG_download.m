function [interface, status] = AWG_download(file,interface)
%downloads iqdata from file to AWG over interface using iqdownload from
%iqtools
% status = 1: errors ocurred
% status = 0: execution was successfull

arbConfig = file.arbconfig;

if (isempty(file.iqdata))
    status = 1;
    warning('AWG_download: No waveform data exists for download');
    
elseif isempty(interface.fp)
    status = 1;
    warning('AWG_download: No connection to AWG was established yet (interface is not initialized).')
    
elseif strcmp(interface.fp.Status, 'closed')
    status = 1;  
    warning('AWG_download: Connection to AWG is closed. Open first connection');
 
else

    fprintf('Downloading Waveform. Please wait...\n');
    len = numel(file.iqdata);
    iqdata = reshape(file.iqdata, len, 1);
     marker = reshape(file.marker, numel(file.marker), 1);
    rept = lcm(len, arbConfig.segmentGranularity) / len;                    %iqdata has to be a multiple of segmentGranularity
    while (rept * len < arbConfig.minimumSegmentSize)                          %length of iqdata has to be greater than minimumSegmentSize
        rept = rept+1;
    end
  
    interface.fp = iqdownload(repmat(iqdata, rept, 1), file.sampleFreq,...  %download data to AWG using iqdownload from iqtools
              'keepopen' ,file.keepOpen,...
              'arbconfig', file.arbconfig,...
              'run', file.run,...
              'marker', marker);%,...
 %'channelMapping', channelMapping, ...
              %'segmentNumber', segmentNum, ...
%               'marker', repmat(marker, rept, 1));
        
    assignin('base', 'iqdata', repmat(iqdata, rept, 1));                    %new file in workspace containing downloaded sampled IQdata
    
    if strcmp(interface.fp.Status, 'closed')
        status = 1;
        warning('AWG_download: Connection to AWG was closed due to error');
    else
        
        while 1
            if(strcmp(interface.fp.TransferStatus, 'idle'))                % wait till data transfer is done
                break;
            end
        end

        res = query(interface.fp,'*OPC?');
        
        if ~isempty(res)                                                    % check if download command is completed
            
%             if (strcmp(arbConfig.triggerMode,'Triggered'))                   %set advance mode "conditional"
%                   
%                 res1=xfprintf(interface.fp, sprintf(':TRACE1:ADV COND'));  %start waveform output if signal applied to trigger in
%                 res2=xfprintf(interface.fp, sprintf(':TRACE2:ADV COND'));
%                 
%                 if (res1==-1 || res2==-1)
%                     status = 1;
%                     fprintf('setting trigger mode failed.... \n');
%                     return;
%                 end
%          
%                 fprintf('triggered mode has been activated.... \n');
%                 
%             end
            
            status = 0;
            fprintf('finished download.... \n');
            
        else
        
        status = 1;
        fprintf('download failed.... \n');
        
        end      
        
    end
    
    
end


function retVal = xfprintf(f, s, ignoreError)
% Send the string s to the instrument object f
% and check the error status and check if last command is completed
% if ignoreError is set, the result of :syst:err is ignored
% returns 0 for success, 1 for errors

    retVal = 0;
% set debugScpi=1 in MATLAB workspace to log SCPI commands
    if (evalin('base', 'exist(''debugScpi'', ''var'')'))
        fprintf('cmd = %s\n', s);
    end
    
    fprintf(f, s); % send command
    
    while 1
        if strcmp(f.TransferStatus, 'idle') % wait till transfer is done
            break;
        end
    end
    
    query(f, '*opc?'); % check if command is completed
    
    result = query(f, ':syst:err?'); %check if system error ocurred
    if (isempty(result))
        fclose(f);
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




