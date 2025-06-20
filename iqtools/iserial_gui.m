function varargout = iserial_gui(varargin)
% ISERIAL_GUI MATLAB code for iserial_gui.fig
%      ISERIAL_GUI, by itself, creates a new ISERIAL_GUI or raises the existing
%      singleton*.
%
%      H = ISERIAL_GUI returns the handle to a new ISERIAL_GUI or the handle to
%      the existing singleton*.
%
%      ISERIAL_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ISERIAL_GUI.M with the given input arguments.
%
%      ISERIAL_GUI('Property','Value',...) creates a new ISERIAL_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iserial_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iserial_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iserial_gui

% Last Modified by GUIDE v2.5 12-Jun-2015 13:31:03

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iserial_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @iserial_gui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before iserial_gui is made visible.
function iserial_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iserial_gui (see VARARGIN)

% Choose default command line output for iserial_gui
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

arbConfig = loadArbConfig();
switch arbConfig.model
    case '81180A'
        dataRate = 1e9;
        numBits = 128;
    case {'M8190A', 'M8190A_base', 'M8190A_14bit' }
        dataRate = 1e9;
        numBits = 192;
    case 'M8190A_12bit'
        dataRate = 3e9;
        numBits = 256;
    case 'M8190A_prototype'
        dataRate = 1e9;
        numBits = 200;
    case { 'M8195A_Rev1' 'M8195A_1ch', 'M8195A_2ch', 'M8195A_4ch', 'M8195A_4ch_256k', 'M8196A' }
        dataRate = 6e9;
        numBits = 1024;
    case 'M933xA'
        dataRate = 250e6;
        numBits = 128;
    otherwise
        dataRate = 250e6;
        numBits = 128;
end
set(handles.editSampleRate, 'String', iqengprintf(arbConfig.defaultSampleRate));
set(handles.editDataRate, 'String', iqengprintf(dataRate));
set(handles.checkboxAutoSampleRate, 'Value', 1);
set(handles.editNumBits, 'String', num2str(numBits));
checkfields([], 0, handles);

if (~isfield(arbConfig, 'tooltips') || arbConfig.tooltips == 1)
set(handles.editDataRate, 'TooltipString', sprintf([ ...
    'Enter the data rate for the signal in symbols per second.\n' ...
    'The utility will adjust the sample rate and oversampling to exactly match\n' ...
    'the specified data rate.']));
set(handles.editSampleRate, 'TooltipString', sprintf([ ...
    'If you enter the sample rate manually, the data rate might not be exact.']));
set(handles.popupmenuDataType, 'TooltipString', sprintf([ ...
    'Select the format and type of data. ''Random'', ''Clock'' and ''PRBS'' \n' ...
    'generate binary data. ''PAMx'' and ''MLT-3'' generate multi-level signals']));
set(handles.editNumBits, 'TooltipString', sprintf([ ...
    'Enter the number of random bits to be generated. For User Defined data pattern.\n' ...
    'this field is ignored.']));
set(handles.editUserData, 'TooltipString', sprintf([ ...
    'Enter a user defined data pattern. The pattern can be a list of values separated by\n' ...
    'spaces or a MATLAB expression that evaluates to a vector. The values must be\n' ...
    '0 or 1 (for binary patterns). For multi-level patterns, values can be anywhere in the\n', ...
    'range 0...1.   Example: repmat([0 1],1,48)  will generate a 96 bit clock pattern.\n' ...
    '0 0 0 1 0 0 0 1 0 1 0 1 1 0 1 1 0 1 0 1  will generate the specified pattern.']));
set(handles.editTransitionTime, 'TooltipString', sprintf([ ...
    'Enter the transition time as portion of a UI. Although a zero transition time can be\n' ...
    'entered, the actual transition time will be limited by the hardware.  If you want to\n' ...
    'apply jitter or you have non-integer relationship between data rate and sample rate,\n' ...
    'you should choose the transition time big enough to contain at least two samples.']));
set(handles.editPreCursor, 'TooltipString', sprintf([ ...
    'Any number of pre-cursor values specified as a list of values in dB, separated \n' ...
    'by spaces or comma. Pre-cursors are typically positive dB values.\n']));
set(handles.editPostCursor, 'TooltipString', sprintf([ ...
    'Any number of post-cursor values specified as a list of values in dB, separated \n' ...
    'by spaces or comma. Post-cursors are typically negative dB values.\n']));
set(handles.editSJfreq, 'TooltipString', sprintf([ ...
    'Enter the frequency for sinusoidal jitter. Note that the smallest frequency for SJ\n' ...
    'is limited by the number of bits the oversampling rate because the utility must fit\n' ...
    'at least one full cycle of the jitter into the waveform']));
set(handles.editSJpp, 'TooltipString', sprintf([ ...
    'Enter the peak-to-peak deviation for sinusoidal jitter in portions of UI.\n' ...
    'Example: For a 1 Gb/s data rate, a 0.2 UI jitter will be 200ps (peak-to-peak)']));
set(handles.editRJpp, 'TooltipString', sprintf([ ...
    'Enter the peak-to-peak deviation for random jitter in portions of UI.\n' ...
    'RJ is simulated as a (near-)gaussian distribution with a maximum deviation\n' ...
    'of 6 sigma.']));
