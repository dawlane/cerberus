/*
	A wrapper in many cases, is required to interface to any librarys that do not use C/C++ base types.
	For example, a Cerberus String would require a wrapper.
	For a library to work with multiple compilers, it has to use C style function calls due to the incompatibilities of
	C++ name mangling.
*/

#include "cx_shared_library_rect.h"

String cx_draw_console_rect(int width,int height) {

	char *buffer=draw_console_rect(width,height);

	// There was an issue, so return an empty string.
	if(buffer==nullptr) return String("");

	// Okay. Now we need a Cerberus string from the variable buffer.
	// A String should automatically copy it.
	String val=String( buffer );
	
	// Now the memory can be freed.
	console_rect_free(buffer);
	
	// The last step is to return the Cerberus string back for use.
	return val;
}