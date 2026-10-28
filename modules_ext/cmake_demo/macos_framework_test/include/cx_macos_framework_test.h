#ifndef MACOS_FRAMEWORK_TEST_H
#define MACOS_FRAMEWORK_TEST_H

#define FRAMEWORK_EXPORT __attribute__((visibility("default")))

FRAMEWORK_EXPORT const char* get_framework_status();

#endif // MACOS_FRAMEWORK_TEST_H