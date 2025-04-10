
%RTO Open
rtb = VISA_Instrument('TCPIP::134.60.27.83::INSTR');
%Setup
fprintf(rto_1044,'TIM:HOR:POS 0');
fprintf(rto_1044, 'TIM:REF 0');
fprintf(rto_1044,['TIM:RANG ' num2str(Nchirp * (Tup+Tdown))]);
fprintf(rto_1044,'EXP:WAV:SOUR C1W1');
%fprintf(rto_1044,'EXP:WAV:SCOP MAN');
%fprintf(rto_1044,'EXP:WAV:STAR 0');
%fprintf(rto_1044,['EXP:WAV:STOP ', num2str(Nchirp * Tc)]);
fprintf(rto_1044,'EXP:WAV:RAW ON');
fprintf(rto_1044,'ACQ:POIN:AADJ OFF');
fprintf(rto_1044,'ACQ:SRAT 2e6');
%fprintf(rto_1044, ['ACQ:POINT ' num2str(Nchirp * 20e6 * Tc + mod(Nchirp * 20e6 * Tc,2))]);
fprintf(rto_1044, 'CHAN1:SCAL 1e-3');

rtb.SetTimeoutMilliseconds(10000); 
rtb.Write('SING');
fprintf('Waiting for the acquisition to finish... ');
tic
rtb.QueryString('*OPC?'); 
toc
fprintf('Fetching waveform in binary format... ');
tic
waveformBIN = rtb.QueryBinaryFloatData('FORM:BORD LSBF;:FORM REAL;:CHAN1:DATA?', false);
% waveformBIN1 = rtb.QueryBinaryFloatData('FORM:BORD LSBF;:FORM REAL;:CHAN2:DATA?', false);
toc
fprintf('Samples count: %d\n', size(waveformBIN, 2));