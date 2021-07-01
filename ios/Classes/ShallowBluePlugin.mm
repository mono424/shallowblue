#import "ShallowBluePlugin.h"
#import "ffi.h"

@implementation ShallowBluePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  if (registrar == NULL) {
    // avoid dead code stripping
    shallowBlue_init();
    shallowBlue_main();
    shallowBlue_stdin_write(NULL);
    shallowBlue_stdout_read();
  }
}

@end
