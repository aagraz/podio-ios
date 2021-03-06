//
//  PKItemFieldValueMoneyData.m
//  PodioKit
//
//  Created by Sebastian Rehnby on 2011-07-07.
//  Copyright (c) 2012 Citrix Systems, Inc. All rights reserved.
//

#import "PKItemFieldValueMoneyData.h"
#import "NSNumber+PKFormat.h"

static NSString * const PKItemFieldValueMoneyDataAmountKey = @"Amount";
static NSString * const PKItemFieldValueMoneyDataCurrencyKey = @"Currency";

@implementation PKItemFieldValueMoneyData

@synthesize amount = amount_;
@synthesize currency = currency_;

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
    amount_ = [[aDecoder decodeObjectForKey:PKItemFieldValueMoneyDataAmountKey] copy];
    currency_ = [[aDecoder decodeObjectForKey:PKItemFieldValueMoneyDataCurrencyKey] copy];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:amount_ forKey:PKItemFieldValueMoneyDataAmountKey];
  [aCoder encodeObject:currency_ forKey:PKItemFieldValueMoneyDataCurrencyKey];
}


#pragma mark - Factory methods

+ (id)dataFromDictionary:(NSDictionary *)dict {
  PKItemFieldValueMoneyData *data = [self data];
  
  data.amount = [NSNumber pk_numberFromStringWithUSLocale:[dict pk_objectForKey:@"value"]];
  data.currency = [dict pk_objectForKey:@"currency"];
  
  return data;
}

@end
