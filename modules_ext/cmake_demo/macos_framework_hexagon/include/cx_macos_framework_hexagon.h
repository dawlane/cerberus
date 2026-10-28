#ifndef MACOS_FRAMEWORK_HEXAGON_H
#define MACOS_FRAMEWORK_HEXAGON_H

#define FRAMEWORK_EXPORT __attribute__((visibility("default")))

FRAMEWORK_EXPORT char* draw_hexagon( int side );
FRAMEWORK_EXPORT void draw_hexagon_free(char* buffer);

#endif // MACOS_FRAMEWORK_HEXAGON_H