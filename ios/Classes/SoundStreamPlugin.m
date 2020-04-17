#import "SoundStreamPlugin.h"
#if __has_include(<sound_stream/sound_stream-Swift.h>)
#import <sound_stream/sound_stream-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "sound_stream-Swift.h"
#endif

@implementation SoundStreamPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftSoundStreamPlugin registerWithRegistrar:registrar];
}
@end
