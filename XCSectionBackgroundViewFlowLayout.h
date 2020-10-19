//
//  NotifyCenterComponentsFlowLayout.h
//  MineModule
//
//  Created by can on 2019/5/22.
//  Copyright © 2019 xiaocan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

@class ZGSectionBackgroundView;

@protocol ZGSectionBackgroundViewFlowLayoutDelegate <NSObject>


@optional
//设备背景insets
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout forSectionItemsBackgroundInsetsAtSection:(NSInteger)section;

//返回背景，返回nil表示不设背景
- (__kindof ZGSectionBackgroundView *_Nullable)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sectionItemsBackgroundViewAtSection:(NSInteger)section;

@end

/**
 * UICollectionView 给每个区添加背景view Layout
 */
@interface ZGSectionBackgroundViewFlowLayout : UICollectionViewFlowLayout

@property (nonatomic, assign) UIEdgeInsets  sectionBackgroundViewInsets;

@end



@interface UICollectionView (ZGSectionBackgroundView)

/**
 * 注册sectionBackgroundView， viewClass必须是 ZGSectionBackgroundView.class 类型
 */
- (void)registerSectionBackgroundViewClass:(nullable Class)viewClass withReuseIdentifier:(NSString *)identifier;

/**
 * 从注册队列获取 ZGSectionBackgroundView
 */
- (__kindof ZGSectionBackgroundView *)dequeueReusableSectionBackgroundViewWithReuseIdentifier:(NSString *)identifier forSection:(NSInteger)section;


@end

@interface ZGSectionBackgroundView : UIView

@end

NS_ASSUME_NONNULL_END
