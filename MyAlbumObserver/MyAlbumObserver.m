//
//  MyAlbumObserver.m
//  DemoOfObserverImagesChange
//
//  Created by 蔡成汉 on 15/7/14.
//  Copyright (c) 2015年 JW. All rights reserved.
//

#import "MyAlbumObserver.h"
#import <AssetsLibrary/AssetsLibrary.h>

/**
 *  定义的宏 -- 是否显示提示框
 */
#define canShowAlertView @"canShowMyAlbumObserverAlertView"

static MyAlbumObserver *myAlbumObserver;

@interface MyAlbumObserver ()<UIAlertViewDelegate>
{
    /**
     *  当前Asset -- 用于匹配上一次图片
     */
    ALAsset *currentAsset;
    
    /**
     *  是否在现实错误信息，默认为NO
     */
    BOOL showError;
    
    /**
     *  获取图片完成，默认为NO
     */
    BOOL getAlbumFinished;
    
    /**
     *  assets 存放图片的数组
     */
    NSMutableArray *assets;
    
    /**
     *  所有图片
     */
    ALAssetsLibrary *assetsLibrary;
    
    /**
     *  相册列表
     */
    NSMutableArray *groups;
}

/**
 *  扫描的结果
 */
@property (nonatomic , copy) void(^result)(UIImage *thumImage ,UIImage *originalImage ,BOOL isNew);

@end

@implementation MyAlbumObserver

/**
 *  单例方法
 *
 *  @return 实例化之后的MyAlbumObserver
 */
+(MyAlbumObserver *)shareMyAlbumObserver
{
    @synchronized (self)
    {
        if (myAlbumObserver == nil)
        {
            myAlbumObserver = [[self alloc] init];
        }
    }
    return myAlbumObserver;
}

-(id)init
{
    self = [super init];
    if (self)
    {
        //初始化数据 -- 设置默认值
        currentAsset = [[ALAsset alloc]init];
        showError = NO;
        getAlbumFinished = NO;
        assets = [NSMutableArray array];
        assetsLibrary = [self.class defaultAssetsLibrary];
        groups = [NSMutableArray array];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:canShowAlertView];
        [defaults synchronize];
    }
    return self;
}

/**
 *  检查相册
 *
 *  @param result 相册检查的结果：缩略图，原始图，是否为新图
 */
-(void)startCheckMyAlbum:(void(^)(UIImage *thumImage ,UIImage *originalImage ,BOOL isNew))result
{
    getAlbumFinished = NO;
    self.result = result;
    [self getImageGroup];
}

/**
 *  获取相册列表
 */
-(void)getImageGroup
{
    if (assetsLibrary == nil)
    {
        assetsLibrary = [self.class defaultAssetsLibrary];
    }
    
    if (groups == nil)
    {
        groups = [NSMutableArray array];
    }
    else
    {
        [groups removeAllObjects];
    }
    
    ALAssetsFilter *assetsFilter = [ALAssetsFilter allPhotos];
    
    ALAssetsLibraryGroupsEnumerationResultsBlock resultsBlock = ^(ALAssetsGroup *group, BOOL *stop)
    {
        if (group)
        {
            [group setAssetsFilter:assetsFilter];
            if (group.numberOfAssets > 0)
            {
                [groups addObject:group];
            }
        }
        else
        {
            //被调用了2次 -- 2次结果一样
            if (getAlbumFinished == NO)
            {
                getAlbumFinished = YES;
                [self getAssetGroupFinish];
            }
        }
    };
    
    ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *error) {
        if (error)
        {
            //被调用了2次
            if (showError == NO)
            {
                showError = YES;
                
                //判断是否用户允许访问
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                BOOL canShow = [defaults boolForKey:canShowAlertView];
                if (canShow == YES)
                {
                    UIAlertView *myAlertView = [[UIAlertView alloc]initWithTitle:@"提示" message:@"无法访问相册，请允许程序访问" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil];
                    [myAlertView show];
                }
            }
        }
    };
    
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                                      usingBlock:resultsBlock
                                    failureBlock:failureBlock];
    
    // Then all other groups
    NSUInteger type =
    ALAssetsGroupLibrary | ALAssetsGroupAlbum | ALAssetsGroupEvent |
    ALAssetsGroupFaces | ALAssetsGroupPhotoStream;
    
    [assetsLibrary enumerateGroupsWithTypes:type
                                      usingBlock:resultsBlock
                                    failureBlock:failureBlock];
}

