//
//  KFHLSManifestGenerator.m
//  Kickflip
//
//  Created by Christopher Ballinger on 10/1/13.
//  Copyright (c) 2013 OpenWatch, Inc. All rights reserved.
//

#import "KFHLSManifestGenerator.h"
#import "KFLog.h"

/// Represents a segment of m3u8 list.
@interface Segment : NSObject

/// A duration of the segment.
@property (nonatomic, readonly) double duration;

/// A file name of the segment.
@property (nonatomic, readonly) NSString *fileName;

/// A sequence number of the segment.
@property (nonatomic, readonly) NSInteger sequenceNumber;

@end

@implementation Segment

/// Creates a new instance of the segment.
- (instancetype)initWithDuration:(double)duration fileName:(NSString *)fileName sequenceNumber:(NSInteger)sequenceNumber {
    self = [super init];
    if (self) {
        _duration = duration;
        _fileName = fileName;
        _sequenceNumber = sequenceNumber;
    }
    return self;
}

/// Returns string representation of the segment.
///
/// For exmaple:
/// ```
/// #EXTINF:11.2729,
/// index2.ts
/// ```
- (NSString *)stringRepresentation {
    return [NSString stringWithFormat:@"#EXTINF:%g,\n%@", self.duration, self.fileName];
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    return [self isEqualToSegment:other];
}

- (BOOL)isEqualToSegment:(Segment *)segment {
    return self.sequenceNumber == segment.sequenceNumber;
}

- (NSUInteger)hash {
    return self.sequenceNumber;
}

@end

@interface KFHLSManifestGenerator()

@property (nonatomic) NSMutableSet *segments;

@end

@implementation KFHLSManifestGenerator

- (id)initWithPlaylistType:(KFHLSManifestPlaylistType)playlistType {
    if (self = [super init]) {
        _version = 3;
        _playlistType = playlistType;
        _segments = [[NSMutableSet alloc] init];
    }
    return self;
}

- (NSString *)finalizeManifest {
    double duration = 0.0;
    NSMutableString *segmentsString = [[NSMutableString alloc] init];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"sequenceNumber" ascending:YES];
    NSArray *sortedSegments = [self.segments sortedArrayUsingDescriptors:@[sortDescriptor]];
    for (Segment *segment in sortedSegments) {
        [segmentsString appendString:[segment stringRepresentation]];
        [segmentsString appendString:@"\n"];
        duration = MAX(duration, segment.duration);
    }

    NSMutableString *manifest = [[NSMutableString alloc] initWithString:@"#EXTM3U\n"];
    [manifest appendFormat:@"#EXT-X-VERSION:%d\n", self.version];
    [manifest appendFormat:@"#EXT-X-TARGETDURATION:%d\n", (NSInteger)ceil(duration)];
    if (self.playlistType == KFHLSManifestPlaylistTypeVOD) {
        [manifest appendString:@"#EXT-X-PLAYLIST-TYPE:VOD\n"];
    } else if (self.playlistType == KFHLSManifestPlaylistTypeEvent) {
        [manifest appendString:@"#EXT-X-PLAYLIST-TYPE:EVENT\n"];
    }
    [manifest appendString:@"#EXT-X-MEDIA-SEQUENCE:0\n"];
    [manifest appendString:segmentsString];
    [manifest appendString:@"#EXT-X-ENDLIST\n"];
    return manifest;
}

- (void)appendFromLiveManifest:(NSString *)liveManifest {
    NSArray *rawLines = [liveManifest componentsSeparatedByString:@"\n"];

    NSMutableSet *newSegments = [[NSMutableSet alloc] initWithCapacity:10];
    [rawLines enumerateObjectsUsingBlock:^(NSString *rawLine, NSUInteger i, BOOL *stop) {
        if ([rawLine hasPrefix:@"#EXTINF"]) {
            // Extract a duration of the segment, for `#EXTINF:6.903822,` it will be 6.903822.
            double duration = 0.0;
            [[self scannerWithString:rawLine] scanDouble:&duration];

            NSString *fileName = rawLines[i + 1]; // the file name is always after #EXTINF tag.

            // Extract a sequence number of the segment, for `index1.ts` it will be 1.
            NSInteger sequenceNumber = 0;
            [[self scannerWithString:fileName] scanInteger:&sequenceNumber];

            [newSegments addObject:[[Segment alloc] initWithDuration:duration fileName:fileName sequenceNumber:sequenceNumber]];
        }
    }];

    [self.segments unionSet:newSegments];
}

/// Returns a scanner that can extract only numbers.
- (NSScanner *)scannerWithString:(NSString *)string {
    NSScanner *scanner = [[NSScanner alloc] initWithString:string];
    scanner.charactersToBeSkipped = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    return scanner;
}

@end
