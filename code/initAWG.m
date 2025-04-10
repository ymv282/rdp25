function initAWG(agilent, cfg)

fprintf(agilent,'*RST');
Voutpp = num2str(cfg.Voutpp);

% Set reference clock
fprintf(agilent, [':ROSC:SOUR ' cfg.clk_source_AWG]); 

% set reference clock frequency
fprintf(agilent, [':ROSC:FREQ ' cfg.clk_freq]); 

% output mode : speed mode, 12 bit DAC resolution
fprintf(agilent, ':TRAC:DWID WSP'); 

%output mode: AC with amplifier, DAC direct, ...
fprintf(agilent, [':OUTP:ROUT ' cfg.Rout]);

% output amplitude & offset( AUX SAMPLE MARKER1 )

fprintf(agilent, ':MARK1:SAMP:VOLT:AMPL 0.5'); 
fprintf(agilent,':MARK1:SAMP:VOLT:OFFS 0.250'); 

fprintf(agilent, ':MARK2:SAMP:VOLT:AMPL 0.5'); 
fprintf(agilent,':MARK2:SAMP:VOLT:OFFS 0.250'); 

fprintf(agilent, ':MARK1:SYNC:VOLT:AMPL 0.500');
fprintf(agilent, ':MARK1:SYNC:VOLT:OFFS 0.250'); 

fprintf(agilent, ':MARK2:SYNC:VOLT:AMPL 0.500');
fprintf(agilent, ':MARK2:SYNC:VOLT:OFFS 0.250'); 


% channel 1
fprintf(agilent, [':VOLT1:AMPL ', Voutpp]); % peak to peak voltage
fprintf(agilent,':VOLT1:OFFS 0');

% Set the internal sample frequency at the end of the function to prevent 
% it from being overwritten by other settings.
fprintf(agilent, [':FREQ:RAST ' num2str(cfg.f_sample)]); 

end