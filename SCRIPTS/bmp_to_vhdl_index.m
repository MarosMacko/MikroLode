a = imread('tiles_and_ships_rev_index.bmp');

b = string(zeros(length(a(:,1))/2));

for i = 1:(length(a(:,1))/2)
    b(i) = "";
    for j = 1:length(a(1,:))
        
        b(i) = append(b(i), "x""", dec2hex(a(2*i-1,j)), dec2hex(a(2*i,j)), """, ");       
    end
end