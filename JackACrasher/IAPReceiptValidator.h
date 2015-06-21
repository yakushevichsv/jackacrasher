//
//  IAReceiptValidator.m
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 6/21/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

#import <Foundation/Foundation.h>

@import StoreKit;
@import UIKit;

@interface IAPReceiptValidator : NSObject<SKRequestDelegate>

- (void)checkReceiptWithCompletionHandler:(void (^)(NSArray *array,NSError *error))handler;

@end