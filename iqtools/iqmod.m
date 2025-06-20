function varargout = iqmod(varargin)
% Generate I/Q modulation waveform
% Parameters are passed as property/value pairs. Properties are:
% 'sampleRate' - sample rate in Hz
% 'numSymbols' - number of symbols
% 'modType' - modulation type (BPSK, QPSK, OQPSK, QAM4, QAM16, QAM64, QAM256)
% 'oversampling' - oversampling rate
% 'filterType' - pulse shaping filter ('Raised Cosine','Square Root Raised Cosine','Gaussian')
% 'filterNsym' - number of symbols for pulse shaping filter
% 'filterBeta' - Alpha/BT for pulse shaping filter
% 'carrierOffset' - frequency of carriers (can be a scalar or vector)
% 'magnitude' - relative magnitude (in dB) for the individual carriers
% 'newdata' - set to 1 if you want separate random bits to be generated for each carrier
% 'correction' - apply amplitude correction stored in iqampCorrFilename()
% 'quadErr' - quadrature error in degrees
%
% If called without arguments, opens a graphical user interface to specify
% parameters
%
% Thomas Dippon, Agilent Technologies 2011-2013, Keysight Technologies 2014
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED AGILENT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. AGILENT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH AGILENT INSTRUMENTS. 

if (nargin == 0)
    iqmod_gui;
    return;
end
sampleRate = 4.2e9;
numSymbols = 256;
data = 'Random';
modType = 'QAM16';
oversampling = 4;
filterType = 'Root Raised Cosine';
filterNsym = 8;
filterBeta = 0.35;
filename = '';
dataContent = [];
carrierOffset = 0;
magnitude = 0;
quadErr = 0;
iqskew = 0;
gainImb = 0;
newdata = 1;
correction = 0;
normalize = 1;
arbConfig = [];
hMsgBox = [];
i = 1;
while (i <= nargin)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'samplerate';     sampleRate = varargin{i+1};
            case 'numsymbols';     numSymbols = varargin{i+1};
            case 'modtype';        modType = varargin{i+1};
            case 'data';           data = varargin{i+1};
            case 'datacontent';    dataContent = varargin{i+1};
            case 'filename';       filename = varargin{i+1};
            case 'oversampling';   oversampling = varargin{i+1};
            case 'filtertype';     filterType = varargin{i+1};
            case 'filternsym';     filterNsym = varargin{i+1};
            case 'filterbeta';     filterBeta = varargin{i+1};
            case 'carrieroffset';  carrierOffset = varargin{i+1};
            case 'magnitude';      magnitude = varargin{i+1};
            case 'quaderr';        quadErr = varargin{i+1};
            case 'iqskew';         iqskew = varargin{i+1};
            case 'gainimbalance';  gainImb = varargin{i+1};
            case 'newdata';        newdata = varargin{i+1};
            case 'correction';     correction = varargin{i+1};
            case 'normalize';      normalize = varargin{i+1};
            case 'arbconfig';      arbConfig = varargin{i+1};
            case 'hmsgbox';        hMsgBox = varargin{i+1};
            otherwise error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
    end
    i = i+2;
end

