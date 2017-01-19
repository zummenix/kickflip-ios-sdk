//
//  KFHLSManifestGenerator.h
//  Kickflip
//
//  Created by Christopher Ballinger on 10/1/13.
//  Copyright (c) 2013 OpenWatch, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, KFHLSManifestPlaylistType) {
    KFHLSManifestPlaylistTypeLive = 0,
    KFHLSManifestPlaylistTypeVOD,
    KFHLSManifestPlaylistTypeEvent
};

@interface KFHLSManifestGenerator : NSObject

@property (nonatomic, readonly) NSUInteger version;
@property (nonatomic, readonly) KFHLSManifestPlaylistType playlistType;

- (id)initWithPlaylistType:(KFHLSManifestPlaylistType)playlistType;

- (void)appendFromLiveManifest:(NSString*)liveManifest;

- (NSString *)finalizeManifest;

@end
