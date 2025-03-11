// Stdcpp trans.system runtime.
//
// Placed into the public domain 24/02/2011.
// No warranty implied; use as your own risk.

//static String::CString<char> C_STR( const String &t ){
//		return t.ToCString<char>();
//};
	
class BBOSModule{

	#if _WIN32
	
	#ifndef PATH_MAX
		#define PATH_MAX MAX_PATH
	#endif
		
		typedef wchar_t OS_CHAR;
		typedef struct _stat stat_t;
		
		#define mkdir( X,Y ) _wmkdir( X )
		#define rmdir _wrmdir
		#define remove _wremove
		#define rename _wrename
		#define stat _wstat
		#define _fopen _wfopen
		#define system _wsystem
		#define realpath(X,Y) _wfullpath( Y,X,PATH_MAX )	//Note: first args SWAPPED to be posix-like!
		#define opendir _wopendir
		#define readdir _wreaddir
		#define closedir _wclosedir
		#define DIR _WDIR
		#define dirent _wdirent
	
	#elif __APPLE__
		typedef char OS_CHAR;
		typedef struct stat stat_t;
		#define _fopen fopen
	
	#elif __linux
		typedef char OS_CHAR;
		typedef struct stat stat_t;
		#define _fopen fopen
	
	#endif
		
		public:
		static String::CString<char> C_STR( const String &t ){
			return t.ToCString<char>();
		};
		
		static String::CString<OS_CHAR> OS_STR( const String &t ){
			return t.ToCString<OS_CHAR>();
		};
	
	
		static String  HostOS(){
			#if _WIN32
				return "winnt";
			#elif __APPLE__
				return "macos";
			#elif __linux
				return "linux";
			#else
				return "";
			#endif
			};
			
		static String RealPath( String path ){
			std::vector<OS_CHAR> buf( PATH_MAX+1 );
			if( realpath( OS_STR( path ),&buf[0] ) ){}
			buf[buf.size()-1]=0;
			for( int i=0;i<PATH_MAX && buf[i];++i ){
				if( buf[i]=='\\' ) buf[i]='/';
				
			}
			return String( &buf[0] );
		};
			
		static int FileType( String path ){
			stat_t st;
			if( stat( OS_STR(path),&st ) ) return 0;
			switch( st.st_mode & S_IFMT ){
			case S_IFREG : return 1;
			case S_IFDIR : return 2;
			}
			return 0;
		};
	
		static int FileSize( String path ){
			stat_t st;
			if( stat( OS_STR(path),&st ) ) return -1;
			return st.st_size;
		};
	
		static int FileTime( String path ){
			stat_t st;
			if( stat( OS_STR(path),&st ) ) return -1;
			return st.st_mtime;
		};
	
		static String LoadString( String path ){
			if( FILE *fp=_fopen( OS_STR(path),OS_STR("rb") ) ){
				String str=String::Load( fp );
				if( _str_load_err ){
					bbPrint( String( _str_load_err )+" in file: "+path );
				}
				fclose( fp );
				return str;
			}
			return "";
		};
			
		static int SaveString( String str,String path ){
			if( FILE *fp=_fopen( OS_STR(path),OS_STR("wb") ) ){
				bool ok=str.Save( fp );
				fclose( fp );
				return ok ? 0 : -2;
			}else{
		//		printf( "FOPEN 'wb' for SaveString '%s' failed\n",C_STR( path ) );
				fflush( stdout );
			}
			return -1;
		};
	
		static Array<String> LoadDir( String path ){
			std::vector<String> files;
			
		#if _WIN32
	
			WIN32_FIND_DATAW filedata;
			HANDLE handle=FindFirstFileW( OS_STR(path+"/*"),&filedata );
			if( handle!=INVALID_HANDLE_VALUE ){
				do{
					String f=filedata.cFileName;
					if( f=="." || f==".." ) continue;
					files.push_back( f );
				}while( FindNextFileW( handle,&filedata ) );
				FindClose( handle );
			}else{
		//		printf( "FindFirstFileW for LoadDir(%s) failed\n",C_STR(path) );
				fflush( stdout );
			}
			
		#else
	
			if( DIR *dir=opendir( OS_STR(path) ) ){
				while( dirent *ent=readdir( dir ) ){
					String f=ent->d_name;
					if( f=="." || f==".." ) continue;
					files.push_back( f );
				}
				closedir( dir );
			}else{
		//		printf( "opendir for LoadDir(%s) failed\n",C_STR(path) );
				fflush( stdout );
			}
	
		#endif
	
			return files.size() ? Array<String>( &files[0],files.size() ) : Array<String>();
		};
			
		static int CopyFile( String srcpath,String dstpath ){
	
		#if _WIN32
	
			if( CopyFileW( OS_STR(srcpath),OS_STR(dstpath),FALSE ) ) return 1;
			return 0;
	
		#elif __APPLE__
	
			// Would like to use COPY_ALL here, but it breaks trans on MacOS - produces weird 'pch out of date' error with copied projects.
			//
			// Ranlib strikes back!
			//
			// DAWLANE - Added file attributes COPYFILE_XATTR | COPYFILE_STAT (NEEDS CONFIRMING)
			if( copyfile( OS_STR(srcpath),OS_STR(dstpath),0,COPYFILE_XATTR | COPYFILE_STAT | COPYFILE_DATA )>=0 ) return 1;
			return 0;
	
		#else
	
			int err=-1;
			if( FILE *srcp=_fopen( OS_STR( srcpath ),OS_STR( "rb" ) ) ){
				err=-2;
				if( FILE *dstp=_fopen( OS_STR( dstpath ),OS_STR( "wb" ) ) ){
					err=0;
					char buf[1024];
					while( int n=fread( buf,1,1024,srcp ) ){
						if( fwrite( buf,1,n,dstp )!=n ){
							err=-3;
							break;
						}
					}
					fclose( dstp );
				
					// DAWLANE - Copy over the file attributes.
					struct stat st;
					stat( OS_STR( srcpath ), &st );
					chmod( OS_STR( dstpath ), st.st_mode );
				}else{
		//            printf( "FOPEN 'wb' for CopyFile(%s,%s) failed\n",C_STR(srcpath),C_STR(dstpath) );
					fflush( stdout );
				}
				fclose( srcp );
			}else{
		//        printf( "FOPEN 'rb' for CopyFile(%s,%s) failed\n",C_STR(srcpath),C_STR(dstpath) );
				fflush( stdout );
			}
			return err==0;
	
		#endif
		};
		
		static bool CreateFile( String path ){
			if( FILE *f=_fopen( OS_STR( path ),OS_STR( "wb" ) ) ){
				fclose( f );
				return true;
			}
			return false;
		}
	
		static int CreateDir( String path ){
			mkdir( OS_STR( path ),0777 );
			return FileType(path)==2;
		};
	
		static int DeleteDir( String path ){
			if( FileType( path ) != 2 ) return 0;
			rmdir( OS_STR(path) );
			return FileType(path)==0;
		};
	
		static int DeleteFile( String path ){
			if( FileType( path ) != 1 ) return 0;
			remove( OS_STR(path) );
			return FileType(path)==0;
		};
	};