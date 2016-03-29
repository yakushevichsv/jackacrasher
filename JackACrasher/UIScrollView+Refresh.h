//
//  FPTableView.h
//  PullToRefresh
//
//  Created by Kirill Zuev on 27.05.13.
//  Copyright (c) 2013 Kirill Zuev. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 Класс табличного представления с функцией Pull to refresh
 
 Для получения извещения о начале обновления, делегат табличного представления должен реализовывать метод `- (void)beginRefreshing`
 */

@interface UIScrollView (Refresh)

@property (nonatomic, weak) UIActivityIndicatorView *refreshActivityIndicator;
@property (nonatomic, weak) UIImageView *arrowImageView;
@property (nonatomic, weak) UILabel *pullLabel;

@property (nonatomic) BOOL refreshing;
@property (nonatomic) BOOL needRefreshing;

- (void)initRefresh;
/**
 Завершает показ индикатора обновления.
 */
- (void)endRefreshing;
- (void)unload;

@end
