//
//  ViewController.m
//  DemoOfObserverImagesChange
//
//  Created by 蔡成汉 on 15/7/14.
//  Copyright (c) 2015年 JW. All rights reserved.
//

#import "ViewController.h"
#import "MyAlbumObserver.h"

@interface ViewController ()
{
    UIImageView *myImageView;
}
@end

@implementation ViewController

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        //注册通告 -- 程序进入前台的通告
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(applicationWillEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [UIColor blueColor];
    button.frame = CGRectMake(100, 100, 100, 30);
    [button addTarget:self action:@selector(buttonIsTouch:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    myImageView = [[UIImageView alloc]initWithFrame:CGRectMake(60, 200, 200, 300)];
    myImageView.backgroundColor = [UIColor clearColor];
    myImageView.contentMode = UIViewContentModeScaleAspectFit;
    myImageView.clipsToBounds = YES;
    [self.view addSubview:myImageView];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

-(void)buttonIsTouch:(UIButton *)paramSender
{
    MyAlbumObserver *myAlbumObserver = [MyAlbumObserver shareMyAlbumObserver];
    [myAlbumObserver startCheckMyAlbum:^(UIImage *thumImage, UIImage *originalImage, BOOL isNew) {
        myImageView.image = originalImage;
    }];
}

#pragma mark - UIApplicationWillEnterForegroundNotification

/**
 *  程序进入前台的通告 -- 从后台进入前台
 *
 *  @param notification 程序进入前台的通告
 */
-(void)applicationWillEnterForegroundNotification:(NSNotification *)notification
{
    [self buttonIsTouch:nil];
}

/**
 *  清理工作
 */
-(void)dealloc
{
    //移除通告    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
