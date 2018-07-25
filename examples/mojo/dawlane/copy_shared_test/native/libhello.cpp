#include <string>
#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

// As only Windows would use __declspec. It needs to be filtered out
#if defined _WIN32 || defined WIN32
	#ifdef ADD_EXPORTS
		#define ADDAPI __declspec(dllexport)
	#else
		#define ADDAPI __declspec(dllimport)
		#pragma message ( "LIBHELLO BIND: DEFINED ADDAPI" )
	#endif
	// Visual Studio hates ADDCALL being set
	//#if defined _WIN32
	//	#define ADDCALL __cdecl
	//	#pragma message ( "LIBHELLO BIND: DEFINED ADDCALL" )
	//#else
		#define ADDCALL
	//#endif
#else
	#define ADDAPI
	#define ADDCALL
	#pragma message ( "LIBHELLO BIND: NON WINDOWS OS" )
#endif

ADDCALL ADDAPI char *Msg(const char *name);
ADDCALL ADDAPI void MemFree();

#ifdef __cplusplus
}
#endif

// Wrapper function for Cerberus
String HelloMgs( String msg );

String HelloMsg( String msg ){
	String result= Msg(msg.ToCString<char>());	
	MemFree();
	return result;
}