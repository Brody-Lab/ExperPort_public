function senderror_report

try %#ok<TRYNC>
    x = lasterror; %#ok<LERR>

    message = cell(0);
    message{end+1} = ['Error Report Generated: ',datestr(now,31)];
    message{end+1} = '';
    message{end+1} = x.message;
    message{end+1} = x.identifier;
    message{end+1} = '';
    
    for i = 1:length(x.stack)
        message{end+1} = ['error in ',x.stack(i).name,' at line ',num2str(x.stack(i).line)]; %#ok<AGROW>
    end
    
    IP = get_network_info;
    message{end+1} = ' ';
    if ischar(IP); message{end+1} = ['Email generated by ',IP];
    else           message{end+1} = 'Email generated by an unknown computer!!!';
    end
    
    message{end+1} = 'ratter\ExperPort\Utility\AutomatedEmails\senderror_report.m';

    %setpref('Internet','SMTP_Server','brodyfs2.princeton.edu');
    %setpref('Internet','E_mail',['ErrorReport',datestr(now,'yymm'),'@Princeton.EDU']);
    set_email_sender
    
    try
        R = bSettings('get','RIGS','Rig_ID');
    catch %#ok<CTCH>
        R = nan;
    end
    
    if ~ischar(R); R = num2str(R); end
    
    sendmail('ckopec@princeton.edu',['AES Error Report on Rig ',R],message);
end