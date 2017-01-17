//
//  KFAWSCredentialsProvider.m
//  Pods
//
//  Created by Christopher Ballinger on 5/11/15.
//
//

#import "KFAWSCredentialsProvider.h"
#import <AWSCore/AWSCore.h>

@implementation KFAWSCredentialsProvider

- (instancetype)initWithStream:(KFS3Stream*)stream {
    if (self = [super init]) {
        _accessKey = stream.awsAccessKey;
        _secretKey = stream.awsSecretKey;
        _sessionKey = stream.awsSessionToken;
        _expiration = stream.awsExpirationDate;
    }
    return self;
}

- (AWSTask<AWSCredentials *> *)credentials {
    AWSCredentials *credentials = [[AWSCredentials alloc] initWithAccessKey:self.accessKey
                                                                  secretKey:self.secretKey
                                                                 sessionKey:self.sessionKey
                                                                 expiration:self.expiration];
    return [AWSTask taskWithResult:credentials];
}

- (void)invalidateCachedTemporaryCredentials {
    // It's not clear for now how to proceed here. Do nothing.
}

/** Utility to convert from "us-west-1" to enum AWSRegionUSWest1 */
+ (AWSRegionType) regionTypeForRegion:(NSString*)region {
    AWSRegionType regionType = AWSRegionUnknown;
    if ([region isEqualToString:@"us-east-1"]) {
        regionType = AWSRegionUSEast1;
    } else if ([region isEqualToString:@"us-west-1"]) {
        regionType = AWSRegionUSWest1;
    } else if ([region isEqualToString:@"us-west-2"]) {
        regionType = AWSRegionUSWest2;
    } else if ([region isEqualToString:@"eu-west-1"]) {
        regionType = AWSRegionEUWest1;
    } else if ([region isEqualToString:@"us-central-1"]) {
        regionType = AWSRegionEUCentral1;
    } else if ([region isEqualToString:@"ap-southeast-1"]) {
        regionType = AWSRegionAPSoutheast1;
    } else if ([region isEqualToString:@"ap-southeast-2"]) {
        regionType = AWSRegionAPSoutheast2;
    } else if ([region isEqualToString:@"ap-northeast-1"]) {
        regionType = AWSRegionAPNortheast1;
    } else if ([region isEqualToString:@"sa-east-1"]) {
        regionType = AWSRegionSAEast1;
    } else if ([region isEqualToString:@"cn-north-1"]) {
        regionType = AWSRegionCNNorth1;
    }
    return regionType;
}

@end
