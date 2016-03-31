//
//  XTCoverFlow.m
//  SupermarketDirect
//
//  Created by Angel Garcia on 3/20/13.
//  Copyright (c) 2013 Xaton. All rights reserved.
//

#import "XTCoverFlow.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

@interface XTCoverFlow()<XTCoverFlowDelegate>

@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, assign) NSUInteger numItems;
@property (nonatomic, weak) id<XTCoverFlowDelegate> customDelegate;

@end


@implementation XTCoverFlow


#pragma mark - Life cycle

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];    
}


- (void)setup {
    self.customDelegate = self.delegate;
    super.delegate = self;
    self.directionalLockEnabled = YES;
    self.showsVerticalScrollIndicator = NO;
    self.showsHorizontalScrollIndicator = NO;
    self.decelerationReduction = 0.3;
    self.renderer = [[XTCoverFlow3DRender alloc] initWithCoverFlow:self];
    self.decelerationRate = UIScrollViewDecelerationRateFast;
}

#pragma mark - Drawing

- (void)layoutSubviews {
    if (!self.items) {
        [self reloadData];
    }
    [self bringSubviewToFront:[self viewForItem:[self currentItem]]];
    [self.renderer render];
}


#pragma mark - Public API

- (void)reloadData {
    
    //Remove old data
    for (UIView *view in self.items) {
        if ([view isKindOfClass:[UIView class]]) {
            [view removeFromSuperview];
        }
    }
    
    //Query the delegate again
    self.numItems = [self.dataSource numberOfItemsInCoverFlow:self];
    self.items = [NSMutableArray arrayWithCapacity:self.numItems];
    for (int i = 0; i < self.numItems; i++) {
        self.items[i] = [NSNull null];
    }
    
    self.contentSize = [self.renderer contentSizeForPageCount:self.numItems];
    
    //Force layaout again
    [self setNeedsLayout];
}

- (CGFloat)currentPage {
    return self.contentOffset.x / self.renderer.pageWidth;
}

- (NSUInteger)currentItem {
    return MAX(0, MIN(lround([self currentPage]), self.items.count));
}

- (void)scrollToCurrentItemAnimated:(BOOL)animated {
    [self setContentOffset:[self offsetForPage:[self currentItem]] animated:animated];
}

- (void)scrollToItem:(NSUInteger)item animated:(BOOL)animated {
    if (self.items.count == 0) return;
    item = MAX(0, MIN(item, self.items.count));
    [self setContentOffset:[self offsetForPage:item] animated:animated];
}

#pragma mark - Private methods

- (UIView *)viewForItem:(NSUInteger)item {
    if (item >= self.items.count) return nil;
    UIView *view = self.items[item];
    if ([view isKindOfClass:[NSNull class]]) {
        UIView *sourceView = [self.dataSource coverFlow:self itemAtIndex:item];        
        NSAssert(sourceView, @"View for item %d in coverflow is nil", item);
        view = [[UIView alloc] initWithFrame:sourceView.bounds];
        view.backgroundColor = [UIColor clearColor];
        [view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnItem:)]];
        [view addSubview:sourceView];
        [self addSubview:view];
        [self sendSubviewToBack:view];
        self.items[item] = view;
        [self.renderer layoutPage:view atIndex:item];
    }
    return view;
}

- (CGPoint)offsetForPage:(CGFloat)page {
    return CGPointMake(page * self.renderer.pageWidth, 0);
}

