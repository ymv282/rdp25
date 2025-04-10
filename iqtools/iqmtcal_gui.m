function varargout = iqmtcal_gui(varargin)
% IQMTCAL_GUI MATLAB code for iqmtcal_gui.fig
%      IQMTCAL_GUI, by itself, creates a new IQMTCAL_GUI or raises the existing
%      singleton*.
%
%      H = IQMTCAL_GUI returns the handle to a new IQMTCAL_GUI or the handle to
%      the existing singleton*.
%
%      IQMTCAL_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IQMTCAL_GUI.M with the given input arguments.
%
%      IQMTCAL_GUI('Property','Value',...) creates a new IQMTCAL_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iqmtcal_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iqmtcal_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iqmtcal_gui

% Last Modified by GUIDE v2.5 03-Mar-2015 09:44:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iqmtcal_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @iqmtcal_gui_OutputFcn, ...
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


% --- Executes just before iqmtcal_gui is made visible.
function iqmtcal_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iqmtcal_gui (see VARARGIN)

% Choose default command line output for iqmtcal_gui
handles.output = hObject;

handles.result = [];
set(handles.popupmenuMemory, 'Value', 3); % 64K
set(handles.pushbuttonSave, 'Enable', 'off');  % no save without data
set(handles.pushbuttonUseAsDefault, 'Enable', 'off');
% make sure initial setting is valid
if ((size(varargin, 1) >= 1) && strcmp(varargin{1}, 'single'))
    set(handles.popupmenuQAWG, 'Value', 5);
    values = get(handles.popupmenuQScope, 'String');
    set(handles.popupmenuQScope, 'Value', length(values));
end
try
    arbConfig = loadArbConfig();
    set(handles.editMaxFreq, 'String', iqengprintf(round(0.4688 * arbConfig.defaultSampleRate/1e8)*1e8));
    if (~isempty(strfind(arbConfig.model, 'M8190A')))
        set(handles.popupmenuTrigAWG, 'String', {'1', '2', '3', '4', 'Sample Marker'});
        set(handles.popupmenuTrigAWG, 'Value', 5);
        if (get(handles.popupmenuQAWG, 'Value') >= 3 && get(handles.popupmenuQAWG, 'Value') <= 4)
            set(handles.popupmenuQAWG, 'Value', 2);
        end
    end
catch ex
    throw(ex);
end

% Update handles structure
guidata(hObject, handles);

checkfields(hObject, [], handles);

% UIWAIT makes iqmtcal_gui wait for user response (see UIRESUME)
% uiwait(handles.iqtool);


function checkfields(hObject, eventdata, handles)
try
    arbConfig = loadArbConfig();
catch
    errordlg('Please set up connection to AWG and Scope in "Configure instrument connection"');
    close(handles.iqtool);
    return;
end
rtsConn = ((~isfield(arbConfig, 'isScopeConnected') || arbConfig.isScopeConnected ~= 0) && isfield(arbConfig, 'visaAddrScope'));
dcaConn = (isfield(arbConfig, 'isDCAConnected') && arbConfig.isDCAConnected ~= 0);
if (~rtsConn && ~dcaConn)
    errordlg('You must set up either a connection to a real-time scope or DCA in "Configure instrument connection"');
    close(handles.iqtool);
    return;
end
if (~rtsConn)
    set(handles.radiobuttonRTScope, 'Value', 0);
end
if (~dcaConn)
    set(handles.radiobuttonDCA, 'Value', 0);
end



% --- Outputs from this function are returned to the command line.
function varargout = iqmtcal_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
try
    varargout{1} = handles.output;
catch
end


