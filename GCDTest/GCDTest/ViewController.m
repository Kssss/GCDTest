//
//  ViewController.m
//  GCDTest
//
//  Created by Vieene on 2016/11/4.
//  Copyright © 2016年 Vieene. All rights reserved.
//  mainQueue 主线程是唯一可用于更新 UI 的线程。这个队列就是用于发生消息给 UIView 或发送通知的。
//至少有五个队列任你处置：主队列、四个全局调度队列，再加上任何你自己创建的队列。

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    

}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self test10];
}
#pragma mark -异步 主队列
- (void)test1
{
    //主线程 就是主线程串行队列  主线程异步 会先执行完毕加入队列之外的代码，然后再执行任务。
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"22222 %@",[NSThread currentThread]);
    });
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"3333 %@",[NSThread currentThread]);
    });
    sleep(2);
    NSLog(@"111111");
}
#pragma mark -同步 主队列  发生死锁
- (void)test2
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSLog(@"22222");
    });
    NSLog(@"111111");

}
#pragma mark -同步 全局队列
- (void)test3
{
    
    dispatch_sync(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"22222 %@",[NSThread currentThread]);
    });
    NSLog(@"111111");
}
#pragma mark -异步 全局队列
- (void)test4
{
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"22222 %@",[NSThread currentThread]);
    });
    NSLog(@"111111");
}
#pragma mark -自定义串行队列 FIFO 规则
- (void)test5
{
    //创建自定义串行队列
    
    //第一个参数：队列标识符，可以获取到某一队列的标识符。
    //第二个参数：队列的类型（串行或者并行）
    dispatch_queue_t serialQueue = dispatch_queue_create("serial", DISPATCH_QUEUE_SERIAL);
    //向自定义串行队列中添加任务
    dispatch_async(serialQueue, ^{
        sleep(2);
        NSLog(@"serialQueue第一个任务%@",[NSThread currentThread]);
    });
    
    dispatch_async(serialQueue, ^{
        sleep(1);

        NSLog(@"serialQueue第二个任务 %@",[NSThread currentThread]);
    });
    
    dispatch_async(serialQueue, ^{
        NSLog(@"serialQueue第三个任务%@",[NSThread currentThread]);
    });
    
    dispatch_async(serialQueue, ^{
        NSLog(@"serialQueue第四个任务%@",[NSThread currentThread]);
    });
    
    //这个标志，一旦设定，就不能更改，所以用const 来接收。
    const  char *s = dispatch_queue_get_label(serialQueue);
    
    NSLog(@"%s",s);
}
#pragma  mark -自定义并行队列 dispatch_barrier_async
- (void)test6
{
    //第二种：自定义并行队列
    dispatch_queue_t concurrentQueue =dispatch_queue_create("concurrent",DISPATCH_QUEUE_CONCURRENT);
    
    //向自定义并行队列中添加任务
    dispatch_async(concurrentQueue, ^{
        sleep(2);
        NSLog(@"concurrentQueue第一个任务%@",[NSThread currentThread]);
    });
    dispatch_async(concurrentQueue, ^{
        sleep(1);
        NSLog(@"concurrentQueue第二个任务%@",[NSThread currentThread]);
    });
    dispatch_async(concurrentQueue, ^{
        NSLog(@"concurrentQueue第三个任务%@",[NSThread currentThread]);
    });
    
    
    //阻塞当前写的第一个参数所对应的队列的任务,必须先执行这个“礁石”任务，才能执行当前队列在这个“礁石任务”后的任务。
    dispatch_barrier_async(concurrentQueue, ^{
        NSLog(@"concurrentQueue阻塞任务");
    });
    
    dispatch_barrier_async(concurrentQueue, ^{
        NSLog(@"concurrentQueue第四个任务");
    });
}
#pragma  mark -信号量测试dispatch_semaphore_t    使用信号量的缺点是会卡线程
- (void)test7
{
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    
    //信号量 创建 为1 ，说明同时只能 1个线程访问 。假如信号量被占用了一个，。
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);//创建一个semaphore 最大信号量为1
    
    NSMutableArray *array = [NSMutableArray array];
    
    for (int index = 0; index < 100000; index++) {
        
        dispatch_async(queue, ^(){
            
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);//等待信号 如果semaphore计数大于等于1，则计数器减去1，程序继续运行。如果计数为0，则线程等待计数器大于0。
            if (index%2 == 0) {
                sleep(1);
            }
            NSLog(@"addd :%d %@", index,[NSThread currentThread]);
            
            [array addObject:[NSNumber numberWithInt:index]];
            
            dispatch_semaphore_signal(semaphore);//发送一个信号通知，其计数会被增加
            
        });
        
    }
}

- (void)test8
{
    CADisplayLink *lin = [CADisplayLink displayLinkWithTarget:self selector:@selector(add:)];
    [lin addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0); //创建信号量
    NSURL *url = [NSURL URLWithString:@"http://192.168.10.228:8080"];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    [request setHTTPMethod:@"GET"];
    
    [request setTimeoutInterval:10];
    
    NSURLSession *session = [NSURLSession sharedSession];
    static int a = 0;
    for ( int i = 0 ; i<5; i++) {
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            sleep(2);
            NSLog(@"网页数据加载完毕！！！！编号%d",i);
            a++;
            if (a == 5) {
            dispatch_semaphore_signal(semaphore);   //发送信号之后，计数器加1 ，这样才能不再等待
            }
           
        }];
        [task resume];
    }
    
    dispatch_semaphore_wait(semaphore,DISPATCH_TIME_FOREVER);  //等待 造成主线程阻塞
    NSLog(@"数据加载完成! %@",[NSThread currentThread]);

 }
#pragma mark -同步执行 + 并行队列
- (void)test9{
    //创建一个并行队列
    dispatch_queue_t queue = dispatch_queue_create("标识符", DISPATCH_QUEUE_CONCURRENT);
    
    NSLog(@"---start---");
    //使用同步函数封装三个任务
    dispatch_sync(queue, ^{
        NSLog(@"任务1---%@", [NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        NSLog(@"任务2---%@", [NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        NSLog(@"任务3---%@", [NSThread currentThread]);
    });
    NSLog(@"---end---");
}
#pragma mark - 异步主线程
- (void)test10{
    //获取主队列
    dispatch_queue_t queue = dispatch_get_main_queue();
    
    NSLog(@"---start---");
    //使用异步函数封装三个任务
    dispatch_async(queue, ^{
        NSLog(@"任务1---%@", [NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"任务2---%@", [NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"任务3---%@", [NSThread currentThread]);
    });
    sleep(2);
    NSLog(@"---end---");
    
}

#pragma mark -active:
static int c = 0;
- (void)add:(id)link
{
    c ++;
    sleep(1);
    NSLog(@"----%d----",c);
}
@end
