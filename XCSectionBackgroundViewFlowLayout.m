//
//  XCSectionBackgroundViewFlowLayout.m
//  XCProject
//
//  Created by can on 2019/5/22.
//  Copyright © 2019 xiaocan. All rights reserved.
//

#import "XCSectionBackgroundViewFlowLayout.h"


@interface XCSectionBackgroundView()

@property (nonatomic, assign) NSInteger section;
@property (nonatomic, copy)   NSString  *identifier;

@end
@implementation XCSectionBackgroundView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.whiteColor;
    }
    return self;
}

@end



@interface UICollectionView (XCSectionBackgroundViewIdentifier)

@property (nonatomic, strong) NSMutableDictionary   *sectionBackgroudViewDic;

@end
@implementation UICollectionView (XCSectionBackgroundViewIdentifier)

- (NSMutableDictionary *)sectionBackgroudViewDic{
    NSMutableDictionary *dic = objc_getAssociatedObject(self, @selector(setSectionBackgroudViewDic:));
    if (!dic) {
        self.sectionBackgroudViewDic = [NSMutableDictionary dictionaryWithCapacity:0];
        dic = objc_getAssociatedObject(self, @selector(setSectionBackgroudViewDic:));
    }
    return dic;
}

- (void)setSectionBackgroudViewDic:(NSMutableDictionary *)sectionBackgroudViewDic{
    objc_setAssociatedObject(self, _cmd, sectionBackgroudViewDic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)removeSectionView:(XCSectionBackgroundView *)view{
    if (view.identifier) {
        NSArray *sectionArr = self.sectionBackgroudViewDic[view.identifier];
        NSMutableArray *visibleArr = sectionArr[0];
        NSMutableArray *layIdleArr = sectionArr[1];
        if ([visibleArr containsObject:view]) {
            [visibleArr removeObject:view];
        }
        [layIdleArr addObject:view];
    }
}


@end










@interface XCSectionBackgroundViewFlowLayout()

@property (nonatomic, weak, nullable) id<UICollectionViewDelegateFlowLayout, XCSectionBackgroundViewFlowLayoutDelegate> ncfDelegate;

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSString *>   *sectionFrameDic;

@property (nonatomic, assign) BOOL                  hasAddObserver;

@end

@implementation XCSectionBackgroundViewFlowLayout

- (NSMutableDictionary<NSNumber *, NSString *> *)sectionFrameDic{
    if (!_sectionFrameDic) {
        _sectionFrameDic = [NSMutableDictionary dictionaryWithCapacity:0];
    }
    return _sectionFrameDic;
}

- (void)prepareLayout{
    [super prepareLayout];
    self.ncfDelegate = (id<UICollectionViewDelegateFlowLayout, XCSectionBackgroundViewFlowLayoutDelegate>)(self.collectionView.dataSource);
    NSArray *subViews = [self.collectionView subviews];
    for (UIView *view in subViews) {
        if ([view isKindOfClass:[ZGSectionBackgroundView class]]) {
            [view removeFromSuperview];
        }
        else{
            continue;
        }
    }
    if (!_hasAddObserver) {
        _hasAddObserver = YES;
        [self.collectionView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    }
    
    [self layoutSectionItemsBackgroundView];
    
}

- (void)layoutSectionItemsBackgroundView{
    [self.sectionFrameDic removeAllObjects];
    if ([self.ncfDelegate respondsToSelector:@selector(collectionView:layout:sectionItemsBackgroundViewAtSection:)]) {
        NSInteger sections = [self.collectionView numberOfSections];
        for (NSInteger section = 0; section < sections; section++) {
            CGRect visibleFrame = [self sectionItemsVisibleFrameAtSection:section];
            [self.sectionFrameDic setObject:NSStringFromCGRect(visibleFrame) forKey:@(section)];
        }
    }
    [self observeValueForKeyPath:nil ofObject:nil change:nil context:nil];
}


- (CGRect)sectionItemsVisibleFrameAtSection:(NSInteger)section{
    if ([self.collectionView numberOfItemsInSection:section] == 0) {
        return CGRectZero;
    }
    else{
        UICollectionViewLayoutAttributes *headerAttributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
        if (headerAttributes) {
            
            UICollectionViewLayoutAttributes *footerAttributes = footerAttributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter atIndexPath:[NSIndexPath indexPathForItem:0 inSection:headerAttributes.indexPath.section]];
            if (!footerAttributes
                ||footerAttributes.frame.origin.y == headerAttributes.frame.origin.y) {
                footerAttributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForItem:0 inSection:headerAttributes.indexPath.section + 1]];
            }
            if (!footerAttributes) {
                footerAttributes = [[UICollectionViewLayoutAttributes alloc] init];
                NSInteger items = [self.collectionView numberOfItemsInSection:headerAttributes.indexPath.section];
                UICollectionViewLayoutAttributes *itemAttribute = [self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:items - 1 inSection:headerAttributes.indexPath.section]];
                
                if (itemAttribute) {
                    UIEdgeInsets sectionIntets = self.sectionInset;
                    if ([self.ncfDelegate respondsToSelector:@selector(collectionView:layout:insetForSectionAtIndex:)]) {
                        sectionIntets = [self.ncfDelegate collectionView:self.collectionView layout:self insetForSectionAtIndex:headerAttributes.indexPath.section];
                    }
                    CGRect footerFrame;
                    if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
                        footerFrame = CGRectMake(CGRectGetMaxX(itemAttribute.frame) + sectionIntets.right, 0, 0, 0);
                    }
                    else{
                        footerFrame = CGRectMake(headerAttributes.frame.origin.x, CGRectGetMaxY(itemAttribute.frame) + sectionIntets.bottom, headerAttributes.frame.size.width, 0);
                    }
                    footerAttributes.frame = footerFrame;
                }
                else{
                    return CGRectZero;
                }
                
            }
            
            if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
                CGRect visibleFrame = CGRectZero;
                visibleFrame.origin.x = CGRectGetMaxX(headerAttributes.frame);
                visibleFrame.origin.y = 0;
                visibleFrame.size.width = CGRectGetMinX(footerAttributes.frame) - CGRectGetMaxX(headerAttributes.frame);
                visibleFrame.size.height = CGRectGetHeight(self.collectionView.frame);
                
                UIEdgeInsets insets = self.sectionBackgroundViewInsets;
                if ([self.ncfDelegate respondsToSelector:@selector(collectionView:layout:forSectionItemsBackgroundInsetsAtSection:)]) {
                    insets = [self.ncfDelegate collectionView:self.collectionView layout:self forSectionItemsBackgroundInsetsAtSection:headerAttributes.indexPath.section];
                }
                visibleFrame.origin.x = visibleFrame.origin.x + insets.left;
                visibleFrame.origin.y = visibleFrame.origin.y + insets.top;
                visibleFrame.size.width = visibleFrame.size.width - insets.left - insets.right;
                visibleFrame.size.height = visibleFrame.size.height - insets.top - insets.bottom;
                return visibleFrame;
            }
            else{
                CGRect visibleFrame = CGRectZero;
                visibleFrame.origin.x = CGRectGetMinX(headerAttributes.frame);
                visibleFrame.origin.y = CGRectGetMaxY(headerAttributes.frame);
                visibleFrame.size.width = CGRectGetWidth(self.collectionView.frame);
                visibleFrame.size.height = CGRectGetMinY(footerAttributes.frame) - CGRectGetMaxY(headerAttributes.frame);
                
                UIEdgeInsets insets = self.sectionBackgroundViewInsets;
                if ([self.ncfDelegate respondsToSelector:@selector(collectionView:layout:forSectionItemsBackgroundInsetsAtSection:)]) {
                    insets = [self.ncfDelegate collectionView:self.collectionView layout:self forSectionItemsBackgroundInsetsAtSection:headerAttributes.indexPath.section];
                }
                visibleFrame.origin.x = visibleFrame.origin.x + insets.left;
                visibleFrame.origin.y = visibleFrame.origin.y + insets.top;
                visibleFrame.size.width = visibleFrame.size.width - insets.left - insets.right;
                visibleFrame.size.height = visibleFrame.size.height - insets.top - insets.bottom;
                return visibleFrame;
            }
        }
        else{
            return CGRectZero;
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    
    if (self.sectionFrameDic.count > 0
        && [self.ncfDelegate respondsToSelector:@selector(collectionView:layout:sectionItemsBackgroundViewAtSection:)]) {
        CGPoint offset = self.collectionView.contentOffset;
        
        CGRect visibleFrame = CGRectMake(0, offset.y, CGRectGetWidth(self.collectionView.frame), CGRectGetHeight(self.collectionView.frame));
        
        NSMutableDictionary *visibleFrames = [NSMutableDictionary dictionaryWithCapacity:0];
        
        NSArray *allKeys = [[self.sectionFrameDic allKeys] sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            if ([obj1 integerValue] > [obj2 integerValue]) {
                return NSOrderedDescending;
            }
            else{
                return NSOrderedAscending;
            }
        }];
        
        //找到当前窗口内的section backgroundView frame
        for (NSNumber *number in allKeys) {
            NSString *frameStr = [self.sectionFrameDic objectForKey:number];
            if (frameStr.length > 0) {
                CGRect frame = CGRectFromString(frameStr);
                if (CGRectIntersectsRect(visibleFrame, frame)) {
                    [visibleFrames setObject:frameStr forKey:number];
                }
            }
        }
        
        //移除超出可见视图的sectionBackgroundView，添加进入到可见视图内的sectionBackgroundView
        NSArray *sectionViews = [self.collectionView subviews];
        for (ZGSectionBackgroundView *view in sectionViews) {
            if ([view isKindOfClass:[ZGSectionBackgroundView class]]) {
                
                //判断view frame是否有效
                BOOL isVisibleFrame = NO;
                if (!CGRectEqualToRect(view.frame, CGRectZero)
                && CGRectIntersectsRect(view.frame, visibleFrame)) {
                    isVisibleFrame = YES;
                }
                //水平滚动
                if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal
                    && CGRectGetWidth(view.frame) < 0.5) {
                    isVisibleFrame = NO;
                }
                //垂直滚动
                if (self.scrollDirection == UICollectionViewScrollDirectionVertical
                    && CGRectGetHeight(view.frame) < 0.5) {
                    isVisibleFrame = NO;
                }
                if (isVisibleFrame) {
                    [visibleFrames removeObjectForKey:@(view.section)];
                }
                else{//移除,移动到重用队列
                    [view removeFromSuperview];
                    [self.collectionView removeSectionView:view];
                }
            }
            else{
                continue;
            }
        }
        
        //新进入到可见试图内的sectionBackgroundView
        allKeys = [[visibleFrames allKeys] sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            if ([obj1 integerValue] > [obj2 integerValue]) {
                return NSOrderedDescending;
            }
            else{
                return NSOrderedAscending;
            }
        }];
        for (NSNumber *section in allKeys) {
            CGRect frame = CGRectFromString(visibleFrames[section]);
            if (!CGRectEqualToRect(frame, CGRectZero)) {
                ZGSectionBackgroundView *sectionView = [self.ncfDelegate collectionView:self.collectionView layout:self sectionItemsBackgroundViewAtSection:[section integerValue]];
                sectionView.section = [section integerValue];
                if (sectionView
                    && [sectionView isKindOfClass:[XCSectionBackgroundView class]]) {
                    sectionView.frame = CGRectFromString(visibleFrames[section]);
                    sectionView.layer.zPosition = -1000;
                    sectionView.userInteractionEnabled = NO;
                    [self.collectionView addSubview:sectionView];
                }
            }
        }
    }
    
}