%% create a modulator object
offsetmod = 0;
iscpm = 0;
switch upper(modType)
    case 'BPSK';   hmod = modem.pskmod(2);
    case 'BPSK_X'; hmod = modem.pskmod(2, pi/2);
    case 'QPSK';   hmod = modem.pskmod('M', 4, 'PhaseOffset', pi/4, 'SymbolOrder', 'Gray');
    case 'OQPSK';  hmod = modem.pskmod('M', 4, 'PhaseOffset', pi/4, 'SymbolOrder', 'Gray'); offsetmod = 1;
    case '8-PSK';  hmod = modem.pskmod(8, pi/8);
    case 'QAM4';   hmod = modem.qammod(4);
    %case 'QAM8';   hmod = modem.qammod(8);
    case 'QAM16';  hmod = modem.qammod(16);
    case 'QAM32';  hmod = modem.qammod(32);
    case 'QAM64';  hmod = modem.qammod(64);
    case 'QAM128'; hmod = modem.qammod(128);
    case 'QAM256'; hmod = modem.qammod(256);
    case 'QAM512'; hmod = modem.qammod(512);
    case 'QAM1024';hmod = modem.qammod(1024);
    case 'QAM2048';hmod = modem.qammod(2048);
    case 'QAM4096';hmod = modem.qammod(4096);
    case 'APSK16'
        r12 = 2.6;
        cst = [exp(j*2*pi*[0.5:1:3.5]/4) exp(j*2*pi*[0.5:1:11.5]/12)*r12];
        % scramble the constellation to avoid strange spectra
        for cnt = 1:2:length(cst)/2
            k = cnt;
            i = cnt + length(cst)/2;
            tmp = cst(i); cst(i) = cst(k); cst(k) = tmp;
        end
        hmod = modem.genqammod('Constellation', cst, 'InputType', 'integer');
    case 'APSK32'
        r12 = 2.84; r13 = 5.27;
        cst = [exp(j*2*pi*[0.5:1:3.5]/4) exp(j*2*pi*[0.5:1:11.5]/12)*r12 ...
            exp(j*2*pi*[0:15]/16)*r13];
        % scramble the constellation to avoid strange spectra
        for cnt = 1:2:length(cst)/2
            k = cnt;
            i = cnt + length(cst)/2;
            tmp = cst(i); cst(i) = cst(k); cst(k) = tmp;
        end
        hmod = modem.genqammod('Constellation', cst, 'InputType', 'integer');
    case 'PAM4'
        hmod = modem.pammod('M', 4, 'SymbolOrder', 'user-defined', 'SymbolMapping', [3 1 0 2]);
    case 'CPM'
        hmod = modem.pskmod(2);
        iscpm = 1;       
    
	% added by Tom Wychock tom.wychock@keysight.com
    % creates a QAM 8 signal (use this setup to create more custom signals)
    case 'QAM8'
        y1Mag = 1;
        y1States = 4;
        y1Phase = 0;
        
        y2Mag = 2;
        y2States = 4;
        y2Phase = pi/4;
        
        cst = [exp(j*(2*pi*[0:y1States-1]/y1States+y1Phase))*y1Mag...
               exp(j*(2*pi*[0:y2States-1]/y2States+y2Phase))*y2Mag];
        % scramble the constellation (Tom Wychock)
        maproute = [1 6 4 5 7 2 8 3];
        cst = cst(maproute);
        hmod = modem.genqammod('Constellation', cst, 'InputType', 'integer');
        
    otherwise; error('unknown modulation type');
end
% scatterplot(get(hmod, 'Constellation'));

% use the same sequence every time so that results are comparable
randStream = RandStream('mt19937ar'); 
reset(randStream);

%% determine the value of numSymbols (could be reading from file)
sym = generate_sym(numSymbols, length(hmod.Constellation), randStream, data, dataContent, filename);
numSymbols = length(sym);

%% determine the number of samples that we need
% find rational number to approximate the oversampling
[overN overD] = rat(oversampling);
% minimum number of samples that are necessary (must be an integer!)
numSamplesRaw = numSymbols * overN / gcd(overD, numSymbols);
% adjust number of samples to match AWG limitations
arbConfig = loadArbConfig(arbConfig);
numSamples = lcm(numSamplesRaw, arbConfig.segmentGranularity);
% make sure we have at least the minimum number of samples for this AWG
while (numSamples < arbConfig.minimumSegmentSize)
    numSamples = 2 * numSamples;
end
% if the number of samples exceeds the memory size, but the "raw" number of
% samples would fit, ignore the granularity for now and perform arbitrary
% resampling later
if (numSamplesRaw <= arbConfig.maximumSegmentSize && numSamples > arbConfig.maximumSegmentSize)
    numSamples = numSamplesRaw;
    % msgbox('Waveform will be re-sampled to match AWG''s granularity requirements', 'Note', 'replace');
