#import "ReceiveSharingIntentPlugin.h"
#import <receive_sharing_intent/receive_sharing_intent-Swift.h>

@implementation ReceiveSharingIntentPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftReceiveSharingIntentPlugin registerWithRegistrar:registrar];
}
@end
