//---------------------------------------------------------------------------------
// x86 32bit Project - ARKO 20L
// Binary Turtle Graphics - works on linux servers with NASM and gcc (see makefile)
// Adam Lisichin
//---------------------------------------------------------------------------------
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define INSTRUCTIONS_FILE "input.bin"
#define BITMAP_FILE "output.bmp"
#define CONFIG_FILE "config.txt"
#define BMP_PIXEL_OFFSET 54
#define BMP_HEADER_SIZE 40
#define BMP_PLANES 1
#define BMP_BITCOUNT 24
#define BMP_COMPRESSION 0
#define BMP_H_RES 12000
#define BMP_V_RES 12000

typedef struct {
    unsigned int x_pos;         // current x
    unsigned int y_pos;         // current y
    unsigned char pen_blue;     // R
    unsigned char pen_green;    // G
    unsigned char pen_red;      // B
    unsigned char pen_ud;       // 0 - up; 1 - down
    unsigned char dir;          // 00 - right; 01 - up; 10 - left; 11 - down
    unsigned char is_setpos;    // if in the middle of set_position cmd
} TurtleContextStruct;

typedef struct {
    unsigned short bfType;
    unsigned long  bfSize;
    unsigned short bfReserved1;
    unsigned short bfReserved2;
    unsigned long  bfOffBits;       // offset of the pixel data
    unsigned long  biSize;          // header size
    unsigned long  biWidth;
    unsigned long  biHeight;
    unsigned short biPlanes;
    unsigned short biBitCount;      // BPP: 24
    unsigned long  biCompression;
    unsigned long  biSizeImage;     // bitmap size
    unsigned long biXPelsPerMeter;
    unsigned long biYPelsPerMeter;
    unsigned long  biClrUsed;       // colors in color table
    unsigned long  biClrImportant;  // important colors
} BmpHeader;


unsigned char * createBMP(unsigned int width, unsigned int height, unsigned int * bmpbuffer_size) {
    // bitmap parameters
    unsigned int row_size = (width * 3 + 3) & ~3;
    unsigned int bitmap_size = row_size * height;
    *bmpbuffer_size = BMP_PIXEL_OFFSET + bitmap_size;

    unsigned char *bitmap = (unsigned char *) malloc(*bmpbuffer_size);

    // bitmap header init
    BmpHeader header;

    header.bfType = 0x4D42;   // B,M (le)
    header.bfSize = *bmpbuffer_size;
    header.bfReserved1 = 0;
    header.bfReserved2 = 0;
    header.bfOffBits = BMP_PIXEL_OFFSET;
    header.biSize = BMP_HEADER_SIZE;
    header.biWidth = width;
    header.biHeight = height;
    header.biPlanes = BMP_PLANES;
    header.biBitCount = BMP_BITCOUNT;
    header.biCompression = BMP_COMPRESSION;
    header.biSizeImage = bitmap_size;
    header.biXPelsPerMeter = BMP_H_RES;
    header.biYPelsPerMeter = BMP_V_RES;
    header.biClrUsed = 0;
    header.biClrImportant = 0;

    memcpy(bitmap, &header, BMP_PIXEL_OFFSET);

    // fill white
    unsigned int * tmptr = (unsigned int *)(bitmap+BMP_PIXEL_OFFSET);
    int cnt;
    for (cnt = 0; cnt++ < bitmap_size>>2; tmptr++) {
        *tmptr = 0xFFFFFFFF;
    }

    // created bitmap buffer address
    return bitmap;
}


int saveBMP(unsigned char *bmpbuffer, unsigned int bmpbuffer_size) {
    FILE *bfile;

    bfile = fopen(BITMAP_FILE, "wb");
    if (bfile == 0) {
        printf("bmp write - file problem");
        return 0;
    }

    fwrite(bmpbuffer, 1, bmpbuffer_size, bfile);

    fclose(bfile);

    return 1;
}


int read_instructions(const unsigned short ** instrbuffer) {
    FILE* finstr = 0;

    finstr = fopen(INSTRUCTIONS_FILE, "rb");
    if (finstr == 0){
        printf("instr read - file problem");
        return 0;
    }

    fseek(finstr, 0L, SEEK_END);
    int fsize = ftell(finstr);
    rewind(finstr);

    *instrbuffer = malloc(fsize);
    if (*instrbuffer == NULL) {
        printf("instr read - mem problem");
        fclose(finstr);
        return 0;
    }

    fread(*instrbuffer, fsize, 1, finstr);

    fclose(finstr);

    return fsize >> 1;
}

int read_config(unsigned int * width, unsigned int * height) {
    FILE *fconf;

    fconf = fopen(CONFIG_FILE, "r");
    if (fconf == 0) {
        printf("conf read - file problem");
        return 0;
    }

    fscanf(fconf, "%d", width);
    fscanf(fconf, "%d", height);

    fclose(fconf);

    return 1;
}

extern int exec_turtle_cmd(unsigned char *dest_bitmap, unsigned char *command, TurtleContextStruct *tc);

int main(void)
{

    TurtleContextStruct trtl_context;

    // read instruction file
    unsigned short * instrbuffer;
    unsigned char * bmpbuffer;

    int instr_number;
    instr_number = read_instructions(&instrbuffer);
    if (instr_number == 0){
        printf("main - no instructions");
        return -1;
    }

    int instr_cnt = 0;
    unsigned short * instr_ptr;
    instr_ptr = instrbuffer;

    // read bitmap size from config file
    int width;
    int height;
    int cnf_result;
    cnf_result = read_config(&width, &height);
    if (cnf_result == 0){
        printf("main - conf file problem");
        return -2;
    }

    // bitmap buffer creation
    unsigned int bmpbuffer_size;
    bmpbuffer = createBMP(width, height, &bmpbuffer_size);

    if (*bmpbuffer == NULL) {
        printf("bmp read - mem problem");
        free(instrbuffer);
        return -3;
    }
    // default values
    trtl_context.x_pos = 0;
    trtl_context.y_pos = 0;
    trtl_context.is_setpos = 0;

    // main program loop
    while (instr_cnt < instr_number) {

        int trtl_result;
        trtl_result = exec_turtle_cmd(bmpbuffer, instr_ptr, &trtl_context);
        printf("instr no: %d, result: %d, posx = %d, posy = %d, dir = %d, ud = %d, B = %d, G = %d, R = %d, \n",
                instr_cnt, trtl_result, trtl_context.x_pos, trtl_context.y_pos, trtl_context.dir,
                trtl_context.pen_ud, trtl_context.pen_blue, trtl_context.pen_green, trtl_context.pen_red);

        instr_ptr++;
        instr_cnt++;
    }

    // bitmap save to file
    int bmp_result;
    bmp_result = saveBMP(bmpbuffer, bmpbuffer_size);

    // memory release
    free(instrbuffer);
    free(bmpbuffer);

    return 0;
}
