#include "../include/cx_shared_library_rect.h"

#include <cstdlib>

char* draw_console_rect(int width, int height) {
    // Basic validation to ensure the shape can be rendered
    if (width <= 0 || height <= 0) {
        char* empty = new char[1];
        empty[0] = '\0';
        return empty;
    }

    // Each row has 'width' chars + 1 newline; plus a trailing '\0'
    int size = height * (width + 1) + 1;
    char* buffer = new char[size];
    int idx = 0;

    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            // Check if the current coordinate sits on any of the outer borders
            if (y == 0 || y == height - 1 || x == 0 || x == width - 1) {
                buffer[idx++] = '*';
            } else {
                buffer[idx++] = ' '; // Empty interior
            }
        }
        buffer[idx++] = '\n'; // Move to the next row
    }

    buffer[idx] = '\0';
    return buffer;
}

void console_rect_free(char* buffer) {
    std::free(buffer);
}