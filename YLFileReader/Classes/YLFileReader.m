//
//  YLFileReader.m
//  YLFileReader
//
//  Created by Hatta Yasuhiro on 2014/11/20.
//  Copyright (c) 2014年 yaslab. All rights reserved.
//

#import "YLFileReader.h"

#define kDefaultBufferSize 128

#define kLineBreakCodeLF 0x0a //'\n'
#define kLineBreakCodeCR 0x0d //'\r'

@interface YLFileReader () {
    FILE *_stream;
    NSStringEncoding _encoding;
    NSInteger _bufferSize;
    uint8_t *_buffer;
    NSInteger _offset;
    NSInteger _charWidth;
    size_t _readCount;
    BOOL _isReadEnd;
    NSMutableData *_data;
}
@end

@implementation YLFileReader

- (instancetype)initWithFilePath:(NSString *)path
{
    return [self initWithFilePath:path encoding:NSUTF8StringEncoding bufferSize:kDefaultBufferSize error:nil];
}

- (instancetype)initWithFilePath:(NSString *)path encoding:(NSStringEncoding)encoding
{
    return [self initWithFilePath:path encoding:encoding bufferSize:kDefaultBufferSize error:nil];
}

- (instancetype)initWithFilePath:(NSString *)path encoding:(NSStringEncoding)encoding bufferSize:(NSInteger)size
{
    return [self initWithFilePath:path encoding:encoding bufferSize:size error:nil];
}

- (instancetype)initWithFilePath:(NSString *)path encoding:(NSStringEncoding)encoding bufferSize:(NSInteger)size error:(NSError *__autoreleasing *)error
{
    self = [super init];
    if (self) {
        _lastError = nil;
        if (size <= 0) {
            if (error) { *error = [NSError errorWithDomain:YLFileReaderErrorDomain code:YLFileReaderErrorCodeBufferSizeZeroOrNegative userInfo:nil]; }
            return nil;
        }
        else if (size < 8) {
            size = 8;
        }
        _stream = fopen(path.UTF8String, "r");
        if (_stream == NULL) {
            if (error) { *error = [NSError errorWithDomain:YLFileReaderErrorDomain code:YLFileReaderErrorCodeFailedToOpenFile userInfo:nil]; }
            return nil;
        }
        _encoding = encoding;
        _bufferSize = size + (4 - (size % 4));
        _buffer = (uint8_t *)malloc(sizeof(uint8_t) * _bufferSize);
        if (_buffer == NULL) {
            fclose(_stream);
            _stream = NULL;
            if (error) { *error = [NSError errorWithDomain:YLFileReaderErrorDomain code:YLFileReaderErrorCodeFailedToMemoryAllocation userInfo:nil]; }
            return nil;
        }
        _offset = 0;
        _charWidth = sizeof(uint8_t);
        _readCount = 0;
        _isReadEnd = NO;
        _data = [NSMutableData new];

        // check Unicode BOM and set width
        switch (encoding) {
            case NSUTF16StringEncoding: { //==NSUnicodeStringEncoding
                uint8_t bom[2];
                size_t count = fread(bom, sizeof(uint8_t), 2, _stream);
                if (ferror(_stream)) {
                    [self close];
                    if (error) { *error = [NSError errorWithDomain:YLFileReaderErrorDomain code:YLFileReaderErrorCodeFailedToReadFile userInfo:nil]; }
                    return nil;
                }
                if (count == 2) {
                    if (bom[0] == 0xfe && bom[1] == 0xff) {
                        _encoding = NSUTF16BigEndianStringEncoding;
                    }
                    else if (bom[0] == 0xff && bom[1] == 0xfe) {
                        _encoding = NSUTF16LittleEndianStringEncoding;
                    }
                    else {
                        _encoding = NSUTF16BigEndianStringEncoding;
                        fseek(_stream, 0L, SEEK_SET);
                    }
                }
                else {
                    _encoding = NSUTF16BigEndianStringEncoding;
                    fseek(_stream, 0L, SEEK_SET);
                }
            }
            case NSUTF16BigEndianStringEncoding:
            case NSUTF16LittleEndianStringEncoding: {
                _charWidth = sizeof(uint16_t);
                break;
            }
            case NSUTF32StringEncoding: {
                uint8_t bom[4];
                size_t count = fread(bom, sizeof(uint8_t), 4, _stream);
                if (ferror(_stream)) {
                    [self close];
                    if (error) { *error = [NSError errorWithDomain:YLFileReaderErrorDomain code:YLFileReaderErrorCodeFailedToReadFile userInfo:nil]; }
                    return nil;
                }
                if (count == 4) {
                    if (bom[0] == 0x00 && bom[1] == 0x00 && bom[2] == 0xfe && bom[3] == 0xff) {
                        _encoding = NSUTF32BigEndianStringEncoding;
                    }
                    else if (bom[0] == 0xff && bom[1] == 0xfe && bom[2] == 0x00 && bom[3] == 0x00) {
                        _encoding = NSUTF32LittleEndianStringEncoding;
                    }
                    else {
                        _encoding = NSUTF32BigEndianStringEncoding;
                        fseek(_stream, 0L, SEEK_SET);
                    }
                }
                else {
                    _encoding = NSUTF32BigEndianStringEncoding;
                    fseek(_stream, 0L, SEEK_SET);
                }
            }
            case NSUTF32BigEndianStringEncoding:
            case NSUTF32LittleEndianStringEncoding: {
                _charWidth = sizeof(uint32_t);
                break;
            }
            default:
                break;
        }
    }
    return self;
}

