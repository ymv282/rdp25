function raw_data = getWaveform(rto_1044, cfg)

tic
% Show errors in queue
% fprintf(rto_1044,'SYST:ERR?');

% Read buffer memory of RTO to clear buffer content. Takes a lot of time,
% only use once per measurement
if isfield(cfg, 'clear_buffer') && cfg.clear_buffer == 1
    buffer_content = fscanf(rto_1044,'%s');
    clear buffer_content
end

fprintf(rto_1044,'SING;*WAI');
fprintf('Waiting for the acquisition to finish... ');
toc
fprintf('Fetching waveform in binary format... ');
tic
% Tell AWG to return data
fprintf(rto_1044,'CHAN1:WAV:DATA?');
raw_data_str=fscanf(rto_1044,'%s');
raw_data=textscan(raw_data_str,'%f','Delimiter',',');
raw_data=raw_data{1};
toc
fprintf('Samples count: %d\n', size(raw_data, 1));

end