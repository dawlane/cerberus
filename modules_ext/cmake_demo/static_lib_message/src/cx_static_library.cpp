#include "../include/cx_static_library_message.h"

#include <cstdio>
#include <cstring>

namespace StaticLibraryMessage{
    char* cx_string_message(const char* input)
    {
        if (input == nullptr)
        {
            return nullptr;
        }

        constexpr const char* prefix = "Cerebus-X says ";
        constexpr const char* suffix = ". So are you using it?";

        const std::size_t prefixLength = std::strlen(prefix);
        const std::size_t inputLength = std::strlen(input);
        const std::size_t suffixLength = std::strlen(suffix);

        const std::size_t length =
            prefixLength +
            inputLength +
            suffixLength;

        char* output = new char[length + 1];

        std::memcpy(
            output,
            prefix,
            prefixLength
        );

        std::memcpy(
            output + prefixLength,
            input,
            inputLength
        );

        std::memcpy(
            output + prefixLength + inputLength,
            suffix,
            suffixLength
        );

        output[length] = '\0';

        return output;
    }

    void cx_static_free_string(const char* string)
    {
        delete[] string;
    }
}