//
//  NSObject+Helper.h
//  Untitled
//
//  Created by Charlie Williams on 20/01/2014.
//  Copyright (c) 2014 Kudan. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef DEBUG
#   define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define DLog(...)
#endif

@interface NSObject (Helper)

- (BOOL)isPad;
- (BOOL)is4inch;
- (BOOL)isRetina;
- (NSUserDefaults *)store;
- (NSURL *)applicationDocumentsDirectoryURL;
- (NSString *)documentsDirectory;
- (NSFileManager *)fileManager;
- (NSString *)localeString;
- (NSString *)deviceString;
- (void)saveData:(NSData *)data atPath:(NSString *)path;
- (NSString *)timeFormatStringForSeconds:(NSInteger)seconds;
- (NSString *)timeFormatStringForSeconds:(NSInteger)seconds roundedTo:(NSUInteger)rounder;
- (NSString *)timeFormatStringForSeconds:(NSInteger)seconds lineBreak:(BOOL)lineBreak;
- (NSString *)timeFormatStringForSecondsRounded:(NSInteger)seconds;

@end