set(handles.editNoise, 'TooltipString', sprintf([ ...
    'Enter the amount of vertical noise that is added to waveform in the range 0 to 1.\n' ...
    'Zero means no noise, 1 means the same amplitude of noise as the signal itself.']));
set(handles.editISI, 'TooltipString', sprintf([ ...
    'Enter the amount of ISI in the range 0 to 1. Zero means no ISI at all, 1 is a\n' ...
    'completely distorted signal. The practial maximum is around 0.8.  ISI is modelled\n' ...
    'as a simple decay function (y=e^(-ax))']));
set(handles.editSegment, 'TooltipString', sprintf([ ...
    'Enter the AWG waveform segment to which the signal will be downloaded.\n' ...
    'If you download to segment #1, all other segments will be automatically\n' ...
    'deleted.']));
set(handles.pushbuttonDisplay, 'TooltipString', sprintf([ ...
    'Use this button to calculate and show the simulated waveform using MATLAB plots.\n' ...
    'The plot will show the downloaded waveform along with the (mathematical) jitter analysis']));
set(handles.pushbuttonChannelMapping, 'TooltipString', sprintf([ ...
    'Select into which channels the waveform is downloaded.\n' ...
    'In dual-M8190A configurations, channels 3 and 4 are on the second module.']));
set(handles.pushbuttonDownload, 'TooltipString', sprintf([ ...
    'Use this button to calculate and download the signal to the configured AWG.\n' ...
    'Make sure that you have configured the connection parameters in "Configure\n' ...
    'instrument connection" before using this function.']));
end
arbConfig = loadArbConfig();
if (~exist('arbConfig', 'var') || isempty(arbConfig))
    errordlg({'No instrument connection configured. ' ...
        'Please use the "Configuration" utility to' ...
        'configure the instrument connection'});
    close(handles.iqtool);
    return;
end
if (~isempty(strfind(arbConfig.model, 'DUC')))
    errordlg({'Can not work in DUC mode. ' ...
        'Please use the "Configuration" utility' ...
        'and select a non-DUC mode'});
    close(handles.iqtool);
    return;
end
pos1 = get(handles.editFilename, 'Position');
pos2 = get(handles.editUserData, 'Position');
pos3 = get(handles.editLevels, 'Position');
pos2(1:2) = pos1(1:2);
set(handles.editUserData, 'Position', pos2);
pos3(1:2) = pos1(1:2);
set(handles.editLevels, 'Position', pos3);
% UIWAIT makes iserial_gui wait for user response (see UIRESUME)
% uiwait(handles.iqtool);

% --- Outputs from this function are returned to the command line.
function varargout = iserial_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
%varargout{1} = handles.output;


function editDataRate_Callback(hObject, eventdata, handles)
% hObject    handle to editDataRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editDataRate as text
%        str2double(get(hObject,'String')) returns contents of editDataRate as a double
value = [];
try
    value = evalin('base', get(hObject, 'String'));
catch ex
end
if (isscalar(value) && value >= 1e3 && value <= 100e9)
    set(hObject,'BackgroundColor','white');
    checkSSC(handles);
    sampleRate = evalin('base', get(handles.editSampleRate, 'String'));
    autoSampleRate = get(handles.checkboxAutoSampleRate, 'Value');
    if (autoSampleRate)
        arbConfig = loadArbConfig();
        sampleRate = arbConfig.defaultSampleRate;
    end
    % if the datarate is larger than Fs/4, adjust transition time
    % to avoid excessive jitter
    ttVal = get(handles.sliderTransitionTime, 'Value');
    if (ttVal < value / sampleRate * 4)
        ttVal = min(value / sampleRate * 4, 1);
        ttVal = ceil(ttVal * 100) / 100;
        set(handles.sliderTransitionTime, 'Value', ttVal);
        sliderTransitionTime_Callback([], [], handles);
    end
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editDataRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDataRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSampleRate_Callback(hObject, eventdata, handles)
% hObject    handle to editSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSampleRate as text
%        str2double(get(hObject,'String')) returns contents of editSampleRate as a double
checkfields(hObject, 0, handles);

