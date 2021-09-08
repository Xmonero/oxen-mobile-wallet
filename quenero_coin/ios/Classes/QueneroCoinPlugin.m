#import "QueneroCoinPlugin.h"
#import <quenero_coin/quenero_coin-Swift.h>
//#include "../External/android/monero/include/wallet2_api.h"

@implementation QueneroCoinPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftQueneroCoinPlugin registerWithRegistrar:registrar];
}
@end
