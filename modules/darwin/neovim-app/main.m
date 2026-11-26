// Finder hands opened files to an app as Apple Events, which a plain script
// can't receive. This stub collects them and passes them to open.applescript.
#import <Cocoa/Cocoa.h>

@interface Launcher : NSObject <NSApplicationDelegate>
@property NSMutableArray<NSString *> *paths;
@end

@implementation Launcher
- (void)application:(NSApplication *)app openURLs:(NSArray<NSURL *> *)urls {
  // The script types each path into a shell. Quoting can't neutralise
  // control characters (they act as keys), so skip any path that has one.
  NSCharacterSet *control = NSCharacterSet.controlCharacterSet;
  for (NSURL *url in urls)
    if (url.isFileURL && [url.path rangeOfCharacterFromSet:control].location == NSNotFound)
      [self.paths addObject:url.path];
}

// Files that launched the app arrive above, before this runs.
- (void)applicationDidFinishLaunching:(NSNotification *)note {
  NSString *script = [NSBundle.mainBundle pathForResource:@"open" ofType:@"applescript"];
  NSMutableArray *args = [NSMutableArray arrayWithObject:script];
  [args addObjectsFromArray:self.paths];
  NSTask *task = [NSTask launchedTaskWithExecutableURL:[NSURL fileURLWithPath:@"/usr/bin/osascript"]
                                             arguments:args
                                                 error:nil
                                    terminationHandler:^(NSTask *t) {
                                      dispatch_async(dispatch_get_main_queue(), ^{ [NSApp terminate:nil]; });
                                    }];
  if (!task) [NSApp terminate:nil];
}
@end

int main(void) {
  @autoreleasepool {
    Launcher *launcher = [Launcher new];
    launcher.paths = [NSMutableArray array];
    NSApplication.sharedApplication.delegate = launcher;
    [NSApp run];
  }
}