- (void)dealloc
{
    [self close];
}

- (void)close
{
    if (_stream != NULL) {
        fclose(_stream);
        _stream = NULL;
    }
    if (_buffer != NULL) {
        free(_buffer);
        _buffer = NULL;
    }
    _isReadEnd = YES;
}

- (NSString *)readLine
{
    if (_isReadEnd) {
        _lastError = [NSError errorWithDomain:YLFileReaderErrorDomain code:YLFileReaderErrorCodeEOF userInfo:nil];
        return nil;
    }
    _data.length = 0;
    NSInteger start = _offset;
    NSInteger length = 0;
    BOOL hasCR = NO;
    while (YES) {
        if (_offset >= _readCount) {
            if (length > 0) {
                [_data appendBytes:(_buffer + start) length:(_charWidth * length)];
            }
            _offset = 0;
            start = 0;
            length = 0;
            _readCount = fread(_buffer, sizeof(uint8_t), _bufferSize, _stream);
            if (_readCount == 0) {
                _isReadEnd = YES;
                if (_data.length == 0) { return nil; }
                else { break; }
            }
        }

        uint32_t c = 0;
        switch (_encoding) {
            case NSUTF16StringEncoding:
            case NSUTF16BigEndianStringEncoding:
                c = OSReadBigInt16(_buffer, _offset);
                break;
            case NSUTF16LittleEndianStringEncoding:
                c = OSReadLittleInt16(_buffer, _offset);
                break;
            case NSUTF32StringEncoding:
            case NSUTF32BigEndianStringEncoding:
                c = OSReadBigInt32(_buffer, _offset);
                break;
            case NSUTF32LittleEndianStringEncoding:
                c = OSReadLittleInt32(_buffer, _offset);
                break;
            default:
                c = *(_buffer + _offset);
                break;
        }

        if (c == kLineBreakCodeLF) {
            // 1行取得完了('\n' or '\r''\n')
            _offset += _charWidth;
            break;
        }
        else if (hasCR) {
            // 1つ前が'\r'で、今回が'\n'でない場合、オフセットは加算しない
            // 1行取得完了('\r')
            break;
        }
        if (c == kLineBreakCodeCR) {
            // 次に'\n'が来るかもしれないので、フラグを立てておく
            hasCR = YES;
            // 次が'\n'かどうかを確認するためにコンティニュー
            _offset += _charWidth;
            continue;
        }

        _offset += _charWidth;
        length++;
    }
    if (length > 0) {
        [_data appendBytes:(_buffer + start) length:(_charWidth * length)];
    }

    NSString *line = [[NSString alloc] initWithData:_data encoding:_encoding];
    if (line == nil) {
        _lastError = [NSError errorWithDomain:YLFileReaderErrorDomain code:YLFileReaderErrorCodeFailedToParse userInfo:nil];
    }
    return line;
}

@end
