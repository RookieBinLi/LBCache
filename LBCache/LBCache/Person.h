//
//  Person.h
//  LBCache
//
//  Created by LB on 2017/9/15.
//  Copyright © 2017年 LB. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Person : NSObject<NSCoding>

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *grade;
@property (nonatomic, assign) int age;


@end
