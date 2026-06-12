#include <stdio.h>
#include <stdlib.h>
#include "add.h"
#include "sub.h"

int main() {
    printf("5 + 2 - 3 = %d\n", sub(add(5, 2), 3));
    return EXIT_SUCCESS;
}