end
% adjust the number of symbols if necessary
newNumSymbols = round(numSamples / overN * overD);
if (numSymbols ~= newNumSymbols)
    sym = repmat(sym, 1, ceil(newNumSymbols / numSymbols));
    sym = sym(1:newNumSymbols);
    numSymbols = newNumSymbols;
end

%% create a filter for pulse shaping
if (overN <= 1)  % avoid error when creating a filter when there is nothing to filter
    filterType = 'None';
end
filt = [];
filterParams = [];
switch (filterType)
    case 'None'
        filt.Numerator = 1;
    case 'Rectangular'
        filt.Numerator = ones(1, overN) / overN;
    case {'Root Raised Cosine' 'Square Root Raised Cosine' 'RRC'}
        filterType = 'Square Root Raised Cosine';
        filterParams = 'Nsym,Beta';
    case {'Raised Cosine' 'RC'}
        filterType = 'Raised Cosine';
        filterParams = 'Nsym,Beta';
    case 'Gaussian'
        filterParams = 'Nsym,BT';
        if (exist('filterBeta', 'var') && filterBeta ~= 0)
            % in MATLAB the BT is given as 1/BT
            filterBeta = 1 / filterBeta;
        end
    otherwise
        error(['unknown filter type: ' filterType]);
end
if (isempty(filt))
    try
        fdes = fdesign.pulseshaping(overN, filterType, filterParams, filterNsym, filterBeta);
        filt = design(fdes);
    catch ex
        errordlg({'Error during filter design. Please verify that' ...
            'you have the "Signal Processing Toolbox" installed' ...
            'MATLAB error message:' ex.message}, 'Error');
    end
end
%fvtool(filt);

%% calculate the relative magnitudes of each carrier in a multi-carrier case
if (isempty(magnitude))
    magnitude = 0;
end
if (length(magnitude) < length(carrierOffset))
    magnitude = reshape(magnitude, length(magnitude), 1);
    magnitude = repmat(magnitude, ceil(length(carrierOffset) / length(magnitude)), 1);
end


%% calculate carrier offsets
%result = zeros(1,len);
result = [];
linmag = 10.^(magnitude./20);
for i = 1:length(carrierOffset)
    if (~isempty(hMsgBox))
        hMsgBox = msgbox(sprintf('Calculating waveform (%d / %d). Please wait...', i, length(carrierOffset)), 'Please wait...', 'replace');
    end
    if (newdata || i == 1)
        iqdata = iqmod_gen(sampleRate, hmod, sym, numSymbols, overN, overD, filt, quadErr, iqskew, gainImb, offsetmod, iscpm, randStream, data, dataContent, filename);
    end
    len = length(iqdata);
    cy = round(len * carrierOffset(i) / sampleRate);
    shiftSig = exp(j * 2 * pi * cy * (linspace(0, 1 - 1/len, len) + randStream.rand(1)));
    if (isempty(result))
        result = zeros(1, len);
    end
    result = result + linmag(i) * (iqdata .* shiftSig);
end
iqdata = result;

%% re-samples, if granularity requirements are not met
if (mod(len, arbConfig.segmentGranularity) ~= 0)
    newLen = ceil(len / arbConfig.segmentGranularity) * arbConfig.segmentGranularity;
    sampleRate = sampleRate * newLen / len;
    if (sampleRate > arbConfig.maximumSampleRate)
        newLen = floor(len / arbConfig.segmentGranularity) * arbConfig.segmentGranularity;
        sampleRate = sampleRate * newLen / len;
    end
    iqdata = iqresample(iqdata, newLen);
end

%% apply amplitude correction if necessary
if (correction)
    iqdata = iqcorrection(iqdata, sampleRate, [], normalize);
