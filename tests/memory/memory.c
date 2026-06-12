/*******************************************************************************
 * Name          : memory.c
 * Author        : Brian S. Borowski
 * Version       : 1.0
 * Date          : February 6, 2023
 * Last modified : February 21, 2025
 * Description   : Demonstrates pointers.
 ******************************************************************************/
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int var;

void increment_both(int *a, int *b) {
    (*a)++; // postfix requires parens
    ++*b;   // prefix does not
}

void swap(int *a, int *b) {
    int temp = *a;
    *a = *b;
    *b = temp;
}

int main(int argc, char **argv) {
    // Pointer immutable resides on the stack. But the string literal it points
    // to is in the read-only section of the initialized data segment. 
    char *immutable = "I am immutable!";
    // If you attempt to change a character, it will lead to undefined behavior,
    // likely resulting in a segmentation fault.
    // immutable[0] = 'i';
    printf("Immutable string: %s\n", immutable);

    // The variable mutable resides on the stack. Since this is an array of
    // characters, they begin at the address of variable mutable.
    char mutable[] = "I am mutable!";    
    mutable[0] = 'i';

    printf("Mutable string: %s\n", mutable);
    printf("Address of immutable var on stack: %lu\n",
           (long unsigned)&immutable);
    printf("Address where immutable points to: %lu\n",
           (long unsigned)immutable);

    // The address of mutable and address of mutable[0] are the same, since
    // the mutable array is on the stack, and the address of the variable also
    // refers to the address of the first character in the array.
    printf("Address of mutable var on stack  : %lu\n",
           (long unsigned)&mutable);
    printf("Address where mutable points to  : %lu\n",
           (long unsigned)&mutable[0]);

    /*
    strings1:
    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
    |'H'|'e'|'l'|'l'|'o'| 0 |'H'|'i'| 0 |   |   |   |'B'|'y'|'e'| 0 |   |   |
    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
    */
    char strings1[3][6] = { "Hello", "Hi", "Bye" };
    strings1[0][0] = 'h';
    for (int i = 0; i < 3; i++) {
        printf("%s, len: %lu, size: %lu\n",
               *(strings1 + i),
               strlen(*(strings1 + i)),
               sizeof(*(strings1 + i)));
    }

    for (int i = 0; i < 18; i++) {
        // This is ugly, but you can print each char by first casting to
        // strings1 to a char *, then add offset i, which will move up 1 byte
        // with each iteration, and finally dereference.
        char c = *((char *)strings1 + i);
        // Or you can do it this way:
        // char c = *(*strings1 + i);
        if (isprint(c)) {
            printf("%c", c);
        } else {
            putc('-', stdout);
        }
    }
    printf("\n");

    /*
    strings2:
    +------+      +---+---+---+---+---+---+
    |   ---|----->|'H'|'e'|'l'|'l'|'o'| 0 |
    +------+      +---+---+---+---+---+---+
    |   ---|----->|'H'|'i'| 0 |
    +------+      +---+---+---+---+
    |   ---|----->|'B'|'y'|'e'| 0 |       
    +------+      +---+---+---+---+
    */
    char *strings2[] = { "Hello", "Hi", "Bye" };
    // Strings in strings2 are immutable.
    // strings2[0][0] = 'h';

    // However, you can assign a different string to a particular index.
    // strings2[2] = strings2[1];
    // Or even this:
    // strings2[2] = "Good morning!";
    // But do not change a character within the string. They reside in the
    // read-only section of initialized data.
    // strings2[2][0] = 'g';

    for (int i = 0; i < 3; i++) {
        printf("%s, len: %lu, size: %lu\n",
               *(strings2 + i),
               strlen(*(strings2 + i)),
               sizeof(*(strings2 + i)));
    }
    printf("Address of var strings1 on stack: %lu\n", (unsigned long)strings1);
    printf("Address of var strings1 on stack: %lu\n", (unsigned long)&strings1);
    printf("Address of var strings2 on stack: %lu\n", (unsigned long)strings2);
    printf("Address of var strings2 on stack: %lu\n", (unsigned long)&strings2);
    printf("Address of strings2[0]: %lu\n", (unsigned long)&strings2[0]);
    printf("Address of strings2[1]: %lu\n", (unsigned long)&strings2[1]);
    printf("Address of strings2[2]: %lu\n", (unsigned long)&strings2[2]);
    printf("Address of where strings2[0] points: %lu\n",
           (unsigned long)&strings2[0][0]);
    printf("Address of where strings2[1] points: %lu\n",
           (unsigned long)&strings2[1][0]);
    printf("Address of where strings2[2] points: %lu\n",
           (unsigned long)&strings2[2][0]);
    // Working with uninitialized data.
    printf("Address of var: %lu\n", (unsigned long)&var);
    printf("Value of var: %d\n", var);

    int a = 2, b = 3;
    increment_both(&a, &b);
    printf("a = %d, b = %d\n", a, b);

    int **intarr = malloc(3 * sizeof(int *));
    int val = 0;
    for (int i = 0; i < 3; i++) {
        intarr[i] = malloc(3 * sizeof(int));
        for (int j = 0; j < 3; j++) {
            // intarr[i][j] = val++;
            *(*(intarr + i) + j) = val++;
        }
    }
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            printf("%d", *(*(intarr + i) + j));
        }
        printf("\n");
    }
    for (int i = 0; i < 3; i++) {
        free(*(intarr + i));
    }
    free(intarr);

    return EXIT_SUCCESS;
}
