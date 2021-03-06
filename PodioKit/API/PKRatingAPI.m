//
//  PKRatingAPI.m
//  PodioKit
//
//  Created by Sebastian Rehnby on 7/31/11.
//  Copyright (c) 2012 Citrix Systems, Inc. All rights reserved.
//

#import "PKRatingAPI.h"

@implementation PKRatingAPI

+ (PKRequest *)requestForLikeWithReferenceId:(NSUInteger)referenceId referenceType:(PKReferenceType)referenceType {
	NSString * uri = [NSString stringWithFormat:@"/rating/%@/%ld/like", [PKConstants stringForReferenceType:referenceType], (unsigned long)referenceId];
  PKRequest *request = [PKRequest requestWithURI:uri method:PKRequestMethodPOST objectMapping:nil];
	request.body = @{@"value": @1};
  
  return request;
}

+ (PKRequest *)requestForUnlikeWithReferenceId:(NSUInteger)referenceId referenceType:(PKReferenceType)referenceType {
	NSString *uri = [NSString stringWithFormat:@"/rating/%@/%ld/like", [PKConstants stringForReferenceType:referenceType], (unsigned long)referenceId];
  PKRequest *request = [PKRequest requestWithURI:uri method:PKRequestMethodDELETE objectMapping:nil];
  
  return request;
}

+ (PKRequest *)requestForLikedByProfilesWithReferenceId:(NSUInteger)referenceId referenceType:(PKReferenceType)referenceType limit:(NSUInteger)limit {
  NSString *uri = [NSString stringWithFormat:@"/rating/%@/%ld/liked_by/", [PKConstants stringForReferenceType:referenceType], (unsigned long)referenceId];
  PKRequest *request = [PKRequest requestWithURI:uri method:PKRequestMethodGET objectMapping:nil];

  if (limit > 0) {
    [request.parameters setObject:[NSString stringWithFormat:@"%ld", (unsigned long)limit] forKey:@"limit"];
  }

  return request;
}

@end
