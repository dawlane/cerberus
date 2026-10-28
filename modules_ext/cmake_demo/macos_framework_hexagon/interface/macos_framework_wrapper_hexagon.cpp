/*
	A wrapper in many cases, is required to interface to any librarys that do not use C/C++ base types.
	For example, a Cerberus String would require a wrapper.
	For a library to work with multiple compilers, it has to use C style function calls due to the incompatiblities of
	C++ name mangling.
*/

#include <cx_framework_hexagon/cx_macos_framework_hexagon.h>

String cx_draw_hexagon(int sides) {

	char *buffer=draw_hexagon(sides);

	// There was an issue, so return an empty string.
	if(buffer==nullptr) return String("");

	String val=String( buffer );

	draw_hexagon_free( buffer );
	
	return val;
}