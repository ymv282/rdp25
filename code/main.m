%% Set the Configuration DO NOT TOUCH

cfg = [];

cfg.ip_rto      = '134.60.27.89'; % string
% Do not use LAN port with this IP adress. It should work without a direct
% LAN connection. If not use IP with 103 at the end and plug LAN cable in
% AWG and Switch
cfg.ip_awg      = '134.60.27.102'; % string

cfg.port        = 5025;

run('iqtools/loadArbConfig.m') %loads arbConfig.mat and transform to struct 
arbConfig.triggerMode = 'Continuous'; %'Continuous','Triggered','Gated'
cfg.arbConfig = arbConfig;

%% User defined radar variables

cfg.Nchirp = ; % number of chirps
cfg.fc = ; % center frequency
cfg.B = ; % Bandwidth of the chirp
cfg.f0 = ; % start frequency
cfg.c_0 = physconst('LightSpeed');
cfg.Tc = ; % duration of a chirp
cfg.Tk = ; % Repetition time of signal
cfg.T_cut_beg = ; % duration cut of the rx signal
cfg.T_cut_end = ; % duration cut of the rx signal
cfg.window_type_R = ; % string: Use 'none' if no window is set
cfg.window_type_v = ; % string: Use 'none' if no window is set
cfg.ZPR = ; % zero padding factor in range dimension
cfg.ZPv = ; % zero padding factor in velocity dimension
cfg.Rlim = ; % limitations of the plot in R dimension in metres
cfg.Vlim = ; % limitations of the plot in v dimension in metres per second

%% User defines RTO settings

%Trigger
cfg.trigger_voltage = '250mV'; % Trigger voltage, string
cfg.trigger_channel = 4; % Set trigger Channel 1-4, 5 for external on the back, double

% Data acquisition --> Use Channel 1 as input
cfg.f_sample_RTO = ; % sampling rate of the RTO, double
cfg.Coupling = ; %DC=50Ohm,DCLimit=1MOhm Dc coupled, AC=1MOhm Ac coupled
% Bandwidth must be enough for acquired beat frequency to work for
% dedicatded range
cfg.AnalogBW = ; % analogue bandwidth: B20=20MHz, B200=200MHz, B800=800MHz, FULL=Full BW
cfg.DigBW = '10e06'; %Range: 100E+3 to 2E+9 Increment: 1000
cfg.clear_buffer = 1;

% Axis Scaling
cfg.timeRange =; % Time range to show on RTO, double
cfg.Scaling = ; % Vertical scaling in volts/division, double

%% User defines AWG settings

% Output parameters
cfg.f_sample = 12e09; % sampling of AWG, double
% Set AWG output to direct
cfg.Rout = 'DAC';
% Set clock of AWG to external --> connect AWG to CLK-out of RTO or use
% frequency genrator. Change to 'INT' to use internal clock
cfg.clk_source_AWG = 'INT';
cfg.clk_freq = '10e6'; % Clock frequency should be 10 MHz, string

% Power
cfg.PoutdBm = ; % AWG output power in dBm
% Calculate Vpp output with dBm output --> double
cfg.Voutpp = ; %peak to peak voltage

%% Show radar limits in console

% Range resolution and maximum range
delta_R = ;
disp("delta_R = " + num2str(delta_R) + " m")
R_max = ;
disp("R_max = " + num2str(R_max) + " m")
% Velocity resolution and maximum velocity
delta_v = ;
disp("delta_v = " + num2str(delta_v) + " m/s")
v_max = ;
disp("v_max = " + num2str(v_max) + " m/s")

%% Open RTO & clear

rto_1044 = connect2RTO(cfg); %you have to take care that the input buffer size is large enough!

%% Open AWG 

[agilent, interface, status] = connect2AWG(cfg);
             
%% RTO Setup

initRTO(rto_1044, cfg); 

%% AWG Setup

initAWG(agilent, cfg);

%% Load file and define sample marker

[tvec, sig] = createWaveform(cfg); % TODO
 
% Set trigger marker
trigger_length = 1;
cfg.samplemarker= [ones(1, trigger_length) zeros(1,length(sig)-trigger_length)];

%% Download waveform to AWG

[interface, status] = download2AWG(interface, status, sig, cfg);

%% Start waveform output
 
if status == 0
    fprintf('The output power is '); fprintf(num2str(cfg.PoutdBm)); %theoratical output power of the AWG!
    fprintf(' dBm and '); fprintf(num2str(cfg.Voutpp)); %V peak peak
    fprintf(' Vpp'); fprintf('\n');
    fprintf('Press any key to start waveform output...'); pause; fprintf('\n');
    [interface, status] = AWG_doRun(interface);
end

%% Acquire Data

% Figure with button to stop measurement acquisition at any time (but not the signal waveform) 
figure(1);
ButtonHandle = uicontrol('Style', 'PushButton', ...
                         'String', 'STOP MEASUREMENT ACQUISITION', ...
                         'Position', [10 10 500 400], ...
                         'FontSize', 18, ...
                         'Callback', 'delete(gcbf)');
                     
counter = 1; %measurement counter

while ishandle(ButtonHandle) 

    raw_data = getWaveform(rto_1044,cfg);
    formatted_data = reshape(raw_data, length(raw_data) / cfg.Nchirp, cfg.Nchirp);

    windowed_data = windowData(formatted_data, cfg); % TODO
    plotWaveform(windowed_data, cfg); drawnow % TODO
    
    fprintf(['Measurements acquired:' num2str(counter) '\r\n'])
    counter = counter+1;

    % Clear buffer only at the first measurement --> Set boolean to 0 after
    % first loop
    if isfield(cfg, 'clear_buffer') && cfg.clear_buffer == 1
        cfg.clear_buffer = 0;
    end

end

%% Stop waveform output 
 
if status == 0
    [interface, status] = AWG_doStop(interface);
end 
fprintf(agilent,':OUTP1 OFF');
fprintf(agilent,':OUTP2 OFF');

%% Close AWG,RTO

fclose(rto_1044);
fclose(agilent);


%% Delete Instrument

delete(rto_1044);
delete(agilent);

%%

clear;
close all;
