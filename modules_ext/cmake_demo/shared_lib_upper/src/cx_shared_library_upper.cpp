#include "../include/cx_shared_library_upper.h"

#include <cctype>
#include <cstring>
#include <memory>


char* cx_string_transform(const char* input)
{
    if (input == nullptr)
    {
        return nullptr;
    }

    const std::size_t length = std::strlen(input);

    char* output = new char[length + 1];

    for (std::size_t i = 0; i < length; ++i)
    {
        output[i] = static_cast<char>(
            std::toupper(static_cast<unsigned char>(input[i]))
        );
    }

    output[length] = '\0';

    return output;
}

void  cx_static_free_string(const char* string)
//void cx_shared_library_upper_free_string(const char* string)
{
    delete[] string;
}