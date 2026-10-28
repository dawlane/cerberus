/*
	A wrapper in many cases, is required to interface to any librarys that do not use C/C++ base types.
	For example, a Cerberus String would require a wrapper.
	But If a library is to be match with the same compiler, then normal C++ headers can be used.
	To avoid name clashes, use a name spaces
*/

#include "cx_static_library_message.h"

/*
	Cerberus Binding
	Function CerberusSays:String( msg:String )="CXStaticLibraryMessage::cx_says"
*/

// The Cerberus wrapper functions. As a number of libraries use cx_says, it's placed in a name space.
namespace CXStaticLibraryMessage {
	String cx_says( String mgs )
	{
	
		// As the cx_string_message will use memory on the heap, it will need to be cleared.
		// As the returned value will be a memory pointer; we store it to be deleted later.
		char *str=::StaticLibraryMessage::cx_string_message( mgs.ToCString<char>() );
	
		// There was an issue, so return an empty string.
		if(str==nullptr) return String("");
	
		// Okay. Now we need a Cerberus string from the value stroed.
		// A String should automatically copy it.
		String val=String( str );
		
		// Now the memory can be freed.
		StaticLibraryMessage::cx_static_free_string(str);
		
		// The last step is to return the Cerberus string back for use.
		return val;
		
	}
}