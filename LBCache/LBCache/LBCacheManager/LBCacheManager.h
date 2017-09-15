//
//  LBCacheManager.h
//  LBCache
//
//  Created by LB on 2017/9/15.
//  Copyright © 2017年 LB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LBCacheManager : NSObject

// 默认缓存过期时间无限,可设置默认缓存时长（秒）
@property (nonatomic, assign) NSTimeInterval cacheTime;

// 内存中最大保存个数，默认为5
@property (nonatomic, assign) NSInteger cacheLimit;

//单例
+ (LBCacheManager *)sharedManager;

//获取所有的key
- (NSArray *)allKeys;

//判断key是否在缓存中
- (BOOL)hasCahceForKey:(NSString *)key;

//缓存的数量
- (NSUInteger)getAllCacheCount;

//缓存的总大小
- (unsigned long long) getAllCacheSize;

//某个缓存的大小
- (unsigned long long) getSingleCacheSizeForKey:(NSString *)key;

//清除所有缓存
- (void)clearAllCache;

//清除内存中的缓存
- (void)clearMemoryCache;

//清除某个缓存
- (void)removeCacheForKey:(NSString *)key complete:(void(^)())complete;

/////////////////////图片缓存/////////////////////////////////

//根据key获得缓存图片
- (UIImage *)readImageObjectForKey:(NSString *)key;

//根据key缓存图片
- (void)setImage:(UIImage *)image forKey:(NSString *)key;

//根据key和时间缓存图片
- (void)setImage:(UIImage *)image forKey:(NSString *)key withTimeInterval:(NSTimeInterval)timeoutInterval;

///////////////////数据模型缓存(模型需要遵守NSCoding协议)/////////////////////////////////

//根据key获得缓存数据
- (id)readObjectForkey:(NSString *)key;

//根据key缓存数据
- (void)setObectValue:(id)value forKey:(NSString *)key;

//根据key和时间缓存数据
- (void)setObectValue:(id)value forKey:(NSString *)key withTimeInterval:(NSTimeInterval)timeoutInterval;

@end

@interface NSObject (NSCode)

@end



