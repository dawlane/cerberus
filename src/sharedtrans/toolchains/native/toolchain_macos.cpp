// This lot is going to need some improving. It's basically just a kludge
// For now it's a quick and dirty Intel x86/x86_64 little endian with a few checks
// for byte ordering.

#include <mach-o/fat.h>
#include <mach-o/loader.h>
#include <CoreFoundation/corefoundation.h>

// Make thes match what's in the Ceberus code
#define LITTLE_ENDIAN_32	0x01
#define LITTLE_ENDIAN_64	0x02
#define BIG_ENDIAN_32		0x03
#define BIG_ENDIAN_64		0x04

#define FAT_LITTLE_ENDIAN	0x05
#define FAT_BIG_ENDIAN		0x06

// Define all known CPU types with a code
#define ANY_CPU				0x00
#define x86 				0x01
#define x86_64 				0x02

extern "C"
{

	int BigInt2HostInt( int val )
	{
		return CFSwapInt32BigToHost( val);
	}

	// Read the MAGIC number of the file.
	int MachO( BBDataBuffer *buffer, int offset = 0 )
	{
		int mach_o = buffer->PeekInt(offset);
		
		switch(CFByteOrderGetCurrent())
		{
		 	case CFByteOrderLittleEndian :
		 		if(mach_o==MH_MAGIC) return LITTLE_ENDIAN_32;
		 		if(mach_o==MH_MAGIC_64) return LITTLE_ENDIAN_64;
		 		if(mach_o==FAT_MAGIC) return FAT_LITTLE_ENDIAN;
		 		
		 		if(mach_o==MH_CIGAM) return BIG_ENDIAN_32;
		 		if(mach_o==MH_CIGAM_64) return BIG_ENDIAN_64;
		 		if(mach_o==FAT_CIGAM) return FAT_BIG_ENDIAN;
		 		
		 		break;
		 		
		 	case CFByteOrderBigEndian :
		 		if(mach_o==MH_MAGIC) return BIG_ENDIAN_32;
		 		if(mach_o==MH_MAGIC_64) return BIG_ENDIAN_64;
		 		if(mach_o==FAT_MAGIC) return FAT_BIG_ENDIAN;
		 		
		 		if(mach_o==MH_CIGAM) return LITTLE_ENDIAN_32;
		 		if(mach_o==MH_CIGAM_64) return LITTLE_ENDIAN_64;
		 		if(mach_o==FAT_CIGAM) return FAT_LITTLE_ENDIAN;
		 		
		 		break;
		 		
		 	default :
		 		return 0;
		}
		
		return 0;
	}
	
	// Convert the OS CPU maco detection to our own cpu id
	int CPUConvert( int val ){
		
		if(val==CPU_TYPE_ANY) return ANY_CPU;
		if(val==CPU_TYPE_X86) return x86;
		if(val==CPU_TYPE_X86_64) return x86_64;
		
		return 0;
	}
	
	// Normal dylibs would have the CPU type right after the MAGIC number
	int CPU( BBDataBuffer *buffer, int offset = 0x04 )
	{
		return CPUConvert(buffer->PeekInt(offset));
	
	}
	
}