- (void)dealloc
{
    if (self.collectionView && self.hasAddObserver) {
        [self.collectionView removeObserver:self forKeyPath:@"contentOffset"];
    }
}


@end









//UICollectioView 添加注册机制
@implementation UICollectionView (XCSectionBackgroundView)

- (void)registerSectionBackgroundViewClass:(nullable Class)viewClass withReuseIdentifier:(NSString *)identifier{
    if (!viewClass) {
        viewClass = ZGSectionBackgroundView.class;
    }
    NSAssert([[viewClass new] isKindOfClass:[ZGSectionBackgroundView class]], @"registerSectionBackgroundViewClass 必须注册一个ZGSectionBackgroundView类型");
    NSMutableArray *visibleArr = [NSMutableArray arrayWithCapacity:0];
    NSMutableArray *layIdleArr = [NSMutableArray arrayWithCapacity:0];
    [self.sectionBackgroudViewDic setObject:@[visibleArr, layIdleArr, viewClass ? viewClass : ZGSectionBackgroundView.class] forKey:identifier];
}

- (__kindof XCSectionBackgroundView *)dequeueReusableSectionBackgroundViewWithReuseIdentifier:(NSString *)identifier forSection:(NSInteger)section{
    NSArray *sectionArr = self.sectionBackgroudViewDic[identifier];
    NSMutableArray *visibleArr = sectionArr[0];
    NSMutableArray *layIdleArr = sectionArr[1];
    Class viewClass = sectionArr[2];
    
    XCSectionBackgroundView *view = nil;
    if (layIdleArr.count > 0) {
        view = [layIdleArr firstObject];
        view.identifier = identifier;
        view.section = section;
        [layIdleArr removeObject:view];
        [visibleArr addObject:view];
    }
    else{
        view = [viewClass new];
        view.identifier = identifier;
        view.section = section;
        [visibleArr addObject:view];
    }
    return view;
}


@end


