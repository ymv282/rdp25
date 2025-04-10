function saveWaveform(acqWaveform, cfg)

current_time = regexp(regexprep(num2str(clock), ' *', '_'), '[^.]*', 'match');
current_time = current_time{1};

save(['../measurements/measurement_' current_time '.mat'], 'acqWaveform', 'cfg');

end