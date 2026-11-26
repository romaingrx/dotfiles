// Finder hands opened files to an app as Apple Events, which a plain script
// can't receive. This stub collects them and runs `nvim` on them through
// run.applescript, which opens a new window in the terminal from lib/apps.
#import <Cocoa/Cocoa.h>

static NSString *shellQuote(NSString *s) {
  return [NSString stringWithFormat:@"'%@'", [s stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"]];
}

@interface Launcher : NSObject <NSApplicationDelegate>
@property NSMutableArray<NSString *> *paths;
@end

@implementation Launcher
- (void)application:(NSApplication *)app openURLs:(NSArray<NSURL *> *)urls {
  // The command is typed into a shell. Quoting can't neutralise control
  // characters (they act as keys), so skip any path that has one.
  NSCharacterSet *control = NSCharacterSet.controlCharacterSet;
  for (NSURL *url in urls)
    if (url.isFileURL && [url.path rangeOfCharacterFromSet:control].location == NSNotFound)
      [self.paths addObject:url.path];
}

// Files that launched the app arrive above, before this runs.
- (void)applicationDidFinishLaunching:(NSNotification *)note {
  // The leading space keeps the command out of shell history.
  NSMutableString *cmd = [NSMutableString stringWithString:@" exec nvim --"];
  for (NSString *path in self.paths) [cmd appendFormat:@" %@", shellQuote(path)];
  NSString *cwd = self.paths.count ? self.paths[0].stringByDeletingLastPathComponent : NSHomeDirectory();

  NSString *script = [NSBundle.mainBundle pathForResource:@"run" ofType:@"applescript"];
  NSTask *task = [NSTask launchedTaskWithExecutableURL:[NSURL fileURLWithPath:@"/usr/bin/osascript"]
                                             arguments:@[ script, cwd, cmd ]
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