% --- Executes during object creation, after setting all properties.
function editSampleRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editNumBits_Callback(hObject, eventdata, handles)
% hObject    handle to editNumBits (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNumBits as text
%        str2double(get(hObject,'String')) returns contents of editNumBits as a double
value = -1;
try
    value = evalin('base', get(hObject, 'String'));
catch ex
end
if (isscalar(value) && value >= 2 && value <= 10e6)
    set(hObject,'BackgroundColor','white');
    checkSSC(handles);
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editNumBits_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNumBits (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSJpp_Callback(hObject, eventdata, handles)
% hObject    handle to editSJpp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSJpp as text
%        str2double(get(hObject,'String')) returns contents of editSJpp as a double
value = -1;
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (isvector(value) && min(value) >= 0 && max(value) <= 1)
    set(handles.sliderSJpp, 'Value', value(1));
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editSJpp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSJpp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function sliderRJpp_Callback(hObject, eventdata, handles)
% hObject    handle to sliderRJpp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
value = get(hObject, 'Value');
set(handles.editRJpp, 'String', sprintf('%.2g', value));


% --- Executes during object creation, after setting all properties.
function sliderRJpp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderRJpp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function sliderSJpp_Callback(hObject, eventdata, handles)
% hObject    handle to sliderSJpp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
value = get(hObject, 'Value');
set(handles.editSJpp, 'String', sprintf('%.2g', value));


% --- Executes during object creation, after setting all properties.
function sliderSJpp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderSJpp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function sliderTransitionTime_Callback(hObject, eventdata, handles)
% hObject    handle to sliderTransitionTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
value = get(handles.sliderTransitionTime, 'Value');
set(handles.editTransitionTime, 'String', sprintf('%.2g', value));
dataRate = evalin('base', get(handles.editDataRate, 'String'));
sampleRate = evalin('base', get(handles.editSampleRate, 'String'));
if (value < 1 && value < dataRate / sampleRate * 4)
    set(handles.sliderTransitionTime, 'Background', 'yellow');
else
    set(handles.sliderTransitionTime, 'Background', 'white');
end

% --- Executes during object creation, after setting all properties.
function sliderTransitionTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderTransitionTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function editUserData_Callback(hObject, eventdata, handles)
% hObject    handle to editUserData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editUserData as text
%        str2double(get(hObject,'String')) returns contents of editUserData as a double
value = -1;
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch
    try
        clear data;
        eval(get(hObject, 'String'));
        value = data;   % expect "data" to be assigned
    catch
        errordlg('Must specify a list of values separated by space or comma *or* a MATLAB statement that assigns a value to the variable "data"');
    end
end
if (isvector(value) && length(value) >= 2 && ...
        min(value) >= 0 && max(value) <= 1)
    set(handles.editNumBits, 'String', num2str(length(value)));
    set(hObject,'BackgroundColor','white');
    checkSSC(handles);
else
    set(hObject,'BackgroundColor','red');
    errordlg('Data values must be between 0 and 1 and separated by spaces or comma. MATLAB expressions are acceptable');
end


% --- Executes during object creation, after setting all properties.
function editUserData_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editUserData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuDataType.
function popupmenuDataType_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuDataType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuDataType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuDataType
dataTypeList = cellstr(get(handles.popupmenuDataType, 'String'));
dataType = dataTypeList{get(handles.popupmenuDataType, 'Value')};

if (strcmp(dataType, 'User defined'))
    set(handles.editNumBits, 'Enable', 'Off');
    set(handles.editUserData, 'Visible', 'On');
    set(handles.editUserData, 'Enable', 'On');
    set(handles.fileBrowser, 'Visible', 'Off');
    set(handles.editFilename, 'Visible', 'Off');
    set(handles.editLevels, 'Visible', 'Off');
    set(handles.textUserData, 'String', 'User defined data');
elseif (~isempty(strfind(dataType, 'file')))
    set(handles.editNumBits, 'Enable', 'Off');
    set(handles.editUserData, 'Visible', 'Off');
    set(handles.editUserData, 'Enable', 'Off');
    set(handles.fileBrowser, 'Visible', 'On');
    set(handles.fileBrowser, 'Enable', 'On');
    set(handles.editFilename, 'Visible', 'On');
    set(handles.editFilename, 'Enable', 'On');
    set(handles.editLevels, 'Visible', 'Off');
    set(handles.textUserData, 'String', 'User pattern file');
elseif (~isempty(strfind(dataType, 'levels')))
    set(handles.editNumBits, 'Enable', 'On');
    set(handles.editUserData, 'Visible', 'On');
    set(handles.editUserData, 'Enable', 'On');
    set(handles.fileBrowser, 'Visible', 'Off');
    set(handles.editFilename, 'Visible', 'Off');
    set(handles.editLevels, 'Visible', 'On');
    set(handles.editLevels, 'Enable', 'On');
    set(handles.textUserData, 'String', 'User defined levels');
else
    set(handles.editNumBits, 'Enable', 'On');
    set(handles.editUserData, 'Enable', 'Off');
    set(handles.editFilename, 'Enable', 'Off');
    set(handles.fileBrowser, 'Enable', 'Off');
    set(handles.editLevels, 'Enable', 'Off');
end
switch dataType
    case 'PRBS2^7-1'
        set(handles.editNumBits, 'String', '64 * (2^7 - 1)');
    case 'PRBS2^9-1'
        set(handles.editNumBits, 'String', '16 * (2^9 - 1)');
    case 'PRBS2^10-1'
        set(handles.editNumBits, 'String', '8 * (2^10 - 1)');
    case 'PRBS2^11-1'
        set(handles.editNumBits, 'String', '4 * (2^11 - 1)');
    case 'PRBS2^15-1'
        set(handles.editNumBits, 'String', '(2^15 - 1)');
    case 'JP03B'
        set(handles.editNumBits, 'String', '16 * 4 * 62');
    case 'QPRBS13'
        set(handles.editNumBits, 'String', '2 * 15548');
    case 'LinearityTestPattern'
        set(handles.editNumBits, 'String', '320');
    otherwise
end


% --- Executes during object creation, after setting all properties.
function popupmenuDataType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuDataType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxAutoSampleRate.
function checkboxAutoSampleRate_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxAutoSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of checkboxAutoSampleRate
autoSamples = get(handles.checkboxAutoSampleRate, 'Value');
if (autoSamples)
    set(handles.editSampleRate, 'Enable', 'off');
else
    set(handles.editSampleRate, 'Enable', 'on');
end



function editNoise_Callback(hObject, eventdata, handles)
% hObject    handle to editNoise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNoise as text
%        str2double(get(hObject,'String')) returns contents of editNoise as a double
value = -1;
try
    value = evalin('base', get(hObject, 'String'));
catch ex
end
if (isscalar(value) && value >= 0 && value <= 1)
    set(handles.sliderNoise, 'Value', value);
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editNoise_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNoise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonDisplay.
function pushbuttonDisplay_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDisplay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[s, fs, dataRate] = calc_serial(handles, 0);
if (~isempty(s))
    set(handles.editNumSamples, 'String', sprintf('%d', length(s)));
    isplot(s, fs, dataRate);
end


% --- Executes on button press in pushbuttonDownload.
function pushbuttonDownload_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDownload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hMsgBox = msgbox('Downloading Waveform. Please wait...', 'Please wait...', 'replace');
channelMapping = get(handles.pushbuttonChannelMapping, 'UserData');
[s, fs, dataRate] = calc_serial(handles, 0);
if (~isempty(s))
    set(handles.editNumSamples, 'String', sprintf('%d', length(s)));
    segmentNum = evalin('base', get(handles.editSegment, 'String'));
    marker = downloadClock(handles);
    iqdownload(s, fs, 'channelMapping', channelMapping, ...
        'segmentNumber', segmentNum, 'marker', marker);
end
close(hMsgBox);



function marker = downloadClock(handles)
% download a clock signal on unchecked channels, but don't start the generator
marker = [];
isCheckedData = (strcmp('on', get(handles.menuDataRateClock, 'Checked')));
isCheckedData4 = (strcmp('on', get(handles.menuDataRateClock4, 'Checked')));
isCheckedOnce = (strcmp('on', get(handles.menuClockOnce, 'Checked')));
numBits = evalin('base', get(handles.editNumBits, 'String'));
if (isCheckedData)
    clockPat = repmat([1 0], 1, ceil(numBits/2));
    clockPat = clockPat(1:numBits);
    if (mod(numBits, 2) ~= 0)
        warndlg('Number of bits is not a multiple of 2 - clock signal will not be periodic', 'Warning', 'replace');
    end
elseif (isCheckedData4)
    clockPat = repmat([1 1 0 0], 1, ceil(numBits/4));
    clockPat = clockPat(1:numBits);
    if (mod(numBits, 4) ~= 0)
        warndlg('Number of bits is not a multiple of 4 - clock signal will not be periodic', 'Warning', 'replace');
    end
elseif (isCheckedOnce)
    clockPat = [ones(1, floor(numBits/2)) zeros(1, numBits - floor(numBits/2))];
else
    return;
end
[s, fs, dataRate] = calc_serial(handles, 0, clockPat);
if (~isempty(s))
    chMap = get(handles.pushbuttonChannelMapping, 'UserData');
    chMap(:,1) = ~chMap(:,1) & ~chMap(:,2);
    chMap(:,2) = zeros(size(chMap,1), 1);
    segmentNum = evalin('base', get(handles.editSegment, 'String'));
    if (~isempty(find(chMap(1:end), 1)))
        iqdownload(s, fs, 'channelMapping', chMap, 'segmentNumber', segmentNum, 'run', 0);
    end
    if (isCheckedData || isCheckedData4)
        numSamples = length(s);
        [overN overD] = rat(fs / dataRate);
        % for 1x oversampling, set marker every other symbol
        overN = max(overN, 2);
        % don't send markers faster than 10 GHz (DCA)
        maxTrig = 5e9;
        % for M8190A, max toggle rate for markers = sequencer clock
        if (fs <= 12e9) 
            maxTrig = fs / 64;
        end
        if (floor(fs / maxTrig / overN) > 1)
            overN = overN * floor(fs / maxTrig / overN);
        end
        h1 = floor(overN / 2);
        h2 = overN - h1;
        marker = repmat([15*ones(1,h1) zeros(1,h2)], 1, ceil(numSamples / overN));
        marker = marker(1:numSamples);
    else
        marker = 15 * (real(s) > 0);
    end
end


function editRJpp_Callback(hObject, eventdata, handles)
% hObject    handle to editRJpp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editRJpp as text
%        str2double(get(hObject,'String')) returns contents of editRJpp as a double
value = -1;
try
    value = evalin('base', get(hObject, 'String'));
catch ex
end
if (isscalar(value) && value >= 0 && value <= 1)
    set(handles.sliderRJpp, 'Value', value);
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editRJpp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editRJpp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editISI_Callback(hObject, eventdata, handles)
% hObject    handle to editISI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editISI as text
%        str2double(get(hObject,'String')) returns contents of editISI as a double
value = -1;
try
    value = evalin('base', get(hObject, 'String'));
catch ex
end
if (isscalar(value) && value >= 0 && value <= 1)
    set(handles.sliderISI, 'Value', value);
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editISI_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editISI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSJfreq_Callback(hObject, eventdata, handles)
% hObject    handle to editSJfreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSJfreq as text
%        str2double(get(hObject,'String')) returns contents of editSJfreq as a double
value = -1;
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (isvector(value) && min(value) >= 0 && max(value) <= 64e9)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editSJfreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSJfreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editTransitionTime_Callback(hObject, eventdata, handles)
% hObject    handle to editTransitionTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editTransitionTime as text
%        str2double(get(hObject,'String')) returns contents of editTransitionTime as a double
value = -1;
try
    value = evalin('base', get(hObject, 'String'));
catch ex
end
if (isscalar(value) && value >= 0 && value <= 1)
    set(handles.sliderTransitionTime, 'Value', value);
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editTransitionTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editTransitionTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function sliderNoise_Callback(hObject, eventdata, handles)
% hObject    handle to sliderNoise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
value = get(hObject, 'Value');
set(handles.editNoise, 'String', sprintf('%.2g', value));


% --- Executes during object creation, after setting all properties.
function sliderNoise_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderNoise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function sliderISI_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderISI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes on slider movement.
function sliderISI_Callback(hObject, eventdata, handles)
% hObject    handle to sliderISI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
value = get(hObject, 'Value');
set(handles.editISI, 'String', sprintf('%.2g', value));


% --- Executes on slider movement.
function sliderDutyCycle_Callback(hObject, eventdata, handles)
% hObject    handle to sliderDutyCycle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
value = get(hObject, 'Value');
set(handles.editDutyCycle, 'String', sprintf('%.0f', value));


% --- Executes during object creation, after setting all properties.
function sliderDutyCycle_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderDutyCycle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function editDutyCycle_Callback(hObject, eventdata, handles)
% hObject    handle to editDutyCycle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editDutyCycle as text
%        str2double(get(hObject,'String')) returns contents of editDutyCycle as a double
value = -1;
try
    value = evalin('base', get(hObject, 'String'));
catch ex
end
if (isscalar(value) && value >= 0 && value <= 100)
    set(handles.sliderDutyCycle, 'Value', value);
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editDutyCycle_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDutyCycle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editAmplitude_Callback(hObject, eventdata, handles)
% hObject    handle to editAmplitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editAmplitude as text
%        str2double(get(hObject,'String')) returns contents of editAmplitude as a double


% --- Executes during object creation, after setting all properties.
function editAmplitude_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAmplitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSegment_Callback(hObject, eventdata, handles)
% hObject    handle to editSegment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSegment as text
%        str2double(get(hObject,'String')) returns contents of editSegment as a double
checkfields(hObject, 0, handles);


% --- Executes during object creation, after setting all properties.
function editSegment_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSegment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --------------------------------------------------------------------
function preset_Callback(hObject, eventdata, handles)
% hObject    handle to preset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function clock_8gbps_Callback(hObject, eventdata, handles)
% hObject    handle to clock_8gbps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.editDataRate, 'String', '8e9');
set(handles.editSampleRate, 'String', '8e9');
set(handles.checkboxAutoSampleRate, 'Value', 0);
set(handles.popupmenuDataType, 'Value', 2);
set(handles.editNumBits, 'String', '192');
set(handles.sliderTransitionTime, 'Value', 0);
sliderTransitionTime_Callback([], [], handles);
set(handles.editSJfreq, 'String', '0');
set(handles.editSJpp, 'String', '0');
editSJpp_Callback([], [], handles);
set(handles.editRJpp, 'String', '0');
set(handles.editNoise, 'String', '0');
editNoise_Callback([], [], handles);
set(handles.editISI, 'String', '0');
set(handles.sliderISI, 'Value', 0);


% --------------------------------------------------------------------
function mlt3_125mbps_Callback(hObject, eventdata, handles)
% hObject    handle to mlt3_125mbps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.editDataRate, 'String', '125e6');
set(handles.checkboxAutoSampleRate, 'Value', 1);
set(handles.popupmenuDataType, 'Value', 3);
set(handles.editNumBits, 'String', '192');
set(handles.sliderTransitionTime, 'Value', 0.3);
sliderTransitionTime_Callback([], [], handles);
set(handles.editSJfreq, 'String', '0');
set(handles.editSJpp, 'String', '0');
editSJpp_Callback([], [], handles);
set(handles.editRJpp, 'String', '0');
set(handles.editNoise, 'String', '0');
editNoise_Callback([], [], handles);
set(handles.editISI, 'String', '0');
set(handles.sliderISI, 'Value', 0);
popupmenuDataType_Callback([], [], handles);


