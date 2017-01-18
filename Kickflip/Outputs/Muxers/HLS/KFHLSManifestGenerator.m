//
//  KFHLSManifestGenerator.m
//  Kickflip
//
//  Created by Christopher Ballinger on 10/1/13.
//  Copyright (c) 2013 OpenWatch, Inc. All rights reserved.
//

#import "KFHLSManifestGenerator.h"
#import "KFLog.h"

@interface KFHLSManifestGenerator()
@property (nonatomic, strong) NSMutableString *segmentsString;
@property (nonatomic) BOOL finished;
@end

@implementation KFHLSManifestGenerator

- (NSMutableString*) header {
    NSMutableString *header = [NSMutableString stringWithFormat:@"#EXTM3U\n#EXT-X-VERSION:%lu\n#EXT-X-TARGETDURATION:%d\n", (unsigned long)self.version, (int)ceil(self.targetDuration)];
    NSString *type = nil;
    if (self.playlistType == KFHLSManifestPlaylistTypeVOD) {
        type = @"VOD";
    } else if (self.playlistType == KFHLSManifestPlaylistTypeEvent) {
        type = @"EVENT";
    }
    if (type) {
        [header appendFormat:@"#EXT-X-PLAYLIST-TYPE:%@\n", type];
    }
    [header appendFormat:@"#EXT-X-MEDIA-SEQUENCE:%ld\n", (long)self.mediaSequence];
    return header;
}

- (NSString*) footer {
    return @"#EXT-X-ENDLIST\n";
}

- (id) initWithTargetDuration:(float)targetDuration playlistType:(KFHLSManifestPlaylistType)playlistType {
    if (self = [super init]) {
        self.targetDuration = targetDuration;
        self.playlistType = playlistType;
        self.version = 3;
        self.mediaSequence = -1;
        self.segmentsString = [NSMutableString string];
        self.finished = NO;
    }
    return self;
}

- (void) appendFileName:(NSString *)fileName duration:(float)duration mediaSequence:(NSUInteger)mediaSequence {
    if (self.finished) {
        return;
    }
    self.mediaSequence = mediaSequence;
    if (duration > self.targetDuration) {
        self.targetDuration = duration;
    }
    [self.segmentsString appendFormat:@"#EXTINF:%g,\n%@\n", duration, fileName];
}

- (void) finalizeManifest {
    self.finished = YES;
    self.mediaSequence = 0;
}

- (NSString*) stripToNumbers:(NSString*)string {
    return [[string componentsSeparatedByCharactersInSet:
             [[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
            componentsJoinedByString:@""];
}

- (void) appendFromLiveManifest:(NSString *)liveManifest {
    NSArray *rawLines = [liveManifest componentsSeparatedByString:@"\n"];
    NSMutableArray *lines = [NSMutableArray arrayWithCapacity:rawLines.count];
    for (NSString *line in rawLines) {
        if (!line.length) {
            continue;
        }
        if ([line isEqualToString:@"#EXT-X-ENDLIST"]) {
            continue;
        }
        [lines addObject:line];
    }
    if (lines.count < 6) {
        return;
    }

    // Extract duration of the file, for `#EXTINF:6.903822,` it will be 6.903822.
    float duration = 0.0;
    NSString *extInf = lines[lines.count-2];
    [[self scannerWithString:extInf] scanFloat:&duration];

    // Extract sequence number of the file, for example for `index1.ts` it will be 1.
    NSInteger sequence = 0;
    NSString *segmentName = lines[lines.count-1];
    [[self scannerWithString:segmentName] scanInteger:&sequence];

    if (sequence > self.mediaSequence) {
        [self appendFileName:segmentName duration:duration mediaSequence:sequence];
    }
}

- (NSString*) manifestString {
    NSMutableString *manifest = [self header];
    [manifest appendString:self.segmentsString];
    if (self.finished) {
        [manifest appendString:[self footer]];
    }
    DDLogInfo(@"Latest manifest:\n%@", manifest);
    return manifest;
}

/// Returns scanner that can extract only numbers.
- (NSScanner *)scannerWithString:(NSString *)string {
    NSScanner *scanner = [[NSScanner alloc] initWithString:string];
    scanner.charactersToBeSkipped = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    return scanner;
}

@end
