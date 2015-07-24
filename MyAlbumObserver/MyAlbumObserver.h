//
//  MyAlbumObserver.h
//  DemoOfObserverImagesChange
//
//  Created by 蔡成汉 on 15/7/14.
//  Copyright (c) 2015年 JW. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MyAlbumObserver : NSObject

/**
 *  单例方法
 *
 *  @return 实例化之后的MyAlbumObserver
 */
+(MyAlbumObserver *)shareMyAlbumObserver;

/**
 *  检查相册 -- 如果用于允许相册访问，则会在获取到图片后进行block返回；如果用户不允许，则不进行block返回，而是直接由这个类进行提示
 *
 *  @param result 相册检查的结果：缩略图，原始图，是否为新图
 */
-(void)startCheckMyAlbum:(void(^)(UIImage *thumImage ,UIImage *originalImage ,BOOL isNew))result;

@end
