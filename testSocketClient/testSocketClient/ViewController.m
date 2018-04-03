//
//  ViewController.m
//  testSocketClient
//
//  Created by li’Pro on 2018/3/15.
//  Copyright © 2018年 wzl. All rights reserved.
//  iphone :192.168.6.126

#import "ViewController.h"
#import "GCDAsyncSocket.h"

@interface ViewController ()<GCDAsyncSocketDelegate>
@property (weak, nonatomic) IBOutlet UITextField *txtHost;
@property (weak, nonatomic) IBOutlet UITextField *txtPort;
@property (weak, nonatomic) IBOutlet UITextField *txtMsg;
@property (weak, nonatomic) IBOutlet UITextView *txvTip;
@property (strong, nonatomic) GCDAsyncSocket *socketClient;

@property (strong, nonatomic) NSMutableDictionary *mudicSending;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _mudicSending = [[NSMutableDictionary alloc] initWithCapacity:10];
}

- (IBAction)connect:(id)sender {
    if (self.socketClient) {
        [self showTipMessage:@"已连接"];
        return;
    }
    [_mudicSending removeAllObjects];
    NSError *error = nil;
    self.socketClient = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    if ([self.socketClient connectToHost:self.txtHost.text onPort:[self.txtPort.text intValue] error:&error] 
        && nil == error) {
        [self showTipMessage:@"连接中。。。"];
    } else {
        [self showTipMessage:@"连接中出错"];
    }
}
- (IBAction)sendMsg:(id)sender {
    if (self.txtMsg.text.length == 0) {
        return;
    }
    NSString *text = [NSString stringWithFormat:@"%@", self.txtMsg.text];
    NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
    
    long tag = time(nil);
    [self.socketClient writeData:data withTimeout:-1 tag:tag];
    
    self.txtMsg.text = nil;
    // 将正在发送的消息保存起来
    [self.mudicSending setObject:text forKey:@(tag)];
}

#pragma -mark 
#pragma -mark GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"%s", __func__);
    NSString *tip = [NSString stringWithFormat:@"已连接%@:%d", host, port];
    [self showTipMessage:tip];
    
    [sock readDataWithTimeout:-1 tag:0];
}

/**
 * Called when a socket has completed reading the requested data into memory.
 * Not called if there is an error.
 **/
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSLog(@"%s:%ld", __func__, tag);
    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    [self showTipMessage:text];
    [sock readDataWithTimeout:15 tag:0];
}
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"%s:%ld", __func__, tag);
    // 将发送中的消息取出显示
    NSString *msg = [NSString stringWithFormat:@"我：%@", [self.mudicSending objectForKey:@(tag)]];
    
    [self.mudicSending removeObjectForKey:@(tag)];
    [self showTipMessage:msg];
}
/**
 后台 95 s 会断开
 code 
 2: 服务器没监听，服务器地址、端口错了
 4: 读数据超过指定超时时间
 7: 服务器断开连接
 */
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err {
    NSLog(@"%s", __func__);
    [self showTipMessage:@"socketDidDisconnect"];
    [self.socketClient setDelegate:nil];
    self.socketClient = nil;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (void)showTipMessage:(NSString *)msg {
    NSString *text = self.txvTip.text;
    text = [NSString stringWithFormat:@"%@\n%@", msg, text];
    self.txvTip.text = text;
}

@end
