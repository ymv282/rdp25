function [tvec, sig] = createWaveform(cfg)

% This function generates the tx signal for the AWG. It is a Chirp Sequence
% signal with multiple ramps in time domain.
% 
% INPUT:
% * cfg: configuration struct with parameters
%
% OUTPUT
% * tvec: time vector of whole tx signal
% * sig: tx signal
% 
% Updated: Max Basler - 20.06.2024

% Signal must be a multiple of 64 to fit into AWG memory
tvec = tvec(1:floor(length(tvec)/64)*64);    
sig = sig(1:floor(length(sig)/64)*64);

end