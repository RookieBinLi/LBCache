# LBCache
根据sdwebImage库的cache源码 自己根据改进封装的一个cache
LBCacheManager库把数据通过文件管理(NSFileManager)类，存放在沙盒中，并运用NSCache做磁 盘上的内存。
支持存取图片，存取数据(模型必需遵守NSCoding协议)，清除全部或者单个缓存，获得全部或者单个缓存的大小(字节数)，缓存的总个数以及可以缓存的个数时间
