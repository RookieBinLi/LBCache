//
//  LBCacheManager.m
//  LBCache
//
//  Created by LB on 2017/9/15.
//  Copyright © 2017年 LB. All rights reserved.
//

#import "LBCacheManager.h"
#import <objc/runtime.h>

static NSString *const kPlistName = @"Cache.plist";

@interface LBCacheManager ()

@property (strong, nonatomic) NSMutableDictionary *cachePlistDic;

@property (strong, nonatomic) dispatch_queue_t cacheDispatch;

@property (strong, nonatomic) NSCache *memoryCahce;

@end


@implementation LBCacheManager

#pragma mark - initMethod(初始化中方法)
//MARK - 创建文件

- (void)creatFileManager{
    
    // 默认路径
    NSString *defaulPath = [self defaulPath];
    
    //1 文件单利
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    //2 判断是否存在文件
    if ([fileManager fileExistsAtPath:defaulPath]) {
        NSMutableDictionary *removeKeys = [[NSMutableDictionary alloc]init];
        //timeIntervalSinceReferenceDate/以2001/01/01 GMT为基准时间，返回实例保存的时间与2001/01/01 GMT的时间间隔
        NSTimeInterval now = [[NSDate date] timeIntervalSinceReferenceDate];
        
        dispatch_sync(_cacheDispatch, ^{
            
            BOOL isChange = NO;
            
            //遍历字典 查看是否存在文件
            for (NSString *key in _cachePlistDic.allKeys) {
                
                //先删除后添加
                if ([_cachePlistDic[key] isKindOfClass:[NSData class]]) {
                    if ([_cachePlistDic[key] timeIntervalSinceReferenceDate] <= now) {
                        isChange = YES;
                        [fileManager removeItemAtPath:[self cachePathForKey:key] error:nil];
                        [removeKeys removeObjectForKey:key];
                    }
                }
            }
            
            //删除后写入文件
            if (isChange) {
                _cachePlistDic = removeKeys;
                [_cachePlistDic writeToFile:[self cachePathForKey:kPlistName] atomically:YES];
            }
        });
        
    }else{
        
        //没有文件的话先去创建文件
        [fileManager createDirectoryAtPath:defaulPath withIntermediateDirectories:YES attributes:nil error:nil];
        
    }
}

//MARK - 添加内存警告通知
- (void)addNotification{
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(clearMemoryCache) name:UIApplicationDidReceiveMemoryWarningNotification  object:nil];
}

//MARK - 移除通知
- (void)removeNotification{
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

//MARK- 默认路径
- (NSString *)defaulPath{
    
    NSString *cachesDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    
    NSString *defaulPath = [[[cachesDirectory stringByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]]stringByAppendingPathComponent:@"LBCache"] copy];
    
    return  defaulPath;
}

//MARK -缓存路径
- (NSString *)cachePathForKey:(NSString *)key{
    return [[self defaulPath] stringByAppendingPathComponent:key].copy;
}


+ (LBCacheManager *)sharedManager {
    
    static dispatch_once_t onceToken;
    static LBCacheManager * manager = nil;
    dispatch_once(&onceToken, ^{
        if (manager == nil ) {
            manager = [[LBCacheManager alloc]init];
        }
    });
    
    return manager;
}

