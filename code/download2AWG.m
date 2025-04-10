function [interface, status] = download2AWG(interface, status, sig, cfg)
    %specifies properties of download file for AWG
    file = struct('iqdata',             0,... % definition to download file for AWG
                  'sampleFreq',         0,...
                  'segmentNumber',      0,...
                  'normalize',          0,...
                  'downloadToChannel',  0,...
                  'channelMapping',     0,...
                  'sequence',           0,...
                  'marker',             0,...
                  'arbconfig',          0,...
                  'keepOpen',           1,...
                  'run',                0);

    %define file/waveform to download
    file.iqdata = sig;
    file.sampleFreq = cfg.f_sample;
    file.keepOpen = 1; %keep connection open
    file.run = 0;  %do not start waveform output
    file.arbconfig = cfg.arbConfig;
    file.marker = cfg.samplemarker.';

    %adjust trigger mode
    file.arbconfig.triggerMode = 'Continuous';%'Continuous';% 'Triggered'; %'Continuous','Triggered','Gated'

    %download file/waveform to AWG
    % tic
    if status == 0
       [interface,status]= AWG_download(file,interface);
    end
    % toc    
end