% --------------------------------------------------------------------
function random_1gbps_Callback(hObject, eventdata, handles)
% hObject    handle to random_1gbps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.editDataRate, 'String', '1e9');
set(handles.checkboxAutoSampleRate, 'Value', 1);
set(handles.popupmenuDataType, 'Value', 1);
set(handles.editNumBits, 'String', '192');
set(handles.sliderTransitionTime, 'Value', 0.3);
sliderTransitionTime_Callback([], [], handles);
set(handles.editSJfreq, 'String', '10e6');
set(handles.editSJpp, 'String', '0');
editSJpp_Callback([], [], handles);
set(handles.editRJpp, 'String', '0');
set(handles.editNoise, 'String', '0');
editNoise_Callback([], [], handles);
set(handles.editISI, 'String', '0.7');
set(handles.sliderISI, 'Value', 0.7);
popupmenuDataType_Callback([], [], handles);


% --------------------------------------------------------------------
function menu_PAM4_nonequidistant_Callback(hObject, eventdata, handles)
% hObject    handle to random_1gbps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.editDataRate, 'String', '25e9');
set(handles.checkboxAutoSampleRate, 'Value', 1);
dataTypeList = cellstr(get(handles.popupmenuDataType, 'String'));
set(handles.popupmenuDataType, 'Value', length(dataTypeList));
set(handles.editUserData, 'String', 'v=[0 0.2 0.5 1]; data = v(randi(4,1,10240));');
set(handles.editNumBits, 'String', '10240');
set(handles.sliderTransitionTime, 'Value', 1);
sliderTransitionTime_Callback([], [], handles);
set(handles.editSJfreq, 'String', '10e6');
set(handles.editSJpp, 'String', '0');
editSJpp_Callback([], [], handles);
set(handles.editRJpp, 'String', '0');
set(handles.editNoise, 'String', '0');
editNoise_Callback([], [], handles);
set(handles.editISI, 'String', '0');
set(handles.sliderISI, 'Value', 0);
set(handles.checkboxCorrection, 'Value', 1);
popupmenuDataType_Callback([], [], handles);


