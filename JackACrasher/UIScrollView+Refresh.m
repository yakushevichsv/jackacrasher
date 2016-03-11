//
//  FPTableView.m
//  PullToRefresh
//
//  Created by Kirill Zuev on 27.05.13.
//  Copyright (c) 2013 Kirill Zuev. All rights reserved.
//

#import "UIScrollView+Refresh.h"
#import <objc/runtime.h>

@implementation UIScrollView (Refresh)

- (void)initRefresh
{
    if (self.refreshActivityIndicator.superview)
        return;
    
    self.refreshing = NO;
    self.needRefreshing = NO;
        
    UIActivityIndicatorView *aiView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    aiView.tintColor = [UIColor blackColor];
    
    UIFont *font = [UIFont fontWithName:@"OpenSans-Semibold" size:13.0f];
    
    UILabel *label = [[UILabel alloc] init];
    label.text =  NSLocalizedString(@"Pull to update", "");
    label.font = font;
    label.textColor = [UIColor grayColor];
    label.backgroundColor = [UIColor clearColor];
    [label sizeToFit];
    
    UIImageView *arrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pull_to_refresh"] highlightedImage:[UIImage imageNamed:@"release_to_refresh"]];
    
    [self addSubview:aiView];
    [self addSubview:label];
    [self addSubview:arrowImageView];
    aiView.hidden = false;
    
    self.refreshActivityIndicator = aiView;
    self.arrowImageView = arrowImageView;
    self.pullLabel = label;
    
    if (![self isContentOffsetObserved]) {
        [self addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:NULL];
        [self contentOffsetObserved:YES];
    }
    
    [self position];
}

- (void)position
{
    self.refreshActivityIndicator.center = CGPointMake(self.frame.size.width / 2, -50);
    [self.pullLabel sizeToFit];
    self.pullLabel.center = CGPointMake(self.frame.size.width / 2, -15);
    CGRect frame = self.arrowImageView.frame;
    frame.origin = CGPointMake(self.pullLabel.frame.origin.x - 20, self.pullLabel.frame.origin.y + 5);
    self.arrowImageView.frame = frame;
}

- (void)updatePullLabelTextForCoordinate:(CGPoint)offset
{
    if (offset.y < - 80) {
        self.pullLabel.text = NSLocalizedString(@"Release to update", "");
        [self.pullLabel sizeToFit];
        self.arrowImageView.highlighted = YES;
    } else {
        self.pullLabel.text = NSLocalizedString(@"Pull to update", "");
        [self.pullLabel sizeToFit];
        self.arrowImageView.highlighted = NO;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    CGPoint offset = [change[NSKeyValueChangeNewKey] CGPointValue];
    [self updatePullLabelTextForCoordinate:offset];
    [self position];
    if (offset.y < - 80) {
        self.needRefreshing = YES;
    } else {
        if (self.isDragging) {
            self.needRefreshing = NO;
        } else {
            if (self.needRefreshing) {
                if (!self.refreshing) {
                    self.refreshing = YES;
                    self.contentInset = UIEdgeInsetsMake(80, 0, 0, 0);
                    [self.refreshActivityIndicator startAnimating];
                    self.refreshActivityIndicator.hidden = NO;
                    if ([self.delegate respondsToSelector:@selector(beginRefreshing)]) {
                        [(id)self.delegate beginRefreshing];
                    }
                }
            }
        }
    }
}


- (void)endRefreshing
{
    __weak typeof(self) wSelf = self;
    [UIView animateWithDuration:0.3 animations:^{
        wSelf.contentInset = UIEdgeInsetsZero;
    } completion:^(BOOL finished) {
        wSelf.refreshing = NO;
        wSelf.needRefreshing = NO;
        [wSelf.refreshActivityIndicator stopAnimating];
    }];
}

- (void)unload
{
    [self.refreshActivityIndicator removeFromSuperview];
    [self.pullLabel removeFromSuperview];
    [self.arrowImageView removeFromSuperview];
    
    self.refreshActivityIndicator = nil;
    self.pullLabel = nil;
    self.arrowImageView = nil;
    
    if ([self isContentOffsetObserved]) {
        [self removeObserver:self forKeyPath:@"contentOffset"];
        [self contentOffsetObserved:NO];
    }
}

#pragma mark

- (void)contentOffsetObserved:(BOOL)observing
{
    objc_setAssociatedObject(self, @selector(contentOffsetObserved:), observing ? @(observing) : nil, OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)isContentOffsetObserved
{
    return  [objc_getAssociatedObject(self, @selector(contentOffsetObserved:)) boolValue];
}

- (void)setRefreshActivityIndicator:(UIActivityIndicatorView *)refreshActivityIndicator
{
    objc_setAssociatedObject(self, @selector(setRefreshActivityIndicator:), refreshActivityIndicator, OBJC_ASSOCIATION_ASSIGN);
}

- (UIActivityIndicatorView*)refreshActivityIndicator
{
    return objc_getAssociatedObject(self, @selector(setRefreshActivityIndicator:));
}


- (void)setArrowImageView:(UIImageView*)arrowImageView
{
    objc_setAssociatedObject(self, @selector(setArrowImageView:), arrowImageView, OBJC_ASSOCIATION_ASSIGN);
}

- (UIImageView*)arrowImageView
{
    return objc_getAssociatedObject(self, @selector(setArrowImageView:));
}


- (void)setRefreshing:(BOOL)refreshing
{
    objc_setAssociatedObject(self, @selector(setRefreshing:), refreshing ? @(refreshing) : nil, OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)refreshing
{
    return [objc_getAssociatedObject(self, @selector(setRefreshing:)) boolValue];
}


- (void)setNeedRefreshing:(BOOL)needRefreshing
{
    objc_setAssociatedObject(self, @selector(setNeedRefreshing:),needRefreshing ? @(needRefreshing) : nil, OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)needRefreshing
{
    return [objc_getAssociatedObject(self, @selector(setNeedRefreshing:)) boolValue];
}


- (void)setPullLabel:(UILabel*)pullLabel
{
    objc_setAssociatedObject(self, @selector(setPullLabel:), pullLabel, OBJC_ASSOCIATION_ASSIGN);
}

- (UILabel*)pullLabel
{
    return objc_getAssociatedObject(self, @selector(setPullLabel:));
}

@end
