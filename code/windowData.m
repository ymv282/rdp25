function windowed_data = windowData(formatted_data, cfg)

% This function is for windowing the raw data. BEst practice is to define a
% window outside this function so that it can be defined in the main file.
%
% INPUT
% * cfg: configuration struct with parameters
%
% OUTPUT
% * windowed_data: windowed radar data in form of a matrix
%
% Updated: Max Basler - 20.06.2024

if isequal(cfg.window_type_R, 'none') && isequal(cfg.window_type_v, 'none')
    windowed_data = formatted_data;
    return
end


end