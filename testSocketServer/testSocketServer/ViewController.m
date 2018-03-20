//
//  ViewController.m
//  testSocketServer
//
//  Created by li’Pro on 2018/3/15.
//  Copyright © 2018年 wzl. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"


@interface ViewController ()<GCDAsyncSocketDelegate>
@property (weak, nonatomic) IBOutlet UITextField *txtPort;
@property (weak, nonatomic) IBOutlet UITextField *txtMsg;
@property (weak, nonatomic) IBOutlet UITextView *txvTip;
@property (strong, nonatomic) GCDAsyncSocket *socketServer;
@property (strong, nonatomic) NSMutableArray<GCDAsyncSocket *> *arrClient;

@property (strong, nonatomic) NSMutableDictionary *mudicSending;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _arrClient = @[].mutableCopy;
    _mudicSending = [[NSMutableDictionary alloc] initWithCapacity:10];
    
    NSData *data = [GCDAsyncSocket CRLFData];
    NSData *dataTail = [@"\r\n" dataUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"%@|%@|", data, dataTail);
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"%@", str);
}
- (IBAction)listen:(id)sender {
    if (self.socketServer) {
        [self showTipMessage:@"已连接"];
        return;
    }
    [_arrClient removeAllObjects];
    uint16_t port = [self.txtPort.text intValue];
    if (0 == port) {
        [self showTipMessage:@"请输入端口号"];
        return;
    }
    NSError *error = nil;
    self.socketServer = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    if ([self.socketServer acceptOnPort:port error:&error] && nil == error) {
        [self showTipMessage:@"监听中..."];
    } else {
        [self showTipMessage:@"监听错误"];
    }
}
- (IBAction)sendMsg:(id)sender {
    if (self.txtMsg.text.length == 0) {
        return;
    }
    NSString *text = [NSString stringWithFormat:@"%@", self.txtMsg.text];
    NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
    
    long tag = time(nil);
    for (GCDAsyncSocket *client in _arrClient) {
        [client writeData:data withTimeout:-1 tag:tag];
    }
    
    self.txtMsg.text = nil;
    // 将正在发送的消息保存起来
    [self.mudicSending setObject:text forKey:@(tag)];
}

#pragma -mark 
#pragma -mark GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    NSLog(@"%s", __func__);
    NSString *tip = [NSString stringWithFormat:@"新连接：%@:%d", newSocket.connectedHost, newSocket.connectedPort];
    [self showTipMessage:tip];
    [self.arrClient addObject:newSocket];
    
    [newSocket readDataWithTimeout:-1 tag:0];
}
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSLog(@"%s:%ld", __func__, tag);
    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
   
    [self showTipMessage:text];
    
    
    [sock readDataWithTimeout:-1 tag:0];
}


- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"%s:%ld", __func__, tag);
    // 将发送中的消息取出显示
    NSString *msg = [NSString stringWithFormat:@"我：%@", [self.mudicSending objectForKey:@(tag)]];
    
    [self.mudicSending removeObjectForKey:@(tag)];
    [self showTipMessage:msg];
}
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err {
    NSLog(@"%s", __func__);
    [self showTipMessage:@"socketDidDisconnect"];
    [self.socketServer setDelegate:nil];
    self.socketServer = nil;
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



















