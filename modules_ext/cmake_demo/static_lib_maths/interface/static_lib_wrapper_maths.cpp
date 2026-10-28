/*
	A wrapper in many cases, is required to interface to any librarys that do not use C/C++ base types.
	For example, a Cerberus String would require a wrapper.
	For a library to work with multiple compilers, it has to use C style function calls due to the incompatibilities of
	C++ name mangling. But If a library is to be match with the same compiler, then normal C++ headers can be used.
*/

#include "cx_static_library_maths.h"

/*
    Cerberus bindings:
    Function Addition:Float( a:Float,b:Float ) = "cx_add"
	Function Subtract:Float( a:Float,b:Float ) = "cx_sub"
	Function Multiple:Float( a:Float,b:Float ) = "cx_mul"
	Function Divide:Float( a:Float,b:Float ) = "cx_div"
*/

// Wrapper declarations
/*namespace CXStaticLibraryMaths
{
    float cx_add(float a, float b);
    float cx_sub(float a, float b);
    float cx_mul(float a, float b);
    float cx_div(float a, float b);
}


// The Cerberus wrapper functions in side a name space.
namespace CXStaticLibraryMaths
{
    float cx_add(float a, float b)
    {
        return ::cx_add(a, b);
    }

    float cx_sub(float a, float b)
    {
        return ::cx_sub(a, b);
    }

    float cx_mul(float a, float b)
    {
        return ::cx_mul(a, b);
    }

    float cx_div(float a, float b)
    {
        return ::cx_div(a, b);
    }
}*/


