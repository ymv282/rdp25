function [agilent, interface, status] = connect2AWG(cfg)

    ip = cfg.ip_awg;
    port = cfg.port;

    %interface to AWG
    interface = struct('fp',        0,... % file pointer                          
                       'connected', 0);

    agilent = tcpip(ip, port);

    fopen(agilent);
    % open connection to AWG

    while 1
        [interface, status] = AWG_open(cfg.arbConfig,interface);
        if status == 0
            break;
        else
            fprintf('Unable to connect to AWG...press key to retry'); pause; fprintf('\n');
        end
    end


    % Instrument identification

    fprintf(agilent, '*IDN?');
    IdString = fscanf(agilent, '%s');
    disp(['Verbunden mit: ', IdString]);
    fprintf(agilent, ':INST:IDEN 10'); % leuchtet wenn Instrument erkannt wurde

end