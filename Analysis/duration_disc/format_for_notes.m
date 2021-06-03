function [] = format_for_notes(data, type, varargin)

pairs = { ...
    'htmlize', 1   ; ...
    'header', 1 ; ...
    };
parse_knownargs(varargin, pairs);

table_st = '<table border="1" align="center">\n'; table_fin = '\n</table>\n';
row_st = '\t<tr>\n'; row_fin = '</tr>\n';
row_st_bold = '\t<tr style=''font-weight:bold''>';
col_st = '<td width="150" align="center">'; col_fin = '</td>';
bold_st = '<b>'; bold_fin = '</b>';
switch type
    case 'summary_weber'
        % make a table
        fprintf(1, table_st); r=1; strow = 1;
        if header
            fprintf(1, row_st);
            for c = 1:cols(data)
                fprintf(1, [col_st bold_st '%s' bold_fin col_fin], data{1,c});
            end;
            fprintf(1, row_fin);
            r= r+1; strow=2;
        end;
        for k = r:rows(data)
            fprintf(1, row_st);
            fprintf(1, ['\t\t' col_st '%s' col_fin], data{k,1});
            fprintf(1, [col_st '%1.2f' col_fin], data{k,2});
            fprintf(1, [col_st '%3.1f, %1.2f' col_fin], data{k,3});
            fprintf(1, [col_st '%1.2f' col_fin], data{k,4});
            fprintf(1, [col_st '%3.1f' col_fin], data{k,5});
            fprintf(1, [col_st '%3.1f' col_fin], data{k,6});
            fprintf(1, [col_st '%3.1f' col_fin row_fin], data{k,7});
        end;
        fprintf(1, ['\t' row_st_bold ...
            col_st 'Averages' col_fin ...
            col_st  '%1.2f' col_fin ...
            col_st 'n/a' col_fin ...
            col_st  '%1.2f' col_fin ...
            col_st  '%3.1f' col_fin ...
            col_st  '%3.1f' col_fin ...
            col_st  '%3.1f' col_fin ...
            row_fin], mean(cell2mat(data(strow:end,2))), mean(cell2mat(data(strow:end,4))), ...
            mean(cell2mat(data(strow:end, 5))), mean(cell2mat(data(strow:end, 6))), ...
            mean(cell2mat(data(strow:end, 7))));
        fprintf(1, ['\t' row_st_bold ...
            col_st 'SD' col_fin ...
            col_st '%1.2f'  col_fin ...
            col_st 'n/a' col_fin ...
            col_st '%1.2f'  col_fin ...
            col_st  '%2.1f' col_fin ...
            col_st  '%2.1f' col_fin ...
            col_st  '%2.1f' col_fin ...
            row_fin], std(cell2mat(data(strow:end,2))), std(cell2mat(data(strow:end,4))), ...
            std(cell2mat(data(strow:end,5))), std(cell2mat(data(strow:end,6))), ...
            std(cell2mat(data(strow:end,7))));
        fprintf(1, ['\t' row_st_bold ...
            col_st 'Range' col_fin ...
            col_st '%1.2f'  col_fin ...
            col_st 'n/a' col_fin ...
            col_st '%1.2f'  col_fin ...
            col_st '%2.1f'  col_fin ...
            col_st '%2.1f'  col_fin ...
            col_st '%2.1f'  col_fin ...
            row_fin], max(cell2mat(data(strow:end,2)))-min(cell2mat(data(strow:end,2))), max(cell2mat(data(strow:end,4)))-min(cell2mat(data(strow:end,4))), ...
            max(cell2mat(data(strow:end,5)))-min(cell2mat(data(strow:end,5))), ...
            max(cell2mat(data(strow:end,6)))-min(cell2mat(data(strow:end,6))), ...
            max(cell2mat(data(strow:end,7)))-min(cell2mat(data(strow:end,7))) );

        fprintf(1, table_fin);
    otherwise
        error('Type unknown!');
end;