- (instancetype)init{
    
    if (self = [super init]) {
        
        //1. 创建线程并交换线程级别
        _cacheDispatch = dispatch_queue_create("lbCacheDisptch", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_t tempPatch = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        dispatch_set_target_queue(tempPatch, _cacheDispatch); //交换线程级别
        
        //2 默认数据
        _cacheTime = 0 ;
        _cacheLimit = 5;
        
        //3 添加通知
        [self addNotification];
        
        //4 内存缓存初始化
        _memoryCahce = [[NSCache alloc]init];
        _memoryCahce.countLimit = _cacheLimit;
        
        //5 初始化字典内存
        _cachePlistDic = [NSMutableDictionary dictionaryWithContentsOfFile:[self cachePathForKey:kPlistName]];
        if (_cachePlistDic == nil) {
            _cachePlistDic = [[NSMutableDictionary alloc]init];
        }
        
        //6 创建文件管理以及文件
        [self creatFileManager];
        
    }
    
    return self;
}

-(void)setCacheLimit:(NSInteger)cacheLimit{
    _cacheLimit = cacheLimit;
    _memoryCahce.countLimit = cacheLimit;
}

#pragma mark - allKeys(获取所有的key)
-(NSArray *)allKeys{
    
    return [_cachePlistDic allKeys];
}

#pragma mark - hasCahceForKey(判断key是否在缓存中)
- (BOOL)hasCahceForKey:(NSString *)key{
    
    __block BOOL res = NO;
    
    res = [[NSFileManager defaultManager]fileExistsAtPath:[self cachePathForKey:key]];
    
    
    return res;
}

#pragma mark - getAllCacheCount(缓存的数量)
- (NSUInteger)getAllCacheCount{
    
    return _cachePlistDic.count;
}

#pragma mark - getAllCacheSize(缓存的大小)
- (unsigned long long)getAllCacheSize{
    
    unsigned long long cacheSize = 0;
    
    for (NSString *key in [_cachePlistDic allKeys]) {
        
        NSString *cachePath = [self cachePathForKey:key];
        
        //attributesOfItemAtPath:方法的功能是获取文件的大小、文件的内容等属性
        NSDictionary *attrubis = [[NSFileManager defaultManager] attributesOfItemAtPath:cachePath error:nil];
        
        cacheSize += [attrubis fileSize];
    }
    return cacheSize;
}

#pragma mark - getSingleCacheSizeForKey(某个缓存的大小)
- (unsigned long long)getSingleCacheSizeForKey:(NSString *)key{
    
    unsigned long long cacheSize = 0;
    
    NSFileManager *manager = [NSFileManager defaultManager];
    
    if ([manager fileExistsAtPath:[self cachePathForKey:key]]) {
        cacheSize = [[manager attributesOfItemAtPath:[self cachePathForKey:key] error:nil] fileSize];
    }
    
    return cacheSize;
}

#pragma mark -clearAllCache(清除所有缓存)
- (void)clearAllCache{
    //优化运用线程，防止阻塞主线程
    dispatch_async(self.cacheDispatch, ^{
        
        for (NSString *key in _cachePlistDic.allKeys) {
            [[NSFileManager defaultManager] removeItemAtPath:[self cachePathForKey:key] error:nil];
        }
        
        [_cachePlistDic removeAllObjects];
        [_cachePlistDic writeToFile:[self cachePathForKey:kPlistName] atomically:YES];
        [self clearMemoryCache];
    });
}

#pragma mark - clearMemoryCache(清除内存中的缓存)
- (void)clearMemoryCache{
    
    [_memoryCahce removeAllObjects];
}

#pragma mark - removeCacheForKey(清除某个缓存)
- (void)removeCacheForKey:(NSString *)key complete:(void(^)())complete {
    
    NSAssert(![key isEqualToString:kPlistName], @"对不起，主plist文件不可删除");
    
    dispatch_async(self.cacheDispatch, ^{
        [[NSFileManager defaultManager]removeItemAtPath:[self cachePathForKey:key] error:nil
         ];
        
        [_cachePlistDic removeObjectForKey:key];
        [_cachePlistDic writeToFile:[self cachePathForKey:kPlistName] atomically:YES];
        [_memoryCahce removeObjectForKey:key];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (complete) {
                complete();
            }
        });
    });
}

#pragma mark - readImageObjectForKey(根据key获得缓存图片)
- (UIImage *)readImageObjectForKey:(NSString *)key{
    if (key) {
        NSData  *data= [self readObjectForkey:key];
        if (data) {
            return [UIImage imageWithData:data];
        }
    }
    return nil;
}

#pragma mark - setImage:(UIImage *)image forKey:(NSString *)key(根据key缓存图片)
- (void)setImage:(UIImage *)image forKey:(NSString *)key{
    [self setImage:image forKey:key withTimeInterval:_cacheTime];
}

