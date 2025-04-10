function result = iqengprintf(x, precision)
% same as sprintf('%g', x), except that the result will have only exponents
% that are a multiple of 3, e.g. 6.4e10 will be returned as '64e9'
% precision can be optionally specified as a second argument (default = 6)
if (~exist('precision', 'var'))
    precision = 6;
end
result = sprintf('%.*g', precision, x);
% check if exponential notation was used
ep = strfind(result, 'e');
if (~isempty(ep))
    ex = str2double(result(ep+1:end));
    % remove leading '+' and '0' from exponent
    result = [result(1:ep-1) sprintf('e%d', ex)];
    for i = 1 : ex - floor(ex / 3) * 3
        ex = ex - 1;
        dp = strfind(result, '.');
        ep = strfind(result, 'e');
        if (isempty(dp))
            % no decimal point -> add a trailing zero
            result = [result(1:ep-1) '0' sprintf('e%d', ex)];
        else
            if (dp == ep - 2)
                % 1 decimal digit -> remove the decimal point
                result = [result(1:dp-1) result(dp+1) sprintf('e%d', ex)];
            else
                % more than one decimal digit -> move the decimal point to the right
                result = [result(1:dp-1) result(dp+1) '.' result(dp+2:ep-1) sprintf('e%d', ex)];
            end
        end
    end
end
