//
//  KFH264Encoder.m
//  Kickflip
//
//  Created by Christopher Ballinger on 2/11/14.
//  Copyright (c) 2014 Kickflip. All rights reserved.
//

#import "KFH264Encoder.h"
#import "AVEncoder.h"
#import "NALUnit.h"


@interface KFH264Encoder()
@property (nonatomic, strong) AVEncoder* encoder;
@property (nonatomic, strong) NSData *naluStartCode;
@property (nonatomic, strong) NSMutableData *videoSPSandPPS;
@property (nonatomic) CMTimeScale timescale;
@end

@implementation KFH264Encoder

- (void) dealloc {
    [_encoder shutdown];
}

- (id) initWithWidth:(int)width height:(int)height {
    if (self = [super init]) {
        [self initializeNALUnitStartCode];
        _timescale = 0;
        _encoder = [AVEncoder encoderForHeight:height andWidth:width];
        [_encoder encodeWithBlock:^int(NSArray* dataArray, CMTimeValue ptsValue) {
            [self writeVideoFrames:dataArray ptsValue:ptsValue];
            return 0;
        } onParams:^int(NSData *data) {
            return 0;
        }];
    }
    return self;
}

- (void) initializeNALUnitStartCode {
    NSUInteger naluLength = 4;
    uint8_t *nalu = (uint8_t*)malloc(naluLength * sizeof(uint8_t));
    nalu[0] = 0x00;
    nalu[1] = 0x00;
    nalu[2] = 0x00;
    nalu[3] = 0x01;
    _naluStartCode = [NSData dataWithBytesNoCopy:nalu length:naluLength freeWhenDone:YES];
}

- (void) encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (!_timescale) {
        CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        _timescale = pts.timescale;
    }
    [_encoder encodeFrame:sampleBuffer];
}

- (void) writeVideoFrames:(NSArray*)frames ptsValue:(CMTimeValue)ptsValue {
    CMTime presentationTimeStamp = CMTimeMake(ptsValue, _timescale);
    //NSLog(@"pts: %f", pts);
    if (ptsValue == 0) {
        NSLog(@"PTS of 0, skipping frame: %@", frames);
        return;
    }
    if (!_videoSPSandPPS) {
        NSData* config = _encoder.getConfigData;
        
        avcCHeader avcC((const BYTE*)[config bytes], [config length]);
        SeqParamSet seqParams;
        seqParams.Parse(avcC.sps());
        
        NSData* spsData = [NSData dataWithBytes:avcC.sps()->Start() length:avcC.sps()->Length()];
        NSData *ppsData = [NSData dataWithBytes:avcC.pps()->Start() length:avcC.pps()->Length()];
        
        _videoSPSandPPS = [NSMutableData dataWithCapacity:avcC.sps()->Length() + avcC.pps()->Length() + _naluStartCode.length * 2];
        [_videoSPSandPPS appendData:_naluStartCode];
        [_videoSPSandPPS appendData:spsData];
        [_videoSPSandPPS appendData:_naluStartCode];
        [_videoSPSandPPS appendData:ppsData];
    }
    
    for (NSData *data in frames) {
        unsigned char* pNal = (unsigned char*)[data bytes];
        //int idc = pNal[0] & 0x60;
        int naltype = pNal[0] & 0x1f;
        NSData *videoData = nil;
        if (naltype == 5) { // IDR
            NSMutableData *IDRData = [NSMutableData dataWithData:_videoSPSandPPS];
            [IDRData appendData:_naluStartCode];
            [IDRData appendData:data];
            videoData = IDRData;
        } else {
            NSMutableData *regularData = [NSMutableData dataWithData:_naluStartCode];
            [regularData appendData:data];
            videoData = regularData;
        }
        //NSMutableData *nalu = [[NSMutableData alloc] initWithData:_naluStartCode];
        //[nalu appendData:data];
        //NSLog(@"%f: %@", pts, videoData.description);
        if (self.delegate) {
            dispatch_async(self.callbackQueue, ^{
                [self.delegate encoder:self encodedData:videoData pts:presentationTimeStamp];
            });
        }
    }
}


@end