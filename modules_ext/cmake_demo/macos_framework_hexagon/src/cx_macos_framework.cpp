#include "cx_macos_framework_hexagon.h"

#include <cstdlib>
#include <cstring>
#include <string>

char* draw_hexagon(int side) {
    if (side < 2) {
        // Return an empty, allocated string so the caller can safely free() it
        char* empty = static_cast<char*>(std::malloc(1));
        if (empty) empty[0] = '\0';
        return empty;
    }

    std::string result;

    // 1. Top horizontal row
    result += std::string(side - 1, ' ') + std::string(side, '*') + "\n";

    // 2. Upper sloped sides (excluding top row)
    for (int i = 1; i < side - 1; ++i) {
        int leading = side - 1 - i;
        int inner = side + 2 * (i - 1);
        result += std::string(leading, ' ') + '*'
                 + std::string(inner, ' ') + "*\n";
    }

    // 3. Middle widest section
    result += '*' + std::string(side + 2 * (side - 2), ' ') + "*\n";

    // 4. Lower sloped sides (excluding bottom row)
    for (int i = side - 2; i >= 1; --i) {
        int leading = side - 1 - i;
        int inner = side + 2 * (i - 1);
        result += std::string(leading, ' ') + '*'
                 + std::string(inner, ' ') + "*\n";
    }

    // 5. Bottom horizontal row
    result += std::string(side - 1, ' ') + std::string(side, '*') + "\n";

    // Allocate a char* buffer with malloc so it pairs correctly with draw_hexagon_free()
    char* buffer = static_cast<char*>(std::malloc(result.size() + 1));
    if (buffer) {
        std::memcpy(buffer, result.c_str(), result.size() + 1);
    }
    return buffer;
}

void draw_hexagon_free(char* buffer) {
    std::free(buffer);
}