#pragma mark - ALAssetsLibrary

+ (ALAssetsLibrary *)defaultAssetsLibrary
{
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once(&pred, ^{
        library = [[ALAssetsLibrary alloc] init];
    });
    return library;
}

/**
 *  获取相册列表完成
 */
-(void)getAssetGroupFinish
{
    //这里获取的是第一个相册的图片，由于IOS系统原因，相册的第一个分组即为“所有照片”分组
    [self getImages:[groups objectAtIndex:0]];
}
/**
 *  获取图片
 *
 *  @param assetsGroup 目标相册
 */
-(void)getImages:(ALAssetsGroup *)assetsGroup
{
    if (assets == nil)
    {
        assets = [NSMutableArray array];
    }
    else
    {
        [assets removeAllObjects];
    }
    
    //获取assetsGroup里的图片
    
    ALAssetsGroupEnumerationResultsBlock resultsBlock = ^(ALAsset *asset, NSUInteger index, BOOL *stop) {
        if (asset)
        {
            [assets addObject:asset];
        }
        else
        {
            //数据处理 -- 判断是否为新图
            NSDictionary *tpDic = [self checkMyImage];
            UIImage *tpThumbImage = [tpDic objectForKey:@"thumb"];
            UIImage *tpOriginalImage = [tpDic objectForKey:@"original"];
            NSNumber *tpNewNum = [tpDic objectForKey:@"isNew"];
            
            if (self.result)
            {
                self.result(tpThumbImage,tpOriginalImage,[tpNewNum boolValue]);
            }
        }
    };
    [assetsGroup enumerateAssetsUsingBlock:resultsBlock];
}

-(NSDictionary *)checkMyImage
{
    NSMutableDictionary *tpDic = [NSMutableDictionary dictionary];
    //获取相册里的最后一张图
    if (assets.count>0)
    {
        ALAsset *tpAsset = [assets lastObject];
        NSString *tpAssetURL = [[tpAsset valueForProperty:ALAssetPropertyAssetURL]absoluteString];
        if (tpAssetURL == nil)
        {
            tpAssetURL = @"tpAssetURL";
        }
        NSString *currentAssetURL = [[currentAsset valueForProperty:ALAssetPropertyAssetURL]absoluteString];
        if (currentAssetURL == nil)
        {
            currentAssetURL = @"currentAssetURL";
        }
        if ([tpAssetURL isEqualToString:currentAssetURL])
        {
            //表示还是旧的
            if (currentAsset)
            {
                //有数据 -- 分别获取缩率图，原图，是否为新图
                UIImage *tpThumbImage = [UIImage imageWithCGImage:currentAsset.thumbnail];
                UIImage *tpOriginalImage = [UIImage imageWithCGImage:currentAsset.defaultRepresentation.fullScreenImage];
                [tpDic setObject:tpThumbImage forKey:@"thumb"];
                [tpDic setObject:tpOriginalImage forKey:@"original"];
                [tpDic setObject:[NSNumber numberWithBool:NO] forKey:@"isNew"];
            }
        }
        else
        {
            //表示有新图
            //有数据 -- 分别获取缩率图，原图，是否为新图
            UIImage *tpThumbImage = [UIImage imageWithCGImage:tpAsset.thumbnail];
            UIImage *tpOriginalImage = [UIImage imageWithCGImage:tpAsset.defaultRepresentation.fullScreenImage];
            [tpDic setObject:tpThumbImage forKey:@"thumb"];
            [tpDic setObject:tpOriginalImage forKey:@"original"];
            [tpDic setObject:[NSNumber numberWithBool:YES] forKey:@"isNew"];
            currentAsset = tpAsset;
        }
    }
    return tpDic;
}


#pragma mark - UIAlertViewDelegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        //确定
        if ([[[UIDevice currentDevice]systemVersion]floatValue] >= 8.0)
        {
            if (UIApplicationOpenSettingsURLString != NULL)
            {
                [[UIApplication sharedApplication]openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
            }
        }
    }
    else
    {
        //取消 -- 不在弹框 -- 写沙盒
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:NO forKey:canShowAlertView];
        [defaults synchronize];
    }
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    showError = NO;
}

@end
