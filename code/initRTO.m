function initRTO(rto_1044, cfg)
    

fprintf(rto_1044, 'CHAN1:STAT ON');


% Trigger Setup, do not touch

fprintf(rto_1044,'TRIG1:ANED:COUP DCLimit');%DCLimit --> 1MOhm

% Select trigger source
switch cfg.trigger_channel
    case 1
        fprintf(rto_1044, 'TRIG1:SOUR CHAN1'); % Trigger Source
        fprintf(rto_1044, ['TRIG1:LEV1 ' cfg.trigger_voltage]); %Which voltage triggers
    case 2
        fprintf(rto_1044, 'TRIG1:SOUR CHAN2'); % Trigger Source
        fprintf(rto_1044, ['TRIG1:LEV2 ' cfg.trigger_voltage]); %Which voltage triggers
    case 3
        fprintf(rto_1044, 'TRIG1:SOUR CHAN3'); % Trigger Source
        fprintf(rto_1044, ['TRIG1:LEV3 ' cfg.trigger_voltage]); %Which voltage triggers
    case 4
        fprintf(rto_1044, 'TRIG1:SOUR CHAN4'); % Trigger Source
        fprintf(rto_1044, ['TRIG1:LEV4 ' cfg.trigger_voltage]); %Which voltage triggers
    case 5
        fprintf(rto_1044, 'TRIG1:SOUR EXT'); % Trigger Source
        fprintf(rto_1044, ['TRIG1:LEV5 ' cfg.trigger_voltage]); %Which voltage triggers
    otherwise
        warning("The trigger sourcce is not set correctly. Set it to a value between 1-5. For now channel 4 is used as default input")
        fprintf(rto_1044, 'TRIG1:SOUR CHAN4'); % Trigger Source
        fprintf(rto_1044, ['TRIG1:LEV4 ' cfg.trigger_voltage]); %Which voltage triggers
end


fprintf(rto_1044,'TRIG1:MODE NORM'); %Trigger only if a waveform occures
fprintf(rto_1044, 'TIM:HOR:POS 0');
fprintf(rto_1044, 'TIM:REF 0');

%% those are often used commands

% Resolution 
fprintf(rto_1044, 'ACQ:POIN:AUTO RES');
fprintf(rto_1044, 'ACQ:POIN:MAX 80E6');

% Offset
fprintf(rto_1044, 'CHAN1:OFFS 0V');

% Setup
% Channel Coupling
fprintf(rto_1044, ['CHAN1:COUP ' cfg.Coupling]); % set coupling mode
fprintf(rto_1044, ['TIM:RANG ' num2str(cfg.timeRange)]); % scale time axis
fprintf(rto_1044, 'EXP:WAV:SOUR C1W1');
fprintf(rto_1044, 'EXP:WAV:RAW ON');
fprintf(rto_1044, 'ACQ:POIN:AADJ OFF');
fprintf(rto_1044, ['CHAN1:SCAL ' num2str(cfg.Scaling)]); % scale volts per division
fprintf(rto_1044, ['CHAN1:BAND ' cfg.AnalogBW]); 
fprintf(rto_1044, 'CHAN1:DIGF:CUT 3e6'); % !!!!
fprintf(rto_1044, 'CHAN1:DIGF:STAT 1');   

% Set the internal sample frequency at the end of the function to prevent 
% it from being overwritten by other settings.
fprintf(rto_1044, ['ACQ:SRAT ', num2str(cfg.f_sample_RTO)]);
    
end