function [s, fs, dataRate] = calc_serial(handles, doCode, clockPat)
s = [];
fs = 0;
dataRate = 0;
dataRate = evalin('base', get(handles.editDataRate, 'String'));
sampleRate = evalin('base', get(handles.editSampleRate, 'String'));
autoSampleRate = get(handles.checkboxAutoSampleRate, 'Value');
dataTypeList = cellstr(get(handles.popupmenuDataType, 'String'));
dataType = dataTypeList{get(handles.popupmenuDataType, 'Value')};
numBits = evalin('base', get(handles.editNumBits, 'String'));
if (~isempty(strfind(dataType, 'file')))
    userData = double(ptrnfile2data(get(handles.editFilename, 'String')));
    if (isempty(userData) || isequal(userData, -1))
        return;
    end
    dataType = 'User defined';
else
    try
        % try to interpret userdata as a list of values
        userData = evalin('base', ['[' get(handles.editUserData, 'String') ']']);
        if (isempty(userData))
            return;
        end
    catch
        % if this fails, try to evaluate as a statement that assigns
        % soemthing to the variable "data"
        clear data;
        eval(get(handles.editUserData, 'String'));
        userData = data;   % expect "data" to be assigned
    end
end
preCursor = evalin('base', ['[' get(handles.editPreCursor, 'String') ']']);
postCursor = evalin('base', ['[' get(handles.editPostCursor, 'String') ']']);
tTime = evalin('base', get(handles.editTransitionTime, 'String'));
SJfreq = evalin('base', ['[' get(handles.editSJfreq, 'String') ']']);
SJpp = evalin('base', ['[' get(handles.editSJpp, 'String') ']']);
RJpp = evalin('base', get(handles.editRJpp, 'String'));
sscFreq = evalin('base', get(handles.editSSCfreq, 'String'));
sscDepth = evalin('base', get(handles.editSSCdepth, 'String'));
noiseFreq = evalin('base', get(handles.editNoiseFreq, 'String'));
noise = evalin('base', get(handles.editNoise, 'String'));
isi = evalin('base', get(handles.editISI, 'String'));
amplitude = evalin('base', get(handles.editAmplitude, 'String'));
dutyCycle = evalin('base', get(handles.editDutyCycle, 'String'));
correction = get(handles.checkboxCorrection, 'Value');
if (exist('clockPat', 'var'))
    % force a certain pattern - independent of user settings
    dataType = 'User defined';
    userData = clockPat;
    % make clock without distortions
    SJpp = 0;
    RJpp = 0;
    noise = 0;
    amplitude = 1;
    dutyCycle = 50;
