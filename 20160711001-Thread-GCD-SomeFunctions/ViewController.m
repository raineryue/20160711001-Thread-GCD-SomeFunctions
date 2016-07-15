//
//  ViewController.m
//  20160711001-Thread-GCD-SomeFunctions
//
//  Created by Rainer on 16/7/11.
//  Copyright © 2016年 Rainer. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    // barrier
//    [self barrier];
    
    // 延迟
//    [self delay];
    
    // 执行一次
//    [self once];
    
    // 使用快速迭代并行拷贝文件
//    [self apply];
    
    // 使用队列组合并图片
    [self queueGroup];
}

- (void)queueGroup {
    // 1.创建两个图片对象
    __block UIImage *image1;
    __block UIImage *image2;
    
    // 2.创建一个队列组对象
    dispatch_group_t dispatchGroup = dispatch_group_create();
    // 获取一个全局的并行队列
    dispatch_queue_t dispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    // 3.异步队列组函数下载第一张图片
    dispatch_group_async(dispatchGroup, dispatchQueue, ^{
        NSURL *imageUrl = [NSURL URLWithString:@"http://pic61.nipic.com/file/20150228/7487939_190907874000_2.jpg"];
        
        image1 = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:imageUrl]];
    });

    // 4.异步队列组函数下载第二张图片
    dispatch_group_async(dispatchGroup, dispatchQueue, ^{
        NSURL *imageUrl = [NSURL URLWithString:@"http://img.tuku.cn/file_big/201505/d620f7e86cb84799aa62b8c9ef50d938.jpg"];
        
        image2 = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:imageUrl]];
    });
    
    // 5.队列组完成后掉用此通知
    dispatch_group_notify(dispatchGroup, dispatchQueue, ^{
        // 5.1.开启一个图形上下文
        UIGraphicsBeginImageContext(CGSizeMake(300, 300));
        
        // 5.2.将图片分别画入图形上下文中
        [image1 drawInRect:CGRectMake(0, 0, 150, 300)];
        [image2 drawInRect:CGRectMake(150, 0, 150, 300)];
        
        // 5.3.从图形上下文中生成一张新的图片
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        
        // 5.4.关闭图形上下文
        UIGraphicsEndImageContext();
        
        // 5.5.回到主线程中显示新的图片
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imageView.image = image;
        });
    });
}

/**
 *  快速迭代
 */
- (void)apply {
    // 1.获取全局的并行队列
    dispatch_queue_t dispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    // 基本用法
//    dispatch_apply(20, dispatchQueue, ^(size_t index) {
//        NSLog(@"%ld", index);
//    });
    
    // 使用快速迭代拷贝文件
    // 1.定义源文件和目标文件夹路径
    NSString *fromPath = @"/Users/Rainer/Downloads/from";
    NSString *toPaht = @"/Users/Rainer/Downloads/to";
    
    // 2.创建文件管理对象
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // 3.使用文件管理对象根据源文件夹路径获取里面所有文件的路径
    NSArray *filePathArray = [fileManager subpathsAtPath:fromPath];
    
    // 4.遍历所有路径并拷贝到目标文件夹中
    // 使用快速迭代做法
    dispatch_apply(filePathArray.count, dispatchQueue, ^(size_t index) {
        // 获取文件路径
        NSString *filePath = filePathArray[index];
        
        // 4.1.拼接源文件的全路径
        NSString *fromFilePath = [fromPath stringByAppendingPathComponent:filePath];
        
        // 4.2.拼接目标文件的全路径
        NSString *toFilePath = [toPaht stringByAppendingPathComponent:filePath];
        
        // 4.3.将源文件从源文件夹中移动到目标文件夹中
        [fileManager moveItemAtPath:fromFilePath toPath:toFilePath error:nil];
        
        NSLog(@"%@---------%@", [NSThread currentThread], fromPath);
    });
    
}

/**
 *  使用传统的方法拷贝文件
 */
- (void)moveFiles {
    // 1.获取全局的并行队列
    dispatch_queue_t dispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    // 1.定义源文件和目标文件夹路径
    NSString *fromPath = @"/Users/Rainer/Downloads/from";
    NSString *toPaht = @"/Users/Rainer/Downloads/to";
    
    // 2.创建文件管理对象
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // 3.使用文件管理对象根据源文件夹路径获取里面所有文件的路径
    NSArray *filePathArray = [fileManager subpathsAtPath:fromPath];
    
    // 4.遍历所有路径并拷贝到目标文件夹中
    // 传统做法
    for (NSString *filePath in filePathArray) {
        // 4.1.拼接源文件的全路径
        NSString *fromFilePath = [fromPath stringByAppendingPathComponent:filePath];
        
        // 4.2.拼接目标文件的全路径
        NSString *toFilePath = [toPaht stringByAppendingPathComponent:filePath];
        
        // 4.3.在子线程中将源文件从源文件夹中移动到目标文件夹中
        dispatch_async(dispatchQueue, ^{
            [fileManager moveItemAtPath:fromFilePath toPath:toFilePath error:nil];
            
            NSLog(@"%@---------%@", [NSThread currentThread], fromPath);
        });
    }

}

/**
 *  执行一次：在整个应用程序中之执行一次
 *  这里的只执行一次和懒加载是有区别的，不用用来代替懒加载，懒加载需要在应用程序中多次被执行，而这里不能做到
 */
- (void)once {
    static dispatch_once_t predicate;
    
    dispatch_once(&predicate, ^{
        NSLog(@"==================run once");
    });
}

/**
 *  延迟执行
 */
- (void)delay {
    NSLog(@"==================Begin:%@", [NSDate date]);
    
    // 1.方法一
//    [self performSelector:@selector(run:) withObject:@"test" afterDelay:2.0];
    
    // 2.方法二
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        NSLog(@"==================run");
//    });

    // 3.方法三
    [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(run:) userInfo:@"test" repeats:NO];
    
    NSLog(@"==================End:%@", [NSDate date]);
}

/**
 *  barrier:栅栏->用来拦截线程的，barrier前面的线程先执行完成后才能执行后面的线程
 *  注意:这里不可以使用全局的并发队列，需要自己创建队列，否则barrier无效
 */
- (void)barrier {
//    dispatch_queue_t dispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_queue_t dispatchQueue = dispatch_queue_create("com.rainer.dispatchQueue.barrier", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(dispatchQueue, ^{
        NSLog(@"========[1]=====>:{%@}", [NSThread currentThread]);
    });
    
    dispatch_async(dispatchQueue, ^{
        NSLog(@"========[2]=====>:{%@}", [NSThread currentThread]);
    });
    
    dispatch_barrier_async(dispatchQueue, ^{
        NSLog(@"========barrier=====>:{%@}", [NSThread currentThread]);
    });
    
    dispatch_async(dispatchQueue, ^{
        NSLog(@"========[3]=====>:{%@}", [NSThread currentThread]);
    });
    
    dispatch_async(dispatchQueue, ^{
        NSLog(@"========[4]=====>:{%@}", [NSThread currentThread]);
    });
}

- (void)run:(NSString *)param {
    NSLog(@"============%@======run", param);
}

@end
