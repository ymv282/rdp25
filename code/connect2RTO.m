function rto_1044 = connect2RTO(cfg)

    ip = cfg.ip_rto;
    port = cfg.port;
    f_sample_RTO = cfg.f_sample_RTO; % double

    rto_1044 = tcpip(ip, port);

    fopen(rto_1044);

    fprintf(rto_1044,'*RST'); 
    fprintf(rto_1044,'*CLS'); 
    fprintf(rto_1044, 'CHAN1:COUP DC');

    % Set Timeout RTO

    fclose(rto_1044);

    % Set the buffer size --> set in bytes (8 bit)
    % Factor 10 added for creating sufficient buffer size
    rto_1044.InputBufferSize=(cfg.Nchirp*cfg.Tc)*f_sample_RTO*2*40;
    % Set the timeout value
    rto_1044.Timeout = 10;


    fopen(rto_1044);
    % Instrument identification

    fprintf(rto_1044, '*IDN?');
    IdString = fscanf(rto_1044, '%s');
    disp(['Verbunden mit: ', IdString]);

end