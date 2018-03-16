#include <stdio.h>
#include "lib.h"

Body new_body() { return (Body) { .name = 2 }; }
void dump_name(Body b) { printf("%d\n", b.name); }
