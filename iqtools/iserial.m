function [samples, sampleRate] = iserial(varargin)
% This function generates a waveform from a digital data stream
% and adds selected distortions
%
% Parameters are passed as property/value pairs. Properties are:
% 'dataRate' - data rate in symbols/s
% 'transitionTime' - rise/fall time in UI (default: 0.5)
% 'numBits' - number of bits to be generated (default: 128)
% 'data' - can be 'clock', 'random', 'MLT-3', 'PAM3', 'PAM4', 'PAM5'
%        'PRBS7', 'PRBS9', 'PRBS11', 'PRBS15' or a vector of values in the
%        range [0...1]
% 'noise' - amount of noise added, range [0...1] (default: 0)
% 'noiseFreq' - frequency of the noise in Hz or zero for gaussian noise
% 'isi' - amount of ISI in the range [0...1] (default = 0)
% 'SJfreq' - sinusoidal jitter frequency in Hz (default: no jitter)
% 'SJpp' - sinusoidal jitter in UI
% 'RJpp' - 6-sigma value in UI
% 'sampleRate' - sample rate in Hz (if zero or not specified, the
%                default sample rate for the selected AWG is used
% 'amplitude' - data will be in the range (-ampl...+ampl) + noise
% 'dutyCycle' - will skew the duty cycle (default: 0.5)
% 'correction' - apply frequency/phase response correction
% 'precursor' - list of values in dB (default: empty)
% 'postcursor' - list of values in dB (default: empty)
% 'nowarning' - can be set to '1' to suppress warning messages (default: 0)
%
% If called without arguments, opens a graphical user interface to specify
% parameters

% T.Dippon, Agilent Technologies 2011-2013, Keysight Technologies 2014-2015
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED AGILENT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. AGILENT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH AGILENT INSTRUMENTS. 

%% if called without arguments, open the GUI
if (nargin == 0)
    iserial_gui;
    return;
end
% set default parameters
samples = [];
sampleRate = 0;
dataRate = 1e9;
ttUI = .5;
numBits = -1;
data = 'random';
isi = 0;
SJfreq = 10e6;
SJpp = 0;
RJpp = 0;
noise = 0;
noiseFreq = 20e6;
amplitude = 1;
dutyCycle = 0.5;
preCursor = [];
postCursor = [];
nowarning = 0;
correction = 0;
sscFreq = 0;
sscDepth = 0;
levels = [];
% parse input parameters
i = 1;
while (i <= nargin)
    if (ischar(varargin{i}))
        switch lower(varargin{i})
            case 'datarate';     dataRate = varargin{i+1};
            case 'transitiontime'; ttUI = varargin{i+1};
            case 'numbits';      numBits = varargin{i+1};
            case 'data';         data = varargin{i+1};
            case 'levels';       levels = varargin{i+1};
            case 'isi';          isi = varargin{i+1};
            case 'noisefreq';    noiseFreq = varargin{i+1};
            case 'noise';        noise = varargin{i+1};
            case 'sjfreq';       SJfreq = varargin{i+1};
            case 'sjpp';         SJpp = varargin{i+1};
            case 'rjpp';         RJpp = varargin{i+1};
            case 'sscfreq';      sscFreq = varargin{i+1};
            case 'sscdepth';     sscDepth = varargin{i+1};
            case 'samplerate';   sampleRate = varargin{i+1};
            case 'amplitude';    amplitude = varargin{i+1};
            case 'dutycycle';    dutyCycle = varargin{i+1};
            case 'precursor';    preCursor = varargin{i+1};
            case 'postcursor';   postCursor = varargin{i+1};
            case 'nowarning';    nowarning = varargin{i+1};
            case 'correction';   correction = varargin{i+1};
            otherwise error(['unexpected argument: ' varargin{i}]);
        end
    else
        error('string argument expected');
    end
    i = i+2;
end
% make sure that SJfreq and SJpp have the same length
numSJ = max(length(SJfreq), length(SJpp));
SJfreq = fixlength(SJfreq, numSJ);
SJpp = fixlength(SJpp, numSJ);

if (numBits < 0)
    numBits = length(data);
end

arbConfig = loadArbConfig();
numBitsOld = numBits;
if (sampleRate ~= 0)    % sample rate is defined by the user
    fsApprox = sampleRate;
    % if sample rate AND data rate are given, round the number of bits
    % to match the granularity requirement
    [n d] = rat(fsApprox / dataRate / arbConfig.segmentGranularity);
    numBits = ceil(numBits / d) * d;
else
    % sample rate automatic --> start with the default sample
    fsApprox = arbConfig.defaultSampleRate;
end
% approximate number of samples per bit
spbApprox = fsApprox / dataRate;
% check if the number of bits is large enough to find a valid sample rate
if (arbConfig.maximumSampleRate == arbConfig.minimumSampleRate)
    factor = 1;
else
    factor = ceil(arbConfig.segmentGranularity / numBits * dataRate / (arbConfig.maximumSampleRate - arbConfig.minimumSampleRate));
end
newFs = round((spbApprox * numBits) / arbConfig.segmentGranularity) * arbConfig.segmentGranularity / numBits * dataRate;
if (factor > 1 && (newFs > arbConfig.maximumSampleRate || newFs < arbConfig.minimumSampleRate))
    if (~ischar(data))
        errordlg(['waveform too short - adjust number of symbols to at least ' num2str(ceil(arbConfig.minimumSegmentSize * dataRate / arbConfig.maximumSampleRate))]);
        return;
    end
    numBits = numBits * factor;
end
if (numBits ~= numBitsOld)
    warndlg(['number of bits has been adjusted to ' num2str(numBits) ' to match waveform granularity and sample rate limitations']);
end
% calculate the number of samples to match segment granularity
numSamples = round((spbApprox * numBits) / arbConfig.segmentGranularity) * arbConfig.segmentGranularity;
% rounding might bring the the sample rate above the maximum
if (numSamples / numBits * dataRate > arbConfig.maximumSampleRate)
    numSamples = numSamples - arbConfig.segmentGranularity;
end
% ...or below the minimum
% if (numSamples / numBits * dataRate < arbConfig.minimumSampleRate)
%     numSamples = numSamples + arbConfig.segmentGranularity;
% end
if (numSamples < arbConfig.minimumSegmentSize && ~nowarning)
    errordlg(['waveform too short - adjust number of symbols to at least ' num2str(ceil(arbConfig.minimumSegmentSize * dataRate / arbConfig.maximumSampleRate))]);
    return;
end
if (numSamples > arbConfig.maximumSegmentSize && ~nowarning)
    errordlg(['waveform too long - adjust number of symbols to less than ' num2str(floor(arbConfig.maximumSegmentSize * dataRate / arbConfig.minimumSampleRate))]);
    return;
end
% calculate exact spb (will likely be NOT an integer value)
spb = numSamples / numBits;
if (sampleRate == 0)
    sampleRate = spb * dataRate;
end

% use the same sequence every time so that results are comparable
randStream = RandStream('mt19937ar'); 
reset(randStream);

if (ischar(data))
    switch(lower(data))
        case 'clock'
            if (mod(numBits, 2) ~= 0)
                errordlg('Clock pattern requires an even number of bits');
            end
            data = repmat([0 1], 1, ceil(numBits / 2));
        case 'random'
            data = randStream.rand(1,numBits) < 0.5;
        case 'mlt-3'
            mltCode = [.5 0 .5 1];
            data = mltCode(mod(cumsum(randStream.randi([0 1], 1, numBits)), 4) + 1);
        case 'pam3'
            data = floor(3 * randStream.rand(1,numBits)) / 2;
        case 'pam4'
            % use a PRBS 2^11-1 as a basis
            h = commsrc.pn('GenPoly', [11 9 0], 'NumBitsOut', 2*numBits);
            data = 1 - flipud(h.generate())';
            % apply a gray mapping (00 01 11 10)
            mapping = [0 1 3 2];
            data = mapping(2 * data(1:2:end-1) + data(2:2:end) + 1) / 3;
        case 'pam5'
            data = floor(5 * randStream.rand(1,numBits)) / 4;
        case 'pam8'
            data = floor(8 * randStream.rand(1,numBits)) / 7;
        case 'pam16'
            data = floor(16 * randStream.rand(1,numBits)) / 15;
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
        case 'doublet'
            if (mod(numBits, 2) ~= 0)
                errordlg('Doublet pattern requires an even number of bits');
                return;
            end
            data = randStream.rand(1,ceil(numBits/2)) < 0.5;
            data(2,:) = 1-data(1,:);
            data = data(1:end);
        case 'jp03b'
            data = repmat([repmat([1 0], 1, 15) repmat([0 1], 1, 16)], 1, ceil(numBits/62));
            data = data(1:numBits);
        case 'linearitytestpattern'
            data = repmat([0 1/3 2/3 1 0 1 0 1 2/3 1/3], 16, ceil(numBits/160));
            data = data(1:numBits);
        case 'qprbs13'
            data = qprbs13(numBits);
        case 'qprbs13 rz'
            if (mod(numBits, 2) ~= 0)
                errordlg('QPRBS13 RZ pattern requires an even number of bits');
            end
            data = qprbs13(ceil(numBits/2));
            data = [data; zeros(1, ceil(numBits/2))];
            data = data(1:numBits);
        case 'qprbs13 r1/2'
            if (mod(numBits, 2) ~= 0)
                errordlg('QPRBS13 R1/2 pattern requires an even number of bits');
            end
            data = qprbs13(ceil(numBits/2));
            data = [data; 0.5 * ones(1, ceil(numBits/2))];
            data = data(1:numBits);
        case 'qprbs13 user defined levels'
            data = qprbs13(numBits, levels);
        case 'dual pam4'
            data1 = floor(4 * randStream.rand(1,numBits)) / 6;
            data2 = floor(4 * randStream.rand(1,numBits)) / 6;
            data = data1 + data2;
        otherwise
            errordlg(['undefined data pattern: ' data]);
            return;
    end
elseif (isvector(data))
    numBits = length(data);
    % make sure the data is in the correct format
    if (isvector(data) && size(data,1) > 1)
        data = data.';
    end
else
    error('data must be ''clock'', ''random'' or a vector of bits');
end
assignin('base', 'data', data);

% apply pre/post-cursors
if (~isempty(preCursor) || ~isempty(postCursor))
    % make sure pre- and postCursor are row-vectors (same "shape" as data)
    preCursor = reshape(preCursor, 1, length(preCursor));
    postCursor = reshape(postCursor, 1, length(postCursor));
    % convert to linear units and combine
    corr = ([-10.^(cumsum(preCursor)/20) 10.^(fliplr(cumsum(fliplr(-postCursor)))/20)] + 1) / 2;
    len = length(corr);
    if (length(data) >= len)
        % prepend zeros to avoid negative indices in the for-loop
        % prepend last <len> symbols of data to avoid wrap-around artefacts
        data2 = [zeros(1, len) data(end - len + 1:end) data];
        % find transitions
        df = diff(data2);
        % at each transition, apply pre/de-emphasis
        for i = find(df);
            data2(i-len+1:i) = data2(i-len+1:i) + df(i) * corr;
        end
        % throw away the extra symbols that have been prepended
        data = data2(len+1:end-len);
    else
        errordlg('data vector is too short to apply pre/postcursors');
    end
end

% convert transition time in number of samples
tt = ttUI * spb;
% define jitter as a function of sample position
SJcycles = round(SJfreq * numBits / dataRate);   % jitter cycles
for i = 1:numSJ
    if (SJpp(i) ~= 0 && SJfreq(i) ~= 0 && SJcycles(i) == 0 && ~nowarning)
    %     warndlg(['SJ frequency too low for the given number of bits. Minimum is: ' iqengprintf(dataRate / numBits) ' Hz'], 'Warning', 'modal');
    % let's not complain too much and use a single cycle...
        SJcycles(i) = 1;
    end
end
% define SJ and RJ functions. The functions will be called with a vector of
% transition times (in units of samples) and are expected to return the
% deviation in units of samples
SJfct = @(x,i) SJpp(i) / 2 * spb * sin(SJcycles(i) * 2*pi*x/numSamples);
RJfct = @(x) RJpp / 2 * spb * (sum(randStream.rand(6,length(x)))/6-0.5)*2;
if (noiseFreq == 0)
    noiseFct = @() noise * (sum(randStream.rand(6,numSamples))/6-0.5)*2;
else
    Ncycles = round(noiseFreq * numBits / dataRate);   % noise cycles
    if (noise ~= 0 && noiseFreq ~= 0 && Ncycles == 0 && ~nowarning)
%         warndlg(['Noise frequency too low for the given number of bits. Minimum is: ' ...
%             iqengprintf(dataRate / numBits) ' Hz'], 'Warning', 'modal');
% let's not complain too much and use a single cycle...
        Ncycles = 1;
    end
    noiseFct = @() noise * sin(Ncycles * 2*pi*(1:numSamples)/numSamples);
end
% the transition function will be called with values between 0 and 1 and is
% expected to return a value between 0 and 1
TTfct = @(x,spb) (cos(pi*(x-1))+1)/2;   % raised cosine
%TTfct = @(x,spb) x;   % straight line

% calculate transition deviation caused by SSC
% assume SSC to have "triangle" shape, centered at dataRate
% sscfct receives vector with values between 0 and 1 as input and returns
% a vector with values between -1 and +1
sscShape = @(x) (2*mod(2*x-1/2,1)-1) .* (2*mod(floor(2*x-1/2),2)-1);      % triangle
%sscShape = @(x) sin(2*pi*x);                                             % sine wave
sscCycles = round(sscFreq * numBits / dataRate);
if (sscDepth ~= 0 && sscFreq ~= 0 && sscCycles == 0 && ~nowarning)
     warndlg(['SSC frequency is too low for the given number of bits. Minimum is: ' iqengprintf(dataRate / numBits) ' Hz'], 'Warning', 'modal');
     sscCycles = 1;
end
% deviation from nominal UI period (in fraction of UI)
perDev = 0.5 * sscDepth * sscShape(sscCycles * (0:numBits)/numBits);
% sum of UI periods
cumDev = cumsum(perDev);

% calculate transition positions (start with first half bit to get the
% complete transition, add 1 because of array indices)
dpos = find(diff([data data(1)]));
ptx = spb * (dpos - 0.5) + 1;
% add jitter to the transition points
pt = ptx + RJfct(ptx);
for i = 1:numSJ
    pt = pt + SJfct(ptx, i);
end
% add SSC
if (sscDepth ~= 0)
    % SSC deviation in number of samples
    sscDev = spb * interp1((0:numBits) *  spb, cumDev, ptx);
    pt = pt + sscDev;
end
% add duty cycle distortion
if (dutyCycle ~= 0.5)
    if (data(dpos) > 0)
        edgeDir = 1;
    else
        edgeDir = -1;
    end
    pt(1:2:end) = pt(1:2:end) + edgeDir * spb * (dutyCycle - 0.5);
    pt(2:2:end) = pt(2:2:end) - edgeDir * spb * (dutyCycle - 0.5);
end

% now calculate the actual samples
samples = zeros(1,numSamples);
numPts = length(pt);
pt(numPts + 1) = numSamples + tt;   % add one more point at the end to avoid overflow
dpos(end+1) = 1;                    % dito
k = 1;                              % k counts transitions
lev = data(dpos(1)+1);              % start with the first data value
oldlev = data(1);                   % remember the previous level in transitions
i = 1;                              % i counts samples
while i <= numSamples
    if (i <= pt(k)-tt/2)            % before transition
        samples(i) = oldlev;        %   set to current level
        i = i + 1;                  %   and go to next sample
    elseif (i >= pt(k)+tt/2)        % after transition
        k = k + 1;                  %   check next transition (don't increment sample ptr!)
        oldlev = lev;               %   remember previous level
        lev = data(mod(dpos(k),numBits)+1);  %   load new level
    else                            % during the transition
        m = (i - (pt(k)-tt/2)) / tt;
        samples(i) = oldlev + TTfct(m,spb) * (lev - oldlev);
        i = i + 1;
    end
end
pt(numPts + 1) = [];                % remove temporary transition point

% add ISI
tmp = repmat(samples, 1, 2);
tmp = filter([1-isi 0], [1 -1*isi], tmp);
samples = tmp(numSamples+1:end);

% shift from [0...1] to [-1...+1]
samples = (2*samples - 1);
% add noise
samples = samples + noiseFct();
% apply frequency correction
samples = complex(samples, samples);
if (correction)
    samples = iqcorrection(samples, sampleRate);
end
% set range to [-ampl...+ampl]
samples = samples * amplitude;

delete(randStream);



function data = qprbs13(numBits, levels)
% Matlab script to generate PAM4 QPRBS13 test pattern - Paul Forrest
% Date 2/13/2015
%
% Start with 3 and a bit repetitions of PRBS13 to X^13+X^12+X^2+X+1
% polynomial = 319096 bits. Then take each pair of bits, with 1st bit
% weighted at 2x amplitude of 2nd bit and add to get PAM4 symbol. Divide by
% 3 to normalize all values between 0 and 1 
% (PAM4 levels will be 0, 1/3, 2/3, 1)
% In this using the lane0 seed for the starting values of the shift
% registers in the LFSR model
%
% NOTE the taps used in Matlab are different to the polynomial above
% because Matlab defines the LFSR structure differently :) But these are
% the taps to use the generate the sequence of bits per the standard.

if (~exist('numBits', 'var'))
    numBits = 15548;
end
if (~exist('levels', 'var'))
    levels = [0 1/3 2/3 1];
end
z1 = commsrc.pn('Genpoly', [13 12 11 1 0], 'Initialstates', [0 0 0 0 0 1 0 1 0 1 0 1 1], 'Numbitsout', 8191,'Shift',13);
% generate 1x sequence of PRBS13 per PAM4 standard, this will be 8191 bits 1:8191 of the 31096 bit NRZ pattern
NRZ1 = z1.generate()';
% generate 1x sequence of PRBS13 per PAM4 standard, inverted, this will be 8191 bits 8192:16382 of the 31096 bit NRZ pattern
NRZ2 = 1 - z1.generate()';
% generate 1x sequence of PRBS13 per PAM4 standard, this will be 8191 bits 16383:24573 of the 31096 bit NRZ pattern
NRZ3 = z1.generate()';
%generate 1x truncated sequence of PRBS13 per PAM4 standard, inverted, this will be 6523 bits 24574:31096 of the 31096 bit NRZ pattern
NRZ4 = 1 - z1.generate()';
% add the segments together to get complete NRZ version of the QBPRS13
NRZ = [NRZ1 NRZ2 NRZ3 NRZ4(1:6523)];
% take pairs of bits, weight and add
data = levels(2*NRZ(1:2:end) + NRZ(2:2:end) + 1);
% adjust length to numBits (in case numBits is not equal to 15548)
data = repmat(data, 1, ceil(numBits / 15548));
data = data(1:numBits);



function x = fixlength(x, len)
% make a vector with <len> elements by duplicating or cutting <x> as
% necessary
x = reshape(x, 1, length(x));
x = repmat(x, 1, ceil(len / length(x)));
x = x(1:len);

