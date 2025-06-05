//
//  MLCBridge.h
//  Public interface for MLC-LLM Objective-C++ bridge
//

#import <Foundation/Foundation.h>

@interface JSONFFIEngine : NSObject

- (void)initBackgroundEngine:(void (^)(NSString*))streamCallback;
- (void)reload:(NSString*)engineConfig;
- (void)unload;
- (void)reset;
- (void)chatCompletion:(NSString*)requestJSON requestID:(NSString*)requestID;
- (void)abort:(NSString*)requestID;
- (void)runBackgroundLoop;
- (void)runBackgroundStreamBackLoop;
- (void)exitBackgroundLoop;

@end 