end
if (autoSampleRate)
    sampleRate = 0;
end
if (strcmp(dataType, 'User defined'))
    data = userData;
    numBits = length(data);
    set(handles.editNumBits, 'String', num2str(numBits));
    dataStr = ['[' sprintf('%g ', userData) ']'];
    levels = [];
    levelStr = '[]';
elseif (~isempty(strfind(dataType, 'levels')))
    data = dataType;
    dataStr = sprintf('''%s''', dataType);
    levels = evalin('base', ['[' get(handles.editLevels, 'String') ']']);
    levelStr = ['[' sprintf('%g ', levels) ']'];
else
    data = dataType;
    dataStr = sprintf('''%s''', dataType);
    levels = [];
    levelStr = '[]';
end
if (doCode) % generate MATLAB code
    channelMapping = iqchannelsetup('arraystring', get(handles.pushbuttonChannelMapping, 'UserData'));
    segmentNum = evalin('base', get(handles.editSegment, 'String'));
    s = sprintf(['[s, fs] = iserial(''dataRate'', %g, ''sampleRate'', %g, ...\n' ...
        '    ''numBits'', %d, ''data'', %s, ''levels'', %s, ''SJfreq'', [%s], ''SJpp'', [%s], ...\n' ...
        '    ''RJpp'', %g, ''noiseFreq'', %g, ''noise'', %g, ''isi'', %g, ...\n' ...
        '    ''preCursor'', [%s], ''postCursor'', [%s], ''transitionTime'', %g, ...\n' ...
        '    ''sscFreq'', %g, ''sscDepth'', %g, ...\n' ...
        '    ''amplitude'', %g, ''dutyCycle'', %g, ''correction'', %g);\n' ...
        'iqdownload(s, fs, ''segmentNumber'', %g, ''channelMapping'', %s);\n'], ...
        dataRate, sampleRate, numBits, dataStr, levelStr, sprintf('%g ', SJfreq), ...
        sprintf('%g ', SJpp), RJpp, noiseFreq, noise, ...
        isi, sprintf('%g ', preCursor), sprintf('%g ', postCursor), tTime, sscFreq, sscDepth / 100, ...
        amplitude, dutyCycle / 100, correction, segmentNum, channelMapping);
    fs = 0;
    dataRate = 0;
