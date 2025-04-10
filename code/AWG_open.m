function [interface, status] = AWG_open(arbConfig,interface)
%opens instrument connection using iqopen function of iq tools
%arbConfig: struct containing connection parameters
%f: serial port connection object
% status = 0: success
% status = 1: error

status = 0;

interface.fp = iqopen(arbConfig);

if isempty(interface.fp)
    status = 1;
else
    fprintf('Connection to AWG was established: \n');
    fprintf('Visa address: %s\n', arbConfig.visaAddr);
    fprintf('Port: %d\n', arbConfig.port)
end



end

