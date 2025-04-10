function result = iqdownload_M8196A(arbConfig, fs, data, marker1, marker2, segmNum, keepOpen, channelMapping, sequence, run)
% Download a waveform to the M8196A
% It is NOT intended that this function be called directly, only via iqdownload
%
% T.Dippon, Keysight Technologies 2015
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED AGILENT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. AGILENT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH AGILENT INSTRUMENTS. 

result = [];
save('waveform.mat', 'data', 'fs', 'channelMapping');
res = questdlg('Waveform has been saved to "waveform.mat". Please download this file to M8196A. Press "OK" when you are done.', 'Download', 'OK', 'Cancel', 'OK');
if (strcmp(res, 'Cancel'))
    error('cancelled by user');
end
