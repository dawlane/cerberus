//
//  Mac OSX Cerberus Launcher v0.1
//

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

#define APP_BUNDLE_ID "com.krautapps.Ted"

void outlist(NSMutableArray *array){
    for(int i = 1;i<array.count-1;i++){
        NSLog(@"%@", [array objectAtIndex:i]);
    }
}

int main(int argc, const char * argv[]) {
    NSMutableArray *files = [[NSMutableArray alloc] initWithCapacity:0];
    
    for(int i = 0;i<argc;i++){
        NSString *str = [NSString stringWithUTF8String:argv[i]];
        [files addObject:[NSURL URLWithString:str]];
    }
    
    if(![[NSWorkspace sharedWorkspace] openURLs:files
                        withAppBundleIdentifier:@APP_BUNDLE_ID
                                        options:NSWorkspaceLaunchDefault
                 additionalEventParamDescriptor:nil
                              launchIdentifiers:nil])
    {
        
        NSLog(@"ERROR");
        outlist(files);
    } else {
        NSLog(@"%@", [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@APP_BUNDLE_ID]);
        outlist(files);
    }
    return 0;
}