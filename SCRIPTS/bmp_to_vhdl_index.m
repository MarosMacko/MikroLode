% Converter from index sprite file to vhdl code

filename = uigetfile(".bmp");
a = imread(filename);
% File must be size 16 x n*16, one sprite tile is written to one line
a = sum(a, 3);
textout = fopen("textout.txt", 'w');
c = string;
for i = 1:size(a, 2)/size(a, 1)
    c = "";
    b = a(:,(i-1)*size(a, 1)+(1:size(a, 1)));
    b = reshape(b', [], 1);
    for j = 1:size(b, 1)
%         c = append(c, """", dec2bin(b(j), 3), """, ");
        c = append(c, "x""", dec2hex(b(j)), """, ");
%         c = append(c, "x""", dec2hex(b(2*j-1)), dec2hex(b(2*j)), """, ");
    end 
    fprintf(textout, '%s \n', c);
end

fclose(textout);