- (void)tapOnItem:(UITapGestureRecognizer *)gesture {
    
    UIView *itemView = gesture.view;
    NSInteger item = [self.items  indexOfObject:itemView];
    NSUInteger currentItem = [self currentItem];
    if (item >= 0) {
        if (currentItem != item &&
                (self.customDelegate == nil ||
                 [self.customDelegate respondsToSelector:@selector(coverFlow:shouldScrollToItem:)] == NO ||
                 [self.customDelegate coverFlow:self shouldScrollToItem:item])) {
            [self scrollToItem:item animated:YES];
        }
        
        if (self.customDelegate && [self.customDelegate respondsToSelector:@selector(coverFlow:didSelectItem:)]) {
            [self.customDelegate coverFlow:self didSelectItem:item];
        }
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    
    CGFloat targetPage = targetContentOffset->x / self.renderer.pageWidth;
    CGFloat currentPage = [self currentPage];
    CGFloat pageDelta = targetPage - currentPage;
    
    //Speed reduction
    targetPage -= pageDelta * self.decelerationReduction;
    
    *targetContentOffset = [self offsetForPage:roundf(targetPage)];
    
    //Forward invocation if needed
    if (self.customDelegate && [self.customDelegate respondsToSelector:@selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:)]) {
        [self.customDelegate scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
    }
}

@end

#pragma mark - Delegate forward invocations

@implementation XTCoverFlow(ForwardInvocation)

- (BOOL)respondsToSelector:(SEL)aSelector {
    BOOL ret = [super respondsToSelector:aSelector];
    if (ret) {
        return ret;
    }
    return [self methodCanBeForwardedToCustomDelegate:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    if ([self methodCanBeForwardedToCustomDelegate:aSelector]) {
        return self.customDelegate;
    }
    return self;
}

- (BOOL)methodCanBeForwardedToCustomDelegate:(SEL)aSelector {
    BOOL methodInProtocol = protocol_getMethodDescription(@protocol(XTCoverFlowDelegate), aSelector, NO, YES).name != NULL;
    return methodInProtocol && [self.customDelegate respondsToSelector:aSelector];
}

- (void)setDelegate:(id<XTCoverFlowDelegate>)delegate {
    self.customDelegate = (delegate == self? nil : delegate);
    if(self.superview != nil){
        super.delegate = self;
    }
}

- (id<XTCoverFlowDelegate>)delegate {
    return self.customDelegate;
}

@end

@implementation XTCoverFlowFlatRender

- (instancetype)initWithCoverFlow:(XTCoverFlow *)coverFlow {
    self = [super init];
    if (self) {
        self.coverFlow = coverFlow;
    }
    return self;
}

- (void)render {
    // For now, draw all views
    NSUInteger page = 0;
    while ([self.coverFlow viewForItem:page++]) YES;
}

- (CGFloat)pageWidth {
    return self.itemWidth + self.itemMargin * 2;
}

- (CGSize)contentSizeForPageCount:(NSUInteger)pageCount {
    return CGSizeMake(pageCount * self.pageWidth, self.coverFlow.bounds.size.height);
}

- (void)layoutPage:(UIView *)page atIndex:(NSUInteger)index {
    CGRect frame = page.frame;
    frame.origin = CGPointMake(self.itemMargin + index * self.pageWidth, roundf((self.coverFlow.bounds.size.height - frame.size.height) / 2));
    page.frame = frame;
}

@end

@implementation XTCoverFlow3DRender

- (instancetype)initWithCoverFlow:(XTCoverFlow *)coverFlow {
    self = [super init];
    if (self) {
        self.coverFlow = coverFlow;
        self.itemSeparation = 30;
        self.itemScale = 0.6;
    }
    return self;
}

- (void)render {
    XTCoverFlow *coverFlow = self.coverFlow;    
    CGFloat currentPage = [coverFlow currentPage];

    // For every view
    for (int page = 0; ; page++) {
        UIView *view = [coverFlow viewForItem:page];
        if (!view) break;
        
        CGFloat pageDistance = page - currentPage;
        CGFloat normalizedPageDistance = MAX(MIN(pageDistance, 1), -1);
        
        // Move page to center of screen with some padding depending on item separation
        CGFloat x = (currentPage - page) * (self.pageWidth - self.itemSeparation);
        
        // Add space for center element
        x +=  normalizedPageDistance * self.pageWidth / 2;
        
        CATransform3D translateTransform = CATransform3DTranslate(CATransform3DIdentity, x, 0, fabsf(pageDistance) * -1000);
        
        // Rotate
        CATransform3D rotateTransform = CATransform3DIdentity;
        rotateTransform.m34 = 1.0 / 500;
        rotateTransform = CATransform3DRotate(rotateTransform, normalizedPageDistance, 0, 1, 0);
        
        // Scale
        CGFloat scale = 1 - fabs(normalizedPageDistance) * (1 - self.itemScale);
        CATransform3D scaleTransform = CATransform3DMakeScale(scale, scale, 1);
        
        // Apply transform
        view.layer.transform = CATransform3DConcat(scaleTransform, CATransform3DConcat(rotateTransform ,translateTransform));
    }
}

- (CGFloat)pageWidth {
    return self.coverFlow.frame.size.width * 0.4;
}

- (CGSize)contentSizeForPageCount:(NSUInteger)pageCount {
    return CGSizeMake((pageCount - 1) * self.pageWidth + self.coverFlow.bounds.size.width, self.coverFlow.bounds.size.height);
}

- (void)layoutPage:(UIView *)page atIndex:(NSUInteger)index {
    page.center = CGPointMake(index * self.pageWidth + self.coverFlow.center.x, self.coverFlow.center.y);
}

@end
