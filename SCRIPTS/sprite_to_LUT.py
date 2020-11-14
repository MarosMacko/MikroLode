from PIL import Image

import glob, os
for file in glob.glob("../SPRITES/*.tiff"):
    im = Image.open(file)
    out = open(os.path.splitext(file)[0]+'.sprite', "w")

    r, g, b, a = im.split()
    width, height = im.size
    for color in [r, g, b]:
        msg = ""
        
        for y in range(height):
            
            for x in range(width):
                thisPixel = color.getpixel((x, y))
                data = "X\""
                
                data += format(thisPixel // 2, 'x').zfill(2) #8bit to 7bit, to hex, prepend 0 if needed
                data += "\","              
                msg = data + msg
                           
        msg = msg.rstrip(',') # remove last ,
        msg += "\n);"
        msg = "\n\nconstant " + ('r' if (color == r) else ('g' if (color == g) else 'b')) + "_rom : RomType := ( \n\t" + msg
        out.write(msg)
        
        print(msg)
    out.close()