#import "AudiotaggerPlugin.h"
#import <audiotagger/audiotagger-Swift.h>

@implementation AudiotaggerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftAudiotaggerPlugin registerWithRegistrar:registrar];
}
@end
