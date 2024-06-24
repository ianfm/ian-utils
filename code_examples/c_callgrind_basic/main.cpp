#include "main.h"

int main() {
   std::cout << "Beginning rollover counter" << std::endl;
    int8_t count = 0;
    for (;;) {
        count += 1;
	std::cout << (int)count << std::endl;
        header_func();
    }
}
