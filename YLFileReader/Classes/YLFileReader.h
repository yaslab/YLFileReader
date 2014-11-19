//
//  YLFileReader.h
//  YLFileReader
//
//  Created by Hatta Yasuhiro on 2014/11/20.
//  Copyright (c) 2014年 yaslab. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString * const YLFileReaderErrorDomain = @"YLFileReaderErrorDomain";

typedef NS_ENUM(NSUInteger, YLFileReaderErrorCode) {
    YLFileReaderErrorCodeBufferSizeZeroOrNegative = 1,
    YLFileReaderErrorCodeFailedToMemoryAllocation,
    YLFileReaderErrorCodeFailedToOpenFile,
    YLFileReaderErrorCodeFailedToReadFile,
    YLFileReaderErrorCodeFailedToParse,
    YLFileReaderErrorCodeEOF,
};

@interface YLFileReader : NSObject

- (instancetype)initWithFilePath:(NSString *)path;
- (instancetype)initWithFilePath:(NSString *)path encoding:(NSStringEncoding)encoding;
- (instancetype)initWithFilePath:(NSString *)path encoding:(NSStringEncoding)encoding bufferSize:(NSInteger)size;
- (instancetype)initWithFilePath:(NSString *)path encoding:(NSStringEncoding)encoding bufferSize:(NSInteger)size error:(NSError *__autoreleasing *)error;

- (NSString *)readLine;

- (void)close;

@property (nonatomic, readonly) NSError *lastError;

@end
