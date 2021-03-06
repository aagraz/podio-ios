//
//  PKAppFieldDataFactory.m
//  PodioKit
//
//  Created by Sebastian Rehnby on 4/11/12.
//  Copyright (c) 2012 Citrix Systems, Inc. All rights reserved.
//

#import "PKAppFieldDataFactory.h"
#import "PKAppFieldOptionsData.h"
#import "PKItemFieldValueOptionData.h"
#import "PKAppFieldMoneyData.h"
#import "PKAppFieldContactData.h"
#import "NSDictionary+PKAdditions.h"

@implementation PKAppFieldDataFactory

+ (id)dataFromDictionary:(NSDictionary *)dict type:(PKAppFieldType)type {
  id data = nil;
  
  NSDictionary *configDict = [dict pk_objectForKey:@"config"];
  
  switch (type) {
    case PKAppFieldTypeCategory:
    case PKAppFieldTypeQuestion: {
      PKAppFieldOptionsData *optionsData = [PKAppFieldOptionsData data];
      NSDictionary *settingsDict = [configDict pk_objectForKey:@"settings"];
      
      optionsData.multiple = [[settingsDict pk_objectForKey:@"multiple"] boolValue];
      
      NSMutableArray *options = [[NSMutableArray alloc] init];
      for (NSDictionary *optionsDict in [settingsDict pk_objectForKey:@"options"]) {
        if ([[optionsDict pk_objectForKey:@"status"] isEqualToString:@"active"]) {
          // Add active options
          PKItemFieldValueOptionData *option = [PKItemFieldValueOptionData dataFromDictionary:optionsDict];
          [options addObject:option];
        }
      }
      
      optionsData.options = options;
      
      data = optionsData;
      break;
    }
    case PKAppFieldTypeState: {
      PKAppFieldOptionsData *optionsData = [PKAppFieldOptionsData data];
      optionsData.multiple = NO; // State is single select only
      
      NSArray *allowedValues = [[configDict pk_objectForKey:@"settings"] pk_objectForKey:@"allowed_values"];
      
      NSMutableArray *options = [[NSMutableArray alloc] init];
      [allowedValues enumerateObjectsUsingBlock:^(id allowedValue, NSUInteger idx, BOOL *stop) {
        if ([allowedValue isKindOfClass:[NSString class]] && [allowedValue length] > 0) { // Old statefieds might contain blank fields
          PKItemFieldValueOptionData *option = [PKItemFieldValueOptionData data];
          option.optionId = -1; // Use index as id
          option.text = allowedValue;
          [options addObject:option];
        }
      }];
      
      optionsData.options = options;
      
      data = optionsData;
      break;
    }
    case PKAppFieldTypeMoney: {
      PKAppFieldMoneyData *moneyData = [PKAppFieldMoneyData data];
      moneyData.allowedCurrencies = [[configDict pk_objectForKey:@"settings"] pk_objectForKey:@"allowed_currencies"];
      data = moneyData;
      break;
    }
    case PKAppFieldTypeContact: {
      PKAppFieldContactData *contactData = [PKAppFieldContactData data];
      contactData.validTypes = [[configDict pk_objectForKey:@"settings"] pk_objectForKey:@"valid_types"];
      data = contactData;
      break;
    }
    default:
      break;
  }
  
  return data;
}

@end