else % generate the acutal waveform
    [s, fs] = iserial('dataRate', dataRate, 'sampleRate', sampleRate, ...
        'numBits', numBits, 'data', data, 'levels', levels, 'SJfreq', SJfreq, 'SJpp', SJpp, ...
        'RJpp', RJpp, 'noiseFreq', noiseFreq, 'noise', noise, 'isi', isi, ...
        'preCursor', preCursor, 'postCursor', postCursor, 'transitionTime', tTime, ...
        'sscFreq', sscFreq, 'sscDepth', sscDepth / 100, ...
        'amplitude', amplitude, 'dutyCycle', dutyCycle / 100, 'correction', correction);
    set(handles.editSampleRate, 'String', iqengprintf(fs));
    assignin('base', 'signal', s);
    assignin('base', 'sampleRate', fs);
    assignin('base', 'dataRate', dataRate);
end

% --------------------------------------------------------------------
function menuFile_Callback(hObject, eventdata, handles)
% hObject    handle to menuFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menuLoadSettings_Callback(hObject, eventdata, handles)
% hObject    handle to menuLoadSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqloadsettings(handles);


% --------------------------------------------------------------------
function menuSaveSettings_Callback(hObject, eventdata, handles)
% hObject    handle to menuSaveSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqsavesettings(handles);


