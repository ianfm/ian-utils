#include <iostream>
#include <string>

int main() {
   std::cout << "Beginning rollover counter" << std::endl;
    int8_t count = 0;
    for (;;) {
        count += 1;
	std::cout << count << std::endl;       // displays the character encoded by count
        #std::cout << (int)count << std::endl;  // displays numerical value of count
    }
}
