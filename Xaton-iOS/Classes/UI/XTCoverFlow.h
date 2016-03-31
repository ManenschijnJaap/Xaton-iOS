//
//  XTCoverFlow.h
//  SupermarketDirect
//
//  Created by Angel Garcia on 3/20/13.
//  Copyright (c) 2013 Xaton. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XTCoverFlow;

@protocol XTCoverFlowDataSource <NSObject>

- (NSUInteger)numberOfItemsInCoverFlow:(XTCoverFlow *)coverFlow;

- (UIView *)coverFlow:(XTCoverFlow *)coverFlow itemAtIndex:(NSUInteger)index;

@end

@protocol XTCoverFlowDelegate <UIScrollViewDelegate>

@optional

- (BOOL)coverFlow:(XTCoverFlow *)coverFlow shouldScrollToItem:(NSUInteger)index;

- (void)coverFlow:(XTCoverFlow *)coverFlow didSelectItem:(NSUInteger)item;

//TODO
- (void)coverFlow:(XTCoverFlow *)coverFlow willChangeCurrentItem:(NSUInteger)toItem;

@end


//Protocol to draw the animation effects
@protocol XTCoverFlowRenderProtocol <NSObject>

- (instancetype)initWithCoverFlow:(XTCoverFlow *)coverFlow;

//This method should only use transformations to render info
- (void)render;

- (CGFloat)pageWidth;
- (CGSize)contentSizeForPageCount:(NSUInteger)pageCount;

- (void)layoutPage:(UIView *)page atIndex:(NSUInteger)index;

@end



@interface XTCoverFlow : UIScrollView

@property(nonatomic, weak) IBOutlet id<XTCoverFlowDataSource> dataSource;
@property(nonatomic, weak) IBOutlet id<XTCoverFlowDelegate> delegate;

// Each item will be place in a page. Controling page width gives you access to dragging speed and similar. Defaults to width * 0.4
//@property(nonatomic, assign) CGFloat pageWidth;

// Rate reduction applied when a draggin is set. Defaults to 0.3
@property(nonatomic, assign) CGFloat decelerationReduction;

// Rendered used. Default to XTCoverFlow3DRender
@property(nonatomic, strong) id<XTCoverFlowRenderProtocol> renderer;


- (void)reloadData;

// Controling paging and items
- (CGFloat)currentPage;
- (NSUInteger)currentItem;
- (void)scrollToCurrentItemAnimated:(BOOL)animated;
- (void)scrollToItem:(NSUInteger)item animated:(BOOL)animated;


@end

@interface XTCoverFlowFlatRender : NSObject<XTCoverFlowRenderProtocol>

@property(nonatomic, weak) XTCoverFlow *coverFlow;
@property(nonatomic, assign) CGFloat itemWidth;
@property(nonatomic, assign) CGFloat itemMargin;

@end


//3D render that mimics the itunes coverflow effect
@interface XTCoverFlow3DRender : NSObject<XTCoverFlowRenderProtocol>

@property(nonatomic, weak) XTCoverFlow *coverFlow;
@property(nonatomic, assign) CGFloat itemSeparation;
@property(nonatomic, assign) CGFloat itemWidth;
@property(nonatomic, assign) CGFloat itemScale;

@end

