Shared Library Message

Description: Simple C function to return a lower case string to upper case.

Header name: cx_static_library_message
Interface Name: shared_lib_wrapper_upper
	CXSharedLibUpper: cx_say( String mgs )

Cerberus Binding:
	Function CerberusSays:String( msg:String )="CXSharedLibUpper::cx_says"
	
Cerberus Import:
	Import cmake_demo.shared_lib_upper