end

%% normalize the output
if (normalize)
    scale = max(max(abs(real(iqdata))), max(abs(imag(iqdata))));
    iqdata = iqdata / scale;
end

delete(randStream);
if (nargout >= 1)
    varargout{1} = iqdata;
end
if (nargout >= 2)
    varargout{2} = sampleRate;
end
if (nargout >= 3)
    varargout{3} = numSymbols;
end
end


%% generate a modulated signal
function iqdata = iqmod_gen(fs, hmod, sym, numSymbols, overN, overD, filt, quadErr, iqskew, gainImb, offsetmod, iscpm, randStream, data, dataContent, filename)
if (ischar(data) && strcmpi(data, 'random'))
    sym = generate_sym(numSymbols, length(hmod.Constellation), randStream, data, dataContent, filename);
end
if (iscpm ~= 0)   % no built-in function for CPM modulation
    % modulate_cpm returns a PHASE vector, not IQ. For CPM, we need to run
    % the phase through the pulse shaping filter
    rawIQ = modulate_cpm(sym, overN);
    phOffset = rawIQ(end);   % correct for N * 360� phase offset
else
    rawIQ = upsample(modulate(hmod, sym), overN);
    phOffset = 0;
end
len = length(rawIQ);
nfilt = length(filt.Numerator);
% apply the filter to the raw signal with some wrap-around to avoid glitches
wrappedIQ = [rawIQ(end-mod(nfilt,len)+1:end)-phOffset repmat(rawIQ, 1, floor(nfilt/len)+1)];
%tmp = filter(filt.Numerator, 1, wrappedIQ);
tmp = fftfilt(filt.Numerator, wrappedIQ);
iqdata = tmp(nfilt+1:end);
% for CPM modulation, we now convert phase into I/Q
if (iscpm ~= 0)
    iqdata = exp(j*real(iqdata));
end
% if oversampling was a fraction, downsample by the denominator
if (overD ~= 1)
    iqdata = downsample(iqdata, overD);
end
% for OQPSK, shift Q by 1 symbol
if (offsetmod)
    iqdata = iqdelay(iqdata, fs, 1/2 * (overN / (overD * fs)));
end
% apply quadrature error:  I' = I*cos(phi)+Q*sin(phi) and  Q' = Q
if (quadErr ~= 0)
    qe = quadErr * pi / 180;
    iqdata = complex(real(iqdata) * cos(qe) + imag(iqdata) * sin(qe), imag(iqdata));
end
% apply skew:  I' = delay(I) and  Q' = Q
if (iqskew ~= 0)
    iqdata = iqdelay(iqdata, fs, iqskew);
end
% apply gain imbalance:  I' = gain(I) and  Q' = Q
if (gainImb ~= 0)
    iqdata = complex(real(iqdata) * 10^(gainImb/20), imag(iqdata));
    scale = max(max(real(iqdata)), max(imag(iqdata)));
    if (scale > 1)
        iqdata = iqdata ./ scale;
    end
end
end


