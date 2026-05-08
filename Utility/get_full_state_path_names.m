function output = get_full_state_path_names(saved_history,saved,trial,sn,varargin)

%The purpose of this function is to transform the full state path output
%from a Bpod into human readable state names.  Required inputs are the two
%variables saved and saved_history that are stored in a training sessions
%.mat file.  The trial number input is option. If you do not pass in a
%specific trial number you would like output it will output all the trials
%with a saved crashed_history of 2, i.e. trials where the state machine was
%stuck in a particular state like state_0 longer than it should.  The
%output is the state names as defined by the protocol. If the specific 
%state is not assigned a name, e.g. state 52 is a state called 
%"nose_in_center" and state 54 is called "wait_for_cout" but we are in
%state 53, then the output will be "nose_in_center+1". 

if nargin < 3
    trial = find(saved.ProtocolsSection_crashed_history == 2);
end
if nargin < 4
    sn = double(saved_history.ProtocolsSection_full_state_path{trial} + 39);
end

sma =  access_sma(saved_history.ProtocolsSection_current_assembler{trial});

%for i = 1:numel(trial)
    
    statenames = sma.state_name_list(:,1);
    statenums  = cell2mat(sma.state_name_list(:,2));
    
    statepath = cell(0);
    for j = 1:numel(sn)
        pos = find(sn(j) - statenums >= 0,1,'last');
        offset = sn(j) - statenums(pos);
        
        if offset > 0; extra = ['+',num2str(offset)];
        else,          extra = '';
        end
        statepath{j} = [statenames{pos},extra];
    end
    output = statepath;
%end

output = output';
    