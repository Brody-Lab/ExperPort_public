function varargout = WaterAlarm(varargin)
% WATERALARM MATLAB code for WaterAlarm.fig
%      WATERALARM, by itself, creates a new WATERALARM or raises the existing
%      singleton*.
%
%      H = WATERALARM returns the handle to a new WATERALARM or the handle to
%      the existing singleton*.
%
%      WATERALARM('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in WATERALARM.M with the given input arguments.
%
%      WATERALARM('Property','Value',...) creates a new WATERALARM or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before WaterAlarm_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to WaterAlarm_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help WaterAlarm

% Last Modified by GUIDE v2.5 29-Jan-2026 23:42:21

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @WaterAlarm_OpeningFcn, ...
                   'gui_OutputFcn',  @WaterAlarm_OutputFcn, ...
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


% --- Executes just before WaterAlarm is made visible.
function WaterAlarm_OpeningFcn(hObject, eventdata, handles, varargin)

handles.output = hObject;

if ~isfield(handles,'running_timer')
    handles.running_timer = timer;
    set(handles.running_timer,'Period',300,'ExecutionMode','FixedRate','TasksToExecute',Inf,...
        'BusyMode','drop','TimerFcn','WaterAlarm(''Update'')','StartDelay',5);
    
    handles.flicker_timer = timer;
    set(handles.flicker_timer,'Period',10,'ExecutionMode','FixedRate','TasksToExecute',Inf,...
        'BusyMode','drop','TimerFcn','WA_flicker_button','StartDelay',30);
end
set(hObject,'CloseRequestFcn','WaterAlarm(''Close'')');
set(handles.Alert_List,'value',[]);

handles.SilenceListPath = 'X:\Training Room\Alarms\RatWaterAlarm\';
if ~exist(handles.SilenceListPath,'dir')
    map_bucket_drive;
end
handles = WA_get_silencelist_file(handles);

if exist(handles.SilenceListFile,'file')
    load(handles.SilenceListFile)
    
    expired = [];
    for i = 1:size(silence_list,1)
        if datenum(silence_list{i,2},'yyyy-mm-dd HH:MM') - now < 0
            expired(end+1) = i;
        end
    end
    silence_list(expired,:) = [];
    
    handles.SilenceList = silence_list;
else
    handles.SilenceList = cell(0,2);
end

names = bdata('select experimenter from ratinfo.contacts where is_alumni=0');
names = unique(names);

Names{1} = 'Select Name';
Names(2:numel(names)+1) = names;

set(handles.Name_Menu,'string',Names,'value',1);
set(handles.Silence_Button,'enable','off');

if ~isfield(handles,'initial_pass')
    set(handles.Run_Toggle,'value',1,'string','Initial Update','backgroundcolor',[1,1,0]);  
    if strcmp(get(handles.running_timer,'Running'),'off')
        handles.initial_pass = 1;
        guidata(hObject, handles);
        start(handles.running_timer);
        
        start(handles.flicker_timer);
    end
end


guidata(hObject, handles);




% --- Outputs from this function are returned to the command line.
function varargout = WaterAlarm_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;


% --- Executes on selection change in Alert_List.
function Alert_List_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function Alert_List_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Run_Toggle.
function Run_Toggle_Callback(hObject, eventdata, handles)

if get(handles.Run_Toggle,'value') == 1
    start(handles.running_timer);
else
    stop(handles.running_timer);
    set(handles.Run_Toggle,'string','Paused','backgroundcolor',[1,0,0]); pause(0.01);
end
    
guidata(hObject, handles);   



% --- Executes on selection change in Name_Menu.
function Name_Menu_Callback(hObject, eventdata, handles)

v = get(handles.Name_Menu,'value');
if v == 1
    set(handles.Silence_Button,'enable','off');
else
    set(handles.Silence_Button,'enable','on');
end

guidata(hObject, handles);   



% --- Executes on button press in Silence_Button.
function Silence_Button_Callback(hObject, eventdata, handles)

set(handles.Silence_Button,'string','Updateing','backgroundcolor',[1,1,0]); pause(0.01);
v = get(handles.Alert_List,'value');
s = get(handles.Alert_List,'string');

e = get(handles.Name_Menu,'string');
a = get(handles.Name_Menu,'value');

silence_list = handles.SilenceList;

for i = 1:numel(v)
    if numel(s) >= v(i) && numel(s{v(i)}) > 5
        ratname = s{v(i)}(1:4);
        sistate = s{v(i)}(end);

        pos = find(strcmp(silence_list(:,1),ratname));
        silence_list(pos,:) = [];
            
        if sistate ~= 'X'    
            silence_list{end+1,1} = ratname;
            silence_list{end,  2} = datestr(now + (3/24),'yyyy-mm-dd HH:MM');
            silence_list{end,  3} = e{a};
            
            s{v(i)}(end) = 'X';
        else
            s{v(i)}(end) = ' ';
        end
    end
end

handles.SilenceList = silence_list;

set(handles.Alert_List,'string',s)
handles = WA_save_silencelist_file(handles);

set(handles.Silence_Button,'string','Silence','backgroundcolor',[0,1,1]); pause(0.01);

guidata(hObject,handles);


    
function Update %#ok<DEFNU>

hObject = WaterAlarm;
handles = guidata(hObject);

set(handles.Run_Toggle,'string','Updating ','backgroundcolor',[1,1,0]); pause(0.01);
    
output{1} = 'Error';
output{2} = '00:00';
try %#ok<TRYNC>
    output = checkrat_24hr_water(str2num(get(handles.Threshold_Edit,'string')),24,1,0); %#ok<ST2NM>
end
 
currfile = handles.SilenceListFile;
handles = WA_get_silencelist_file(handles);
if strcmp(currfile,handles.SilenceListFile) == 0
    load(handles.SilenceListFile);
    handles.SilenceList = silence_list;
end

%remove any expired entries
expired = [];
found_expired = 0;
for i = 1:size(handles.SilenceList,1)
    if datenum(handles.SilenceList{i,2},'yyyy-mm-dd HH:MM') - now < 0
        expired(end+1) = i;
        found_expired = 1;
    end
end

%remove any entry past 24 hours from the silence list
past24ratname = cell(0);
for i = 1:numel(output{1})
    if ~isempty(strfind(output{1}{i},'OVER'))
        past24ratname{end+1} = output{1}{i}(1:4);
    end
end
for i = 1:size(handles.SilenceList,1)
    if sum(strcmp(past24ratname,handles.SilenceList{i,1})) > 0
        expired(end+1) = i;
        found_expired = 1;
    end
end

expired = unique(expired);
handles.SilenceList(expired,:) = [];

%if the silence list is empty and there's no folder for today, let's make
%that folder and save an empty file.
if isempty(handles.SilenceList) && ~exist([handles.SilenceListPath,datestr(now,'yymmdd'),filesep],'dir')
    handles = WA_save_silencelist_file(handles);
end

s = output{1};
for i = 1:numel(s)
    if numel(s{i}) > 5
        ratname = s{i}(1:4);
        
        pos = find(strcmp(handles.SilenceList(:,1),ratname));
        if ~isempty(pos)
            s{i}(end) = 'X';
        end
    end
end
output{1} = s;

set(handles.Alert_List,'string',output{1},'value',[]);
set(handles.DateTime_Text,'string',datestr(now,'mm/dd   HH:MM'));

TR = (str2num(output{2}(1:2)) + (str2num(output{2}(4:5))/60));
start_color_at = 3;
hold_pink_for  = 1;

TR = TR - hold_pink_for;
start_color_at = start_color_at - hold_pink_for;
if TR > start_color_at
    clr = [0.6,1,0.6];
elseif TR > start_color_at/2
    clr = [  1 - (((TR - (start_color_at/2)) / (start_color_at/2)) * 0.4), 1, 0.6];
elseif TR > 0
    clr = [1,1 - ((((start_color_at/2) - TR) / (start_color_at/2)) * 0.4),    0.6];
elseif TR > -hold_pink_for
    clr = [1,0.6,0.6];
else
    clr = [1,0,0];
end
set(handles.Alert_List,'backgroundcolor',clr); %disp(clr);

if get(handles.Run_Toggle,'value') == 1
    set(handles.Run_Toggle,'string','Running','backgroundcolor',[0,1,0]);
else
    set(handles.Run_Toggle,'string','Paused','backgroundcolor',[1,0,0]); 
end
pause(0.01);

guidata(hObject, handles);

  

function Threshold_Edit_Callback(hObject, eventdata, handles)

WaterAlarm('Update');
guidata(hObject, handles);



function UpdateCycle_Edit_Callback(hObject, eventdata, handles)

stop(handles.running_timer);

update_period = str2num(get(handles.UpdateCycle_Edit,'string')) * 60;
set(handles.running_timer,'Period', update_period);

if get(handles.Run_Toggle,'value') == 1
    start(handles.running_timer);
end

guidata(hObject, handles);



function Close

hObject = WaterAlarm;
handles = guidata(hObject);

stop(handles.running_timer); pause(0.1);
while strcmp(get(handles.running_timer,'Running'),'on')
    pause(0.1);
end
delete(handles.running_timer); pause(0.1);

stop(handles.flicker_timer); pause(0.1);
while strcmp(get(handles.flicker_timer,'Running'),'on')
    pause(0.1);
end
delete(handles.flicker_timer); pause(0.1);


delete(hObject);



% --- Executes during object creation, after setting all properties.
function UpdateCycle_Edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function Threshold_Edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



