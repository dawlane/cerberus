/*
	A wrapper in many cases, is required to interface to any librarys that do not use C/C++ base types.
	For example, a Cerberus String would require a wrapper.
	For a library to work with multiple compilers, it has to use C style function calls due to the incompatiblities of
	C++ name mangling.
*/

#include "cx_shared_library_upper.h"

// The Cerberus wrapper functions
namespace CXSharedLibraryUpper {
	String cx_says( String mgs )
	{
	
		// As the cx_string_message will use memory on the heap, it will need to be cleared.
		// As the returned value will be a memory pointer; we store it to be deleted later.
		char *str=cx_string_transform( mgs.ToCString<char>() );
	
		// There was an issue, so return an empty string.
		if(str==nullptr) return String("");
	
		// Okay. Now we need a Cerberus string from the value stroed.
		// A String should automatically copy it.
		String val=String( str );
		
		// Now the memory can be freed.
		::cx_static_free_string(str);
		
		// The last step is to return the Cerebrus string back for use.
		return val;
		
	}
}