% --- Executes on button press in pushbuttonRun.
function pushbuttonRun_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonRun (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    maxFreq = evalin('base', ['[' get(handles.editMaxFreq, 'String') ']']);
    numTones = evalin('base', ['[' get(handles.editNumTones, 'String') ']']);
    scopeAvg = evalin('base', ['[' get(handles.editScopeAverage, 'String') ']']);
    analysisAvg = evalin('base', ['[' get(handles.editAnalysisAverages, 'String') ']']);
    amplitude = evalin('base', ['[' get(handles.editAmplitude, 'String') ']']);
    awgChannels = [get(handles.popupmenuIAWG, 'Value') get(handles.popupmenuQAWG, 'Value') get(handles.popupmenuTrigAWG, 'Value')];
    iList = get(handles.popupmenuIScope, 'String');
    qList = get(handles.popupmenuQScope, 'String');
    trigList = get(handles.popupmenuTrigScope, 'String');
    scopeChannels = { iList{get(handles.popupmenuIScope, 'Value')} ...
                      qList{get(handles.popupmenuQScope, 'Value')} ...
                      trigList{get(handles.popupmenuTrigScope, 'Value')}};
    skewIncluded = get(handles.checkboxSkewIncluded, 'Value');
    scopeRST = get(handles.checkboxScopeRST, 'Value');
    AWGRST = get(handles.checkboxAWGRST, 'Value');
    autoScopeAmplitude = get(handles.checkboxAutoScopeAmplitude, 'Value');
    axes = [handles.axesMag handles.axesPhase];
    sim = get(handles.popupmenuSimulation, 'Value') - 1;
    debugLevel = get(handles.popupmenuDebugLevel, 'Value') - 1;
    memory = 2^(get(handles.popupmenuMemory, 'Value') + 13);
    toneDevList = get(handles.popupmenuToneDev, 'String');
    toneDev = toneDevList{get(handles.popupmenuToneDev, 'Value')};
    if (get(handles.radiobuttonRTScope, 'Value'))
        scope = 'RTScope';
    elseif (get(handles.radiobuttonDCA, 'Value'))
        scope = 'DCA';
    else
        errordlg('Please select a scope');
        return;
    end
catch ex
    errordlg({'Invalid parameter setting', ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
    return;
end
result = [];
try
    hMsgBox = waitbar(0, 'Please wait...', 'Name', 'Please wait...', 'CreateCancelBtn', 'setappdata(gcbf,''cancel'',1)');
    setappdata(hMsgBox, 'cancel', 0);
    result = iqmtcal('scope', scope, 'sim', sim, 'scopeAvg', scopeAvg, ...
            'numTones', numTones, 'scopeRST', scopeRST, 'AWGRST', AWGRST, ...
            'autoScopeAmpl', autoScopeAmplitude, 'memory', memory, ...
            'awgChannels', awgChannels, 'scopeChannels', scopeChannels, ...
            'maxFreq', maxFreq, 'analysisAvg', analysisAvg, 'toneDev', toneDev, ...
            'amplitude', amplitude, 'hMsgBox', hMsgBox, 'axes', axes, ...
            'skewIncluded', skewIncluded, 'debugLevel', debugLevel);
catch ex
    errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
end
try delete(hMsgBox); catch; end
handles.result = result;
guidata(hObject, handles);
if (~isempty(result))
    set(handles.pushbuttonSave, 'Enable', 'on');
    set(handles.pushbuttonUseAsDefault, 'Enable', 'on');
    if (sim == 0)
        res = questdlg('Use this result as default freq/phase response for IQTools per-channel correction and adjust DC offset?', 'Save this measurement?', 'Yes', 'No', 'Yes');
        if (strcmp(res, 'Yes'))
            pushbuttonUseAsDefault_Callback([], [], handles);
            % close the window to avoid confusion
            close(handles.iqtool);
        end
    end
else
    set(handles.pushbuttonSave, 'Enable', 'off');
    set(handles.pushbuttonUseAsDefault, 'Enable', 'off');
end


function editScopeAverage_Callback(hObject, eventdata, handles)
% hObject    handle to editScopeAverage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = [];
try
    val = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (isempty(val) || ~isscalar(val) || val < 0)
    set(hObject, 'Background', 'red');
else
    set(hObject, 'Background', 'white');
end


% --- Executes during object creation, after setting all properties.
function editScopeAverage_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editScopeAverage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editAnalysisAverages_Callback(hObject, eventdata, handles)
% hObject    handle to editAnalysisAverages (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = [];
try
    val = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (isempty(val) || ~isscalar(val) || val < 0)
    set(hObject, 'Background', 'red');
else
    set(hObject, 'Background', 'white');
end


% --- Executes during object creation, after setting all properties.
function editAnalysisAverages_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAnalysisAverages (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in radiobuttonRTScope.
function radiobuttonRTScope_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonRTScope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (get(handles.radiobuttonRTScope, 'Value') == 1)
    arbConfig = loadArbConfig();
    rtsConn = ((~isfield(arbConfig, 'isScopeConnected') || arbConfig.isScopeConnected ~= 0) && isfield(arbConfig, 'visaAddrScope'));
    if (rtsConn)
        % if DCA was previously selected , save the channel assignment
        if (get(handles.radiobuttonDCA, 'Value'))
            handles.oldDCA_Chan = [ ...
                get(handles.popupmenuIScope, 'Value') ...
                get(handles.popupmenuQScope, 'Value') ...
                get(handles.popupmenuTrigScope, 'Value')];
            guidata(handles.output, handles);
        end
        % flip the radio buttons
        set(handles.radiobuttonRTScope, 'Value', 1);
        set(handles.radiobuttonDCA, 'Value', 0);
        % set the channel selection
        set(handles.popupmenuIScope, 'String', {'1', '2', '3', '4', 'DIFF1', 'DIFF2'});
        set(handles.popupmenuQScope, 'String', {'1', '2', '3', '4', 'DIFF1', 'DIFF2', 'unused'});
        set(handles.popupmenuTrigScope, 'String', {'1', '2', '3', '4', 'AUX'});
        if (isfield(handles, 'oldRTS_Chan'))
            chan = handles.oldRTS_Chan;
        else
            chan = [1 3 4];
        end
        set(handles.popupmenuIScope, 'Value', chan(1));
        set(handles.popupmenuQScope, 'Value', chan(2));
        set(handles.popupmenuTrigScope, 'Value', chan(3));
    else
        set(handles.radiobuttonRTScope, 'Value', 0);
        errordlg('You must set the VISA address of the real-time scope in "Configure Instrument"');
    end
end
checkChannels(handles);


% --- Executes on button press in radiobuttonDCA.
function radiobuttonDCA_Callback(hObject, eventdata, handles)
% hObject    handle to radiobuttonDCA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (get(handles.radiobuttonDCA, 'Value') == 1)
    arbConfig = loadArbConfig();
    if (isfield(arbConfig, 'isDCAConnected') && arbConfig.isDCAConnected)
        % if RTScope was previously selected , save the channel assignment
        if (get(handles.radiobuttonRTScope, 'Value'))
            handles.oldRTS_Chan = [ ...
                get(handles.popupmenuIScope, 'Value') ...
                get(handles.popupmenuQScope, 'Value') ...
                get(handles.popupmenuTrigScope, 'Value')];
            guidata(handles.output, handles);
        end
        set(handles.radiobuttonDCA, 'Value', 1);
        set(handles.radiobuttonRTScope, 'Value', 0);
        set(handles.popupmenuIScope, 'String', {'1A', '1B', 'DIFF1A', '1C', '1D', 'DIFF1C', '2A', '2B', '2C', '2D', '3A', '3B', '3C', '3D', '4A', '4B', '4C', '4D'});
        set(handles.popupmenuQScope, 'String', {'1A', '1B', 'DIFF1A', '1C', '1D', 'DIFF1C', '2A', '2B', '2C', '2D', '3A', '3B', '3C', '3D', '4A', '4B', '4C', '4D', 'unused'});
        set(handles.popupmenuTrigScope, 'String', {'Front Panel'});
        if (isfield(handles, 'oldDCA_Chan'))
            chan = handles.oldDCA_Chan;
        else
            chan = [1 2 1];
            if (get(handles.popupmenuQAWG, 'Value') == 5)
                chan(2) = length(get(handles.popupmenuQScope, 'String'));
            end
        end
        set(handles.popupmenuTrigScope, 'Value', 1);
        set(handles.popupmenuIScope, 'Value', chan(1));
        set(handles.popupmenuQScope, 'Value', chan(2));
    else
        set(handles.radiobuttonDCA, 'Value', 0);
        errordlg('You must set the VISA address of the DCA in "Configure Instrument" if you want to use a DCA for calibration');
    end
end
checkChannels(handles);


function editMaxFreq_Callback(hObject, eventdata, handles)
% hObject    handle to editMaxFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = [];
try
    val = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (isempty(val))
    set(hObject, 'Background', 'red');
else
    set(hObject, 'Background', 'white');
end



% --- Executes during object creation, after setting all properties.
function editMaxFreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editMaxFreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editNumTones_Callback(hObject, eventdata, handles)
% hObject    handle to editNumTones (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = [];
try
    val = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (isempty(val))
    set(hObject, 'Background', 'red');
else
    set(hObject, 'Background', 'white');
end


% --- Executes during object creation, after setting all properties.
function editNumTones_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editNumTones (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuIAWG.
function popupmenuIAWG_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuIAWG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
checkChannels(handles);


% --- Executes during object creation, after setting all properties.
function popupmenuIAWG_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuIAWG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuIScope.
function popupmenuIScope_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuIScope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
checkChannels(handles);

% --- Executes during object creation, after setting all properties.
function popupmenuIScope_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuIScope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuQAWG.
function popupmenuQAWG_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuQAWG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (get(handles.popupmenuQAWG, 'Value') == 5)
    list = get(handles.popupmenuQScope, 'String');
    set(handles.popupmenuQScope, 'Value', length(list));
end
checkChannels(handles);


% --- Executes during object creation, after setting all properties.
function popupmenuQAWG_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuQAWG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuQScope.
function popupmenuQScope_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuQScope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
list = get(handles.popupmenuQScope, 'String');
if (strcmp(list{get(handles.popupmenuQScope, 'Value')}, 'unused'))
    set(handles.popupmenuQAWG, 'Value', 5);
end
checkChannels(handles);


% --- Executes during object creation, after setting all properties.
function popupmenuQScope_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuQScope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuTrigAWG.
function popupmenuTrigAWG_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuTrigAWG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
checkChannels(handles);


% --- Executes during object creation, after setting all properties.
function popupmenuTrigAWG_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuTrigAWG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function checkChannels(handles)
h = [handles.popupmenuIAWG, handles.popupmenuQAWG, handles.popupmenuTrigAWG, ...
     handles.popupmenuIScope, handles.popupmenuQScope, handles.popupmenuTrigScope];
hx = zeros(1, 6);       % flag for error
hv = get(h, 'Value');   % values
hs = cell(1, 6);        % strings
for i=1:6
    list = get(h(i), 'String');
    hs{i} = list{hv{i}};
end
% check for double use channels
if (hv{1} == hv{2}); hx(1) = 1; hx(2) = 1; end
if (hv{3} ~= 5)
    if (hv{1} == hv{3}); hx(1) = 1; hx(3) = 1; end
    if (hv{2} == hv{3}); hx(2) = 1; hx(3) = 1; end
end
if (hv{4} == hv{5}); hx(4) = 1; hx(5) = 1; end
if (~strcmp(hs{6}, 'Front Panel') && ~strcmp(hs{6}, 'AUX'))
    if (hv{4} == hv{6}); hx(4) = 1; hx(6) = 1; end
    if (hv{5} == hv{6}); hx(5) = 1; hx(6) = 1; end
end
% check for unused connected to not unused
if (strcmp(hs{2}, 'unused') && ~strcmp(hs{5}, 'unused'))
    hx(2) = 1;
end
if (~strcmp(hs{2}, 'unused') && strcmp(hs{5}, 'unused'))
    hx(5) = 1;
end
% turn the background to red for those that violate a rule
for i = 1:6
    if (hx(i))
        set(h(i), 'Background', 'red');
    else
        set(h(i), 'Background', 'white');
    end
end

% --- Executes on selection change in popupmenuTrigScope.
function popupmenuTrigScope_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuTrigScope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
checkChannels(handles);


% --- Executes during object creation, after setting all properties.
function popupmenuTrigScope_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuTrigScope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editAmplitude_Callback(hObject, eventdata, handles)
% hObject    handle to editAmplitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = [];
try
    val = evalin('base', ['[' get(hObject, 'String') ']']);
catch ex
end
if (isempty(val) || ~isscalar(val) || val < 0)
    set(hObject, 'Background', 'red');
else
    set(hObject, 'Background', 'white');
end


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


% --- Executes on selection change in popupmenuSimulation.
function popupmenuSimulation_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuSimulation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuSimulation contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuSimulation


% --- Executes during object creation, after setting all properties.
function popupmenuSimulation_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuSimulation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuDebugLevel.
function popupmenuDebugLevel_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuDebugLevel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuDebugLevel contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuDebugLevel


% --- Executes during object creation, after setting all properties.
function popupmenuDebugLevel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuDebugLevel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxSkewIncluded.
function checkboxSkewIncluded_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxSkewIncluded (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxSkewIncluded


% --- Executes on button press in checkboxScopeRST.
function checkboxScopeRST_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxScopeRST (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxScopeRST


% --- Executes on button press in pushbuttonSave.
function pushbuttonSave_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonSave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (isfield(handles, 'result') && ~isempty(handles.result))
    Cal = handles.result;
    tsExt = sprintf('.s%dp', 2 * size(Cal.AmplitudeResponse_MT, 2));
    tsDescr = sprintf('Touchstone file (*%s)', tsExt);
    [filename, pathname, filterindex] = uiputfile({...
        '.mat', 'MATLAB file (*.mat)'; ...
        '.csv', 'CSV file (*.csv)'; ...
        tsExt, tsDescr}, ...
        'Save Frequency Response As...');
    if (filename ~= 0)
        try
            switch (filterindex)
                case 1 % .mat
                    save(strcat(pathname, filename), 'Cal');
                case 2 % .csv
                    f = fopen(strcat(pathname, filename), 'wt');
%                    fprintf(f, '# freq, mag(db), phase(degrees), ...\n');
                    for i = 1:size(Cal.AmplitudeResponse_MT, 1)
                        fprintf(f, sprintf('%g', Cal.Frequency_MT(i) * 1e9));
                        for ch = 1:size(Cal.AmplitudeResponse_MT, 2)
                            fprintf(f, sprintf(',%g,%g', Cal.AmplitudeResponse_MT(i,ch), Cal.AbsPhaseResponse_MT(i,ch)));
                        end
                        fprintf(f, '\n');
                    end
                    fclose(f);
                case 3 % .s2p / .s4p / ...
                    sp = rfdata.data;
                    sp.Freq = Cal.Frequency_MT;
                    sp.S_Parameters = zeros(2 * size(Cal.AmplitudeResponse_MT, 2), 2 * size(Cal.AmplitudeResponse_MT, 2), size(Cal.AmplitudeResponse_MT, 1));
                    for i = 1:size(Cal.AmplitudeResponse_MT, 2)
                        amp = 10 .^ (Cal.AmplitudeResponse_MT(:,i) / 20);
                        phi = Cal.AbsPhaseResponse_MT(:,i) * pi / 180;
                        cplx = amp .* exp(1j * phi);
                        sp.S_Parameters(2*i,2*i-1,:) = cplx;
                        sp.S_Parameters(2*i-1,2*i,:) = cplx;
                    end
                    write(sp, strcat(pathname, filename), 'dB');
            end
        catch ex
            errordlg({ex.message, [ex.stack(1).name ', line ' num2str(ex.stack(1).line)]});
        end
    end
else
    msgbox('no valid measurement available');
end


% --- Executes on button press in pushbuttonUseAsDefault.
function pushbuttonUseAsDefault_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonUseAsDefault (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (isfield(handles, 'result') && ~isempty(handles.result))
    result = handles.result;
    updatePerChannelCorr(result.Frequency_MT * 1e9, result.AmplitudeResponse_MT, result.AbsPhaseResponse_MT);
    % if the corr mgmt window is open, update the graphs
    updateCorrWindow();
    % adjust DC offset in AWG if we are not using a differential channel
    iList = get(handles.popupmenuIScope, 'String');
    if (~strncmpi(iList{get(handles.popupmenuIScope, 'Value')}, 'DIFF', 4))
        try
            f = iqopen();
            for ch = 1:length(result.AWGChannels)
                off = str2double(query(f, sprintf(':VOLTage%d:OFFSet?', result.AWGChannels(ch))));
                off = off - result.DCOffset(ch);
                fprintf(f, sprintf(':VOLTage%d:OFFSet %g', result.AWGChannels(ch), off));
            end
            fclose(f);
        catch
        end
    end
else
    msgbox('no valid measurement available');
end


function updateCorrWindow()
% If Correction Mgmt Window is open, refresh it
try
    TempHide = get(0, 'ShowHiddenHandles');
    set(0, 'ShowHiddenHandles', 'on');
    figs = findobj(0, 'Type', 'figure', 'Tag', 'iqcorrmgmt');
    set(0, 'ShowHiddenHandles', TempHide);
    if (~isempty(figs))
        iqcorrmgmt();
    end
catch
end



function updatePerChannelCorr(freq, mag, phase)
% update the PerChannel correction file
cplxCorr = (10 .^ (mag/20)) .* exp(1i * phase/180*pi);
% set up perChannelCorr structure
clear perChannelCorr;
perChannelCorr(:,1) = freq(1:end);
perChannelCorr(:,2:size(cplxCorr,2)+1) = 1 ./ cplxCorr;
% get the filename
ampCorrFile = iqampCorrFilename();
clear acs;
% %%% TBD: Load the ampCorr file, ask user if it is OK to delete complex
% %%% correction, S-Parameters, etc.  For now, simply start from scratch
% try to load ampCorr file - be graceful if it does not exist
%try
%    acs = load(ampCorrFile);
%catch
%end
acs.perChannelCorr = perChannelCorr;
% and save
try
    save(ampCorrFile, '-struct', 'acs');
catch ex
    errordlg(sprintf('Can''t save correction file: %s. Please check if it write-protected.', ex.message));
end


% --- Executes on selection change in popupmenuMemory.
function popupmenuMemory_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuMemory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuMemory contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuMemory


% --- Executes during object creation, after setting all properties.
function popupmenuMemory_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuMemory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuToneDev.
function popupmenuToneDev_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuToneDev (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuToneDev contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuToneDev


% --- Executes during object creation, after setting all properties.
function popupmenuToneDev_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuToneDev (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxAWGRST.
function checkboxAWGRST_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxAWGRST (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxAWGRST


% --- Executes on button press in checkboxAutoScopeAmplitude.
function checkboxAutoScopeAmplitude_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxAutoScopeAmplitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = get(hObject, 'Value');
if (val)
    set(handles.editAmplitude, 'Enable', 'off');
else
    set(handles.editAmplitude, 'Enable', 'on');
end
% Hint: get(hObject,'Value') returns toggle state of checkboxAutoScopeAmplitude
