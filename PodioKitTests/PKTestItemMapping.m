//
//  PKTestItemMapping.m
//  PodioKit
//
//  Created by Sebastian Rehnby on 12/21/11.
//  Copyright (c) 2012 Citrix Systems, Inc. All rights reserved.
//

#import "PKTestItemMapping.h"
#import "PKTestItemFieldMapping.h"
#import "PKTestItemAppMapping.h"
#import "NSDictionary+PKAdditions.h"

@implementation PKTestItemMapping

+ (BOOL)shouldPerformMappingWithData:(NSDictionary *)data {
  NSNumber *itemId = [data pk_objectForKey:@"item_id"];
  return [itemId intValue] != 1111;
}

- (void)buildMappings {
  [self hasProperty:@"itemId" forAttribute:@"item_id"];
  [self hasProperty:@"title" forAttribute:@"title"];
  [self hasRelationship:@"fields" forAttribute:@"fields" inverseProperty:nil objectMapping:[PKTestItemFieldMapping mapping]];
  [self hasRelationship:@"app" forAttribute:@"app" inverseProperty:nil objectMapping:[PKTestItemAppMapping mapping]];
}

@end