#pragma mark - setImage:(UIImage *)image forKey:(NSString *)key withTimeInterval:(NSTimeInterval)timeoutInterval(根据key和时间缓存图片)
- (void)setImage:(UIImage *)image forKey:(NSString *)key withTimeInterval:(NSTimeInterval)timeoutInterval{
    
    if (!key || !image) {
        return ;
    }
    
    if ([self readImageObjectForKey:key]) {
        return;
    }
    
    NSData *data = UIImagePNGRepresentation(image);
    data = data ? data : UIImageJPEGRepresentation(image, 1.0f);
    [self setObectValue:data forKey:key withTimeInterval:timeoutInterval];
}

#pragma mark - readObjectForkey(根据key缓存数据)
-(id)readObjectForkey:(NSString *)key{
    
    if (key) {
        if ([self hasCahceForKey:key]) { //判断是否存在
            NSFileManager *fileManager = [NSFileManager defaultManager];
            
            if ([_cachePlistDic[key] isKindOfClass:[NSData class]]) {
                
                NSTimeInterval now = [[NSDate date] timeIntervalSinceReferenceDate];
                if ([_cachePlistDic[key] timeIntervalSinceReferenceDate] <= now) {
                    dispatch_async(self.cacheDispatch, ^{
                        [fileManager removeItemAtPath:[self cachePathForKey:key] error:nil];
                        [_cachePlistDic writeToFile:[self cachePathForKey:key] atomically:YES];
                        [_memoryCahce removeObjectForKey:key];
                        
                    });
                    
                    return nil;
                }
            }
            
            if ([self.memoryCahce objectForKey:key]) {
                return [self.memoryCahce objectForKey:key];
            }
            
            NSData *data = [NSData dataWithContentsOfFile:[self cachePathForKey:key]];
            if (data) {
                return [NSKeyedUnarchiver unarchiveObjectWithData:data];
            }
            
        }
    }
    
    return nil;
}

#pragma mark - setObectValue(根据key缓存数据)
- (void)setObectValue:(id)value forKey:(NSString *)key{
    
    [self setObectValue:value forKey:key withTimeInterval:_cacheTime];
}

#pragma mark -setObectValue:(id)value forKey:(NSString *)key withTimeInterval(根据key和时间缓存数据)
- (void)setObectValue:(id)value forKey:(NSString *)key withTimeInterval:(NSTimeInterval)timeoutInterval{
    
    if (!key || !value) { //没有key和Value返回
        return ;
    }

    //内存添加缓存
    [self.memoryCahce setObject:value forKey:key];
    
    [self setDataValue:[NSKeyedArchiver archivedDataWithRootObject:value] forKey:key withTimeInterVal:timeoutInterval];
}

- (void)setDataValue:(NSData *)value forKey:(NSString *)key withTimeInterVal:(NSTimeInterval )timeoutInterval{
    
    
    NSAssert(![key isEqualToString:kPlistName] , @"不能保存或修改默认的plist");
    
    dispatch_async(self.cacheDispatch, ^{
        
        NSLog(@"key ==%@",key);
        [value writeToFile:[self cachePathForKey:key] atomically:YES];
        //[NSDate distantFuture] 返回很长时间的时间值(永久)
        id obj  = timeoutInterval > 0 ? [NSDate dateWithTimeIntervalSinceNow:timeoutInterval] : [NSDate distantFuture];
        [_cachePlistDic setObject:obj forKey:key];
        [_cachePlistDic writeToFile:[self cachePathForKey:kPlistName] atomically:YES];
    });
}
@end


@implementation NSObject (NSCode)

-(void)encodeWithCoder:(NSCoder *)aCoder{
    unsigned int count = 0;
    Ivar *ivarLists = class_copyIvarList([self class], &count);// 注意下面分析
    for (int i = 0; i < count; i++) {
        const char* name = ivar_getName(ivarLists[i]);
        NSString* strName = [NSString stringWithUTF8String:name];
        [aCoder encodeObject:[self valueForKey:strName] forKey:strName];
    }
    free(ivarLists);  
}


-(instancetype)initWithCoder:(NSCoder *)aDecoder {
        unsigned int count = 0;
        Ivar *ivarLists = class_copyIvarList([self class], &count);
        for (int i = 0; i < count; i++) {
            const char* name = ivar_getName(ivarLists[i]);
            NSString* strName = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
            id value = [aDecoder decodeObjectForKey:strName];
            [self setValue:value forKey:strName];
        }
    free(ivarLists);
    return self;
}



@end

