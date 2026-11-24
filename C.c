#include <stdio.h>

//##########################################
//    Main Program ask values
//##########################################
int main() {
    const char hex_chars[] = "0123456789ABCDEF";
    char buffer[16];

    int count;
    printf("How many bytes: ");
    scanf("%d", &count);

    int i = 0;
    unsigned int sum = 0;

    if (count <= 0) {
        printf("Invalid count.\n");
        return 1;
    }

//##########################################
//    Loop binary and sum
//##########################################
    do {
        printf("8-bit binary: ");
        scanf("%15s", buffer);

        char *p = buffer;
        unsigned int value = 0;

        while (1) {
            unsigned int bit = (unsigned int)(*p++ - '0');
            if (bit >= 2) break;
            value = (value << 1) + bit;
        }

        sum += value;
        i++;
    } while (i < count);

//##########################################
//    Wrap around and one complement
//##########################################
    unsigned int carry;
    while ((carry = sum >> 8) != 0) {
        sum = (sum & 0xFF) + carry;
    }
    unsigned int checksum = (~sum) & 0xFF;

//##########################################
//    Print binary and Hex
//##########################################
    printf("Checksum (Bin): ");
    i = 7;
    do {
        printf("%d", (checksum >> i) & 1);
        i--;
    } while (i >= 0);

    printf("\nChecksum (Hex): 0x%c%c\n",
           hex_chars[checksum >> 4],
           hex_chars[checksum & 0x0F]);

    return 0;
}
