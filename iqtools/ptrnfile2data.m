%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   v0.3
%   Call this function for test
%   
%   [data, fileCharData] = ptrnfile2data('fileName')
%   input parameter:    string file name (Optional)
%   output parameter:   fileCharData
%                                characters in file (bits)
%                       
%
%   Thanks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [fileCharData] = ptrnfile2data(fileName)

Formatting = {'Version='        ...     % Parameters used in PTRN format
              'Format='         ...
              'Description='    ...
              'Count='          ...
              'Length='         ...
              'Data='           ...
               };
checkFormattingDATA = cell(6,1);        % to store parameter values

badfile = 0;                            % bad file format check 
txtfile = 0;
%fileName = 'CEIstress.ptrn';    %
%fileName = 'CRPAT.ptrn';
if (nargin == 0)
    [filename, pathname] = uigetfile({'*.ptrn;*.txt'},'Select a *.ptrn file');
    if filename ~= 0
        fileName = strcat(pathname, filename);
    else
        badfile = 1;
    end
end

if ~badfile
    if strcmp(fileName(length(fileName)-3:end),'.txt')
        txtfile = 1;
    end
    fid = fopen(fileName, 'r');             % open to read file
    if fid == -1
        f = errordlg(sprintf('Can''t open %s', fileName),...
                    'Error Message PTRNfile');
        badfile = 1;
    end
    dis = sprintf('File name is %s\n',fileName);
%    disp(dis);

if ~badfile
if ~txtfile
    for i=1:6       % this loop will test all the parameters and compair
    stringCheck=''; % 
    counter = 0;    % bad file formate check
        while true
            readchar = fread(fid, 1)';                  % read one byte from file
            stringCheck=strcat(stringCheck,readchar);   % make string with single characters
            if readchar=='='        % find '=' as its a part of the format
                break;
            end

            counter = counter +1;
            if counter > 100 && i~=4                % chaeck if don't find '=' for longer time
                f = errordlg('Bad File Format',...
                    'Error Message PTRNfile');
                %disp('Bad File Format')            % that means there is some problem with the file format
                badfile = 1;                        % 100 is just an arbitrarily value.
                break;                              % "Description parameter" may contain more characters.
            end

        end

    if badfile      % if file format is bad just break for loop
        break
    end

    lF = length(Formatting{i})-1;   % length of each format string 
    ls = length(stringCheck);       % number of characters read till '='
        if ls>lF+1                  % for first parameter "Version=" both lenths will be same
            checkFormatting = stringCheck(ls-lF:ls);            % saperate the parameter portion and their values 
            checkFormattingDATA{i-1} = stringCheck(1:ls-lF-1);
            % dis = sprintf('%s %s',Formatting{i-1},checkFormattingDATA{i-1});
            % disp(dis);
        else
            checkFormatting = stringCheck;      % for case "Version=" only
        end

        if strcmp(checkFormatting,Formatting{i})    % compair if we alligned with the format
    %        dis = sprintf('True and Checked');
    %        disp(dis);
        else
            dis = sprintf('..ERROR..Bad file format\n');
            f = errordlg('Bad File Format',...
                    'Error Message PTRNfile');
            %disp(dis);
            badfile = 1;
        end

    end     % End of for loop which test all the parameters

        dataChar = fread(fid, 1)';          % read a character and check
        if dataChar == 10 || dataChar == 13 % if we can find <CR/LF> before start of
            %dis = sprintf('Data begins');       % data payload
            %disp(dis);
        else
            %dis = sprintf('Wrong Wrong');
            %disp(dis);
            badfile = 1;
        end
end
end
    if ~badfile         % don't go further if there is some error in format

        dataChar = fread(fid, inf)';        % read rest of the data from the file
        fclose(fid);                        % close the file

    if ~txtfile
        if checkFormattingDATA{4} == '2'        % if count parameter is 2
            k=strfind(dataChar,Formatting{6});  % then we have duplicate data in file
            dataChar=dataChar(1:k-2);
        end

        checkFormattingDATA{i} = dataChar;    % take it for further purpose if needed

        byteCurrection = mod(str2double(checkFormattingDATA{5}),8);
        if checkFormattingDATA{5} == num2str( (length(dataChar)*8) - byteCurrection)
%            dis = sprintf('Length is right');               % just check if the length of 
%            disp(dis);                                      % data read from file is 
        else                                                 % equal as stated in the file parameter
            dis = sprintf('Length error');
%            disp(dis);
            f = errordlg(dis, 'Error Message PTRNfile');
        end

    if strcmp(checkFormattingDATA(2),'Bin') %% chaeck format 

        fileCharData = [];              % this will convert all the characters and place
        for j=1:length(dataChar)        % in a variable 'data' as bit pattren
        a = uint8(dataChar(j));
            gg = bitand(a,1);
               for i = 1:8
                  a = bitshift(a,-1);
                  f = bitand(a,1);
                  if i<8
                      gg=[f,gg];
                  end
               end
        fileCharData = [fileCharData,gg];
        end
        fileCharData = fileCharData(1:end-byteCurrection);
    else
%        disp('other format');
        f = errordlg('other then BIN formate', 'Error Message PTRNfile');
    %%%%%%%%%%%%%  for other formats
    end
    
    else
        fileCharData = [];          % for txt file
        i=1;
        sp = 0;
        counterSample = 1;
        while i<length(dataChar)+1
            if dataChar(i) == ' ' || dataChar(i) == 10 || dataChar(i) == 13
                i = i + 1;
                sp = 0;
            elseif dataChar(i) == '1'
                i = i + 1;
                sp = sp + 1;
                counterSample = counterSample + 1;
                fileCharData = [fileCharData,1];
            elseif dataChar(i) == '0'
                i = i + 1;
                sp = sp + 1;
                counterSample = counterSample + 1;
                fileCharData = [fileCharData,0];
            else
                f = errordlg(sprintf('Sample %d in file %s is invalid',counterSample, fileName),...
                    'Error Message PTRNfile');
                fileCharData = [];
                break;
            end
            if sp > 1
                f = errordlg(sprintf('Sample %d in file %s is invalid',counterSample-1, fileName),...
                    'Error Message PTRNfile');
                fileCharData = [];
                break;
            end
        end
    end
    
    
    else            % if any bad file format error occur then come here
        fileCharData = [];
        if fid ~= -1
            fclose(fid);
        end
    end
else                % if no file selected
    fileCharData = [];
end


fclose('all');

        
end
