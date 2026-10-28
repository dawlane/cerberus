/*
    Simpler namespace header.
*/


#ifndef CX_STATIC_LIBRARY_MESSAGE_H
#define CX_STATIC_LIBRARY_MESSAGE_H

namespace StaticLibraryMessage{

    char* cx_string_message(const char* input);
    void cx_static_free_string(const char* string);
}
#endif // CX_STATIC_LIBRARY_MESSAGE_H