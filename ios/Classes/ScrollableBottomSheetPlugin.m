#import "ScrollableBottomSheetPlugin.h"
#import <scrollable_bottom_sheet/scrollable_bottom_sheet-Swift.h>

@implementation ScrollableBottomSheetPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftScrollableBottomSheetPlugin registerWithRegistrar:registrar];
}
@end
