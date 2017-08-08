//
//  DelegateSplitter.h
//  SofascoreApp
//
//  Created by Kristian Vukušić on 04/08/2017.
//  Copyright © 2017 SofaScore. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 The `DelegateSplitter` class is used to allow a class like UITableView to have a UITableViewDelegate
 (inherits from UIScrollViewDelegate) and a separate UIScrollViewDelegate.

 This pattern becomes necessary when a UITableView sets its delegate to an instance of `NavigationBarBehaviorDefiner`
 but also wants another class to act as the UITableViewDelegate.
 */
@interface DelegateSplitter : NSObject

@property (nonatomic, weak) id<NSObject> firstDelegate;
@property (nonatomic, weak) id<NSObject> secondDelegate;

- (instancetype)initWithFirstDelegate:(id<NSObject>)firstDelegate
                       secondDelegate:(id<NSObject>)secondDelegate;

@end