%% generate random data stream
function sym = generate_sym(numSymbols, k, randStream, data, dataContent, filename)
% generate symbols
sym = [];
b = floor(log2(k));     % number of bits per symbol (just powers of 2 for now)
numBits = b * numSymbols;
if (ischar(data))
    if (~isempty(strfind(data, 'from file')))
        data = regexprep(data, '(.*) from file', 'User defined $1');
        try
            f = fopen(filename, 'r');
            dataContent = fscanf(f, '%d');
            fclose(f);
        catch ex
            fclose(f);
            dataContent = zeros(numBits, 1);
            errordlg(ex.message);
        end
    end
    switch(lower(data))
        case 'clock'
            if (mod(numSymbols, 2) ~= 0)
                errordlg('Clock pattern requires an even number of symbols');
            end
            sym = repmat([0 k-1], 1, ceil(numSymbols / 2));
        case 'counter'
            if (mod(numSymbols, k) ~= 0)
                errordlg(sprintf('Count pattern requires an multiple of %d symbols', k));
            end
            sym = repmat(linspace(0, k-1, k), 1, ceil(numSymbols / k));
        case 'random'
            data = randStream.rand(1,numBits) < 0.5;
        case 'prbs2^7-1'
            h = commsrc.pn('GenPoly', [7 6 0], 'NumBitsOut', numBits);
            data = 1 - flipud(h.generate())';
        case 'prbs2^9-1'
            h = commsrc.pn('GenPoly', [9 5 0], 'NumBitsOut', numBits);
            data = 1 - flipud(h.generate())';
        case 'prbs2^10-1'
            h = commsrc.pn('GenPoly', [10 7 0], 'NumBitsOut', numBits);
            data = 1 - flipud(h.generate())';
        case 'prbs2^11-1'
            h = commsrc.pn('GenPoly', [11 9 0], 'NumBitsOut', numBits);
            data = 1 - flipud(h.generate())';
        case 'prbs2^15-1'
            h = commsrc.pn('GenPoly', [15 14 0], 'NumBitsOut', numBits);
            data = 1 - flipud(h.generate())';
        case 'user defined symbols'
            numSymbols = length(dataContent);
            dataContent = round(dataContent);
            if (min(dataContent) < 0 || max(dataContent) >= k)
                dataContent(dataContent < 0) = 0;
                dataContent(dataContent >= k) = k - 1;
                errordlg(sprintf('User defined symbols must be in the range 0 to %d', k-1));
            end
            sym = reshape(dataContent, 1, numSymbols);
        case 'user defined bits'
            numBits = length(dataContent);
            dataContent = round(dataContent);
            if (min(dataContent) < 0 || max(dataContent) > 1)
                dataContent(dataContent < 0) = 0;
                dataContent(dataContent > 1) = 1;
                errordlg('User defined bits must use values 0 and 1');
            end
            if (mod(numBits, b) ~= 0)
                errordlg(sprintf('Number of bits must be a multiple of %d', b));
                numBits = floor(numBits / b) * b;
                dataContent = dataContent(1:numBits);
            end
            numSymbols = numBits / b;
            data = reshape(dataContent, numBits, 1);
        otherwise
            errordlg(['undefined data pattern: ' data]);
    end
elseif (isvector(data))     % legacy: data can be a vector of bits
    numBits = length(data);
    % make sure the data is in the correct format
    data = reshape(data, numBits, 1);
else
    error('data must be a string with a predefined data pattern or a vector of bits');
end
if (isempty(sym))
    % convert from numBits of [0..1] to numSymbols of [0..k-1]
    weight = repmat(2.^(0:b-1)', 1, numSymbols);
    data = reshape(data, b, numSymbols);
    sym = sum(weight .* data, 1);
end
end


function phase = modulate_cpm(sym, os)
t = (1:os)/os;
pht = zeros(length(t), 4);
% 4 phase trajectories, depending on previous and current bit
pht(:,1) = -t;
pht(:,2) = -sin(pi*t)/pi;
pht(:,3) = sin(pi*t)/pi;
pht(:,4) = t;
phaseOffset = [-1 0 0 1];
numBits = length(sym);
res = zeros(os, numBits);
flag = sym(numBits);
phMemory = 0;
for k=1:numBits
    % index into array of phase trajectories
    idx = 2*flag + sym(k) + 1;
    flag = sym(k);
    res(:,k) = phMemory + pht(:,idx);
    phMemory = phMemory + phaseOffset(idx);
end 
phase = res(1:end) * pi;
%iq = exp(j*phase);
%n = 100;
%figure(21); plot([res(end-n+1:end) res(1:n)], '.-');
%figure(22); plot([[real(iq(end-n+1:end))' imag(iq(end-n+1:end))']; [real(iq(1:n))' imag(iq(1:n))']], '.-');
end