% --------------------------------------------------------------------
function menuSaveWaveform_Callback(hObject, eventdata, handles)
% hObject    handle to menuSaveWaveform (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[data, sampleRate, dataRate] = calc_serial(handles, 0);
if (~isempty(data))
    iqsavewaveform(data, sampleRate);
end


function result = checkfields(hObject, eventdata, handles)
% This function verifies that all the fields have valid and consistent
% values. It is called from inside this script as well as from the
% iqconfig script when arbConfig changes (i.e. a different model or mode is
% selected). Returns 1 if all fields are OK, otherwise 0
result = 1;
arbConfig = loadArbConfig();

% --- generic checks
if (arbConfig.maxSegmentNumber <= 1)
    set(handles.editSegment, 'Enable', 'off');
    set(handles.textSegment, 'Enable', 'off');
else
    set(handles.editSegment, 'Enable', 'on');
    set(handles.textSegment, 'Enable', 'on');
end
% --- channel mapping
%iqchannelsetup('setup', handles.pushbuttonChannelMapping, arbConfig, 'single');
iqchannelsetup('setup', handles.pushbuttonChannelMapping, arbConfig);
% --- editSampleRate
value = -1;
try
    value = evalin('base', get(handles.editSampleRate, 'String'));
catch ex
    msgbox(ex.message);
    result = 0;
end
if (isscalar(value) && value >= arbConfig.minimumSampleRate && value <= arbConfig.maximumSampleRate)
    set(handles.editSampleRate, 'BackgroundColor', 'white');
else
    set(handles.editSampleRate, 'BackgroundColor', 'red');
    result = 0;
end
% --- editSegment
value = -1;
try
    value = evalin('base', get(handles.editSegment, 'String'));
catch ex
    msgbox(ex.message);
    result = 0;
end
if (isscalar(value) && value >= 1 && value <= arbConfig.maxSegmentNumber)
    set(handles.editSegment,'BackgroundColor','white');
else
    set(handles.editSegment,'BackgroundColor','red');
    result = 0;
end


% --- Executes on button press in pushbuttonChannelMapping.
function pushbuttonChannelMapping_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonChannelMapping (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
arbConfig = loadArbConfig();
%[val, str] = iqchanneldlg(get(hObject, 'UserData'), arbConfig, handles.iqtool, 'single');
[val, str] = iqchanneldlg(get(hObject, 'UserData'), arbConfig, handles.iqtool);
if (~isempty(val))
    set(hObject, 'UserData', val);
    set(hObject, 'String', str);
end


% --- Executes on button press in checkboxCorrection.
function checkboxCorrection_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxCorrection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxCorrection


% --- Executes on button press in pushbuttonShowCorrection.
function pushbuttonShowCorrection_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonShowCorrection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqcorrmgmt();


% --------------------------------------------------------------------
function menuGenerateCode_Callback(hObject, eventdata, handles)
% hObject    handle to menuGenerateCode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[code fs dataRate] = calc_serial(handles, 1);
if (~isempty(code))
    iqgeneratecode(handles, code);
end


function editNumSamples_Callback(hObject, eventdata, handles)
% hObject    handle to editNumSamples (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNumSamples as text
%        str2double(get(hObject,'String')) returns contents of editNumSamples as a double


% --- Executes during object creation, after setting all properties.
function editNumSamples_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNumSamples (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function menuDataRateClock_Callback(hObject, eventdata, handles)
% hObject    handle to menuDataRateClock (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
isChecked = (strcmp('on', get(handles.menuDataRateClock, 'Checked')));
if (isChecked)
    set(handles.menuDataRateClock, 'Checked', 'off');
else
    set(handles.menuDataRateClock, 'Checked', 'on');
    set(handles.menuDataRateClock4, 'Checked', 'off');
    set(handles.menuClockOnce, 'Checked', 'off');
end


% --------------------------------------------------------------------
function menuClockOnce_Callback(hObject, eventdata, handles)
% hObject    handle to menuClockOnce (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
isChecked = (strcmp('on', get(handles.menuClockOnce, 'Checked')));
if (isChecked)
    set(handles.menuClockOnce, 'Checked', 'off');
else
    set(handles.menuClockOnce, 'Checked', 'on');
    set(handles.menuDataRateClock, 'Checked', 'off');
    set(handles.menuDataRateClock4, 'Checked', 'off');
end



function menuDataRateClock4_Callback(hObject, eventdata, handles)
% hObject    handle to menuDataRateClock4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
isChecked = (strcmp('on', get(handles.menuDataRateClock4, 'Checked')));
if (isChecked)
    set(handles.menuDataRateClock4, 'Checked', 'off');
else
    set(handles.menuDataRateClock4, 'Checked', 'on');
    set(handles.menuDataRateClock, 'Checked', 'off');
    set(handles.menuClockOnce, 'Checked', 'off');
end


function editNoiseFreq_Callback(hObject, eventdata, handles)
% hObject    handle to editNoiseFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editNoiseFreq as text
%        str2double(get(hObject,'String')) returns contents of editNoiseFreq as a double


% --- Executes during object creation, after setting all properties.
function editNoiseFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNoiseFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbuttonMTCal.
function pushbuttonMTCal_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonMTCal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
iqmtcal_gui('single');


% --- Executes on button press in pushbuttonConfigScope.
function pushbuttonConfigScope_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonConfigScope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
msgbox('Function not yet implemented');


% --------------------------------------------------------------------



function editPreCursor_Callback(hObject, eventdata, handles)
% hObject    handle to editPreCursor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPreCursor as text
%        str2double(get(hObject,'String')) returns contents of editPreCursor as a double
value = [];
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (isempty(value) || (isvector(value) && min(value) >= -10 && max(value) <= 10))
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editPreCursor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPreCursor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editPostCursor_Callback(hObject, eventdata, handles)
% hObject    handle to editPostCursor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPostCursor as text
%        str2double(get(hObject,'String')) returns contents of editPostCursor as a double
value = [];
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (isempty(value) || (isvector(value) && min(value) >= -10 && max(value) <= 10))
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editPostCursor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPostCursor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in fileBrowser.
function fileBrowser_Callback(hObject, eventdata, handles)                  %
% hObject    handle to fileBrowser (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[filename, pathname] = uigetfile({'*.ptrn;*.txt'},'Select a pattern file');
if filename ~= 0
    fullfilepath = strcat(pathname, filename);
    set(handles.editFilename, 'String', fullfilepath);
end


function editFilename_Callback(hObject, eventdata, handles)
data = ptrnfile2data(get(handles.editFilename));
if (isempty(data))
    set(handles.editFilename, 'Background', 'red');
else
    set(handles.editFilename, 'Background', 'white');
    set(handles.editNumBits, 'String', iqengprintf(length(data)));
end


% --- Executes during object creation, after setting all properties.
function editFilename_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editLevels_Callback(hObject, eventdata, handles)
% hObject    handle to editLevels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = -1;
try
    value = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (isvector(value) && min(value) >= 0 && max(value) <= 1)
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor','red');
    errordlg('Must be a list of values in the range 0...1', 'Error', 'replace');
end


% --- Executes during object creation, after setting all properties.
function editLevels_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editLevels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSSCfreq_Callback(hObject, eventdata, handles)
% hObject    handle to editSSCfreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSSCfreq as text
%        str2double(get(hObject,'String')) returns contents of editSSCfreq as a double
value = -1;
try
    value = evalin('base', get(hObject, 'String'));
catch ex
end
if (isscalar(value) && value >= 0 && value <= 1e9)
    set(hObject,'BackgroundColor','white');
    checkSSC(handles);
else
    set(hObject,'BackgroundColor','red');
end



function checkSSC(handles)
dataRate = evalin('base', get(handles.editDataRate, 'String'));
numBits = evalin('base', get(handles.editNumBits, 'String'));
sscDepth = evalin('base', get(handles.editSSCdepth, 'String'));
sscFreq = evalin('base', get(handles.editSSCfreq, 'String'));
if (sscDepth == 0 || dataRate / numBits <= sscFreq)
    set(handles.editSSCfreq, 'BackgroundColor', 'white');
else
    set(handles.editSSCfreq, 'BackgroundColor', 'red');
    errordlg(sprintf(['SSC frequency is too low *or* current number of symbols is too small.\n' ...
        'Please increase SSC frequency to %s *or* increase number of symbols to %d'], ...
        iqengprintf(dataRate / numBits, 3), ceil(dataRate / sscFreq)));
end


% --- Executes during object creation, after setting all properties.
function editSSCfreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSSCfreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editSSCdepth_Callback(hObject, eventdata, handles)
% hObject    handle to editSSCdepth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editSSCdepth as text
%        str2double(get(hObject,'String')) returns contents of editSSCdepth as a double
value = -1;
try
    value = evalin('base', get(hObject, 'String'));
catch ex
end
if (isscalar(value) && value >= 0 && value <= 100)
    set(hObject,'BackgroundColor','white');
    checkSSC(handles);
else
    set(hObject,'BackgroundColor','red');
end


% --- Executes during object creation, after setting all properties.
function editSSCdepth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSSCdepth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
