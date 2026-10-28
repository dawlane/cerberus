Static Library Message

Description: Simple C function to return Cerberus-X says {message}. So are you using it? 

Header name: cx_static_library_message
Interface Name: static_lib_wrapper_message
	CXStaticLibMessage: cx_say( String mgs )

Cerberus Binding:
	Function CerberusSays:String( msg:String )="CXStaticLibraryMessage::cx_says"
	
Cerberus Import:
	Import cmake_demo.static_lib_message
