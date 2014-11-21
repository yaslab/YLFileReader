YLFileReader
============

YLFileReader is simple file reader.

## How To Use

```objc
NSString *path = @"/path/for/file.txt";
NSStringEncoding encoding = NSShiftJISStringEncoding;
NSInteger bufferSize = 1024;
YLFileReader *reader = [[YLFileReader alloc] initWithFilePath:path encoding:encoding bufferSize: bufferSize];
NSInteger lineNo = 0;
NSString *line;
while ((line = [reader readLine]) != nil) {
    lineNo++;
    NSLog(@"%02d:(%@)", lineNo, line);
}
[reader close];
```

## License

MIT