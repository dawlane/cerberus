/*
	A wrapper in many cases, is required to interface to any librarys that do not use C/C++ base types.
	For example, a Cerberus String would require a wrapper.
	For a library to work with multiple compilers, it has to use C style function calls due to the incompatiblities of
	C++ name mangling.
*/

#include <cx_framework_test/cx_macos_framework_test.h>

// The Cerebreus wrapper functions
namespace CXMacOSFramework {
	String cx_says()
	{
	
		// Okay. Now we need a Cerberus string from the value stroed.
		// A String should automatically copy it.
		String val=String( get_framework_status() );
		
		// The last step is to return the Cerebrus string back for use.
		return val;
		
	}
}