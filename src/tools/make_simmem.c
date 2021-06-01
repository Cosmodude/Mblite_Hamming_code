#include <stdio.h>
#include <string.h>


unsigned power (unsigned base, unsigned n) {
    unsigned p;

    for( p = 1; n > 0; --n)
        p = p*base;
    return p;
}

void print_help(char * name)
{
    fprintf(stderr, "%s converts a binary file into init txt file\n", name);
    fprintf(stderr, "Usage: %s INFILE OUTFILE SIZE\n", name);
}


int main(int argc, char *argv[]) {

    FILE *infile, *outfile;
    int c[4], insize;
    unsigned ram_size;
    unsigned i = 0;
    unsigned m = 0;

    if (argc != 4) {
        print_help(argv[0]);
        return(1);
    }

    infile = fopen(argv[1], "rb");
    if (!infile) {
        printf("Cannot open file %s\n", argv[1]);
        return(1);
    }

    outfile = fopen(argv[2], "w");
    if (!outfile) {
        printf("Cannot open file %s\n", argv[2]);
        return(1);
    }

    if (strlen(argv[3]) <= 0) {
        printf("Argument SIZE missing", argv[3]);
        return(1);
    }

    ram_size = atoi(argv[3]);
    // determine the size of the input file in bytes
    fseek(infile, 0, SEEK_END);
    insize = ftell(infile);
    rewind(infile);

    if (ram_size % 8) {
        printf("Size should be 64-bit alligned\n");
        return(1);
    }    
    if (insize > ram_size) {
        printf("Size (%d bytes) is too small (at least %d bytes needed)\n", ram_size, insize);
        return(1);
    }


    while (i < insize) {
        c[0] = fgetc(infile);
        c[1] = fgetc(infile);
        c[2] = fgetc(infile);
        c[3] = fgetc(infile);

        for (m = 0; m < 4; m++)        
            fprintf(outfile, "%.2X", (unsigned char) c[m] & 0x0ff);
            
        fprintf(outfile, "00000000\n");

        i += 4;
        /*if (!(i % 8))*/
        
    }

        // Fill rest of file if not full yet
    while (i < ram_size) {
             
        fprintf(outfile, "0000000000000000\n");

        i += 8;

    }


  fclose(infile);
  fclose(outfile);

  return 0;

}
