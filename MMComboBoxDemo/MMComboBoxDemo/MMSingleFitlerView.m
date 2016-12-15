//
//  MMSingleFitlerView.m
//  MMComboBoxDemo
//
//  Created by wyy on 2016/12/8.
//  Copyright © 2016年 wyy. All rights reserved.
//

#import "MMSingleFitlerView.h"
#import "MMHeader.h"
#import "MMNormalCell.h"
#import "MMSelectedPath.h"

@interface MMSingleFitlerView ()
@property (nonatomic, assign) BOOL isSuccessfulToCallBack;
@property (nonatomic, strong) UIView *bottomView;
@end
@implementation MMSingleFitlerView
- (id)initWithItem:(MMItem *)item{
    self = [super init];
    if (self) {
        self.item = item;
        self.selectedArray = [NSMutableArray array];
        
        for (int i = 0; i < self.item.childrenNodes.count; i++) {
            MMItem *subItem = item.childrenNodes[i];
            if (subItem.isSelected == YES){
                MMSelectedPath *path = [[MMSelectedPath alloc] init];
                path.firstPath = i;
                [self.selectedArray addObject:path];
            }
        }
        self.temporaryArray= [[NSArray alloc] initWithArray:self.selectedArray copyItems:YES] ;
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)popupViewFromSourceFrame:(CGRect)frame {
    UIView *rootView = [[UIApplication sharedApplication] keyWindow];
    self.sourceFrame = frame;
    CGFloat top =  CGRectGetMaxY(self.sourceFrame);
    CGFloat maxHeight = kScreenHeigth - DistanceBeteewnPopupViewAndBottom - top - PopupViewTabBarHeight;
    CGFloat resultHeight = MIN(maxHeight, self.item.childrenNodes.count * PopupViewRowHeight);
    self.frame = CGRectMake(0, top, kScreenWidth, 0);
     [rootView addSubview:self];
   
    //addSubView
    self.shadowView.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeigth - top);
    self.shadowView.alpha = 0.0;
    [self addSubview:self.shadowView];
    
    self.mainTableView = [[UITableView alloc] initWithFrame:self.bounds style:UITableViewStylePlain];
    self.mainTableView.rowHeight = PopupViewRowHeight;

    self.mainTableView.delegate = self;
    self.mainTableView.dataSource = self;
    [self.mainTableView registerClass:[MMNormalCell class] forCellReuseIdentifier:MainCellID];
    [self addSubview:self.mainTableView];
    
    //出现的动画
    [UIView animateWithDuration:AnimationDuration animations:^{
        self.frame = CGRectMake(0, top, kScreenWidth, resultHeight);
        self.mainTableView.frame = self.bounds;
        self.shadowView.alpha = .3;
    } completion:^(BOOL finished) {
        if (self.item.selectedType == MMPopupViewSingleSelection) return ;
        self.height += PopupViewTabBarHeight;
        self.bottomView = [[UIView alloc] init];
        self.bottomView.backgroundColor = [UIColor whiteColor];
        self.bottomView.frame = CGRectMake(0, self.mainTableView.bottom, self.width, PopupViewTabBarHeight);
        [self addSubview:self.bottomView];
        
        NSArray *titleArray = @[@"取消",@"确定"];
        for (int i = 0; i < 2 ; i++) {
            CGFloat left = ((i == 0)?ButtonHorizontalMargin:self.width - ButtonHorizontalMargin - 100);
            UIColor *titleColor = ((i == 0)?[UIColor blackColor]:[UIColor colorWithHexString:titleSelectedColor]);
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.frame = CGRectMake(left, 0, 100, PopupViewTabBarHeight);
            button.tag = i;
            [button setTitle:titleArray[i] forState:UIControlStateNormal];
            [button setTitleColor:titleColor forState:UIControlStateNormal];
            button.titleLabel.font = [UIFont systemFontOfSize:ButtonFontSize];
            [button addTarget:self action:@selector(respondsToButtonAction:) forControlEvents:UIControlEventTouchUpInside];
            [self.bottomView addSubview:button];
        }
        
    }];
}

- (void)dismiss{
    [self _resetValue];
    
    if ([self.delegate respondsToSelector:@selector(popupViewWillDismiss:)]) {
        [self.delegate popupViewWillDismiss:self];
    }
    
    if (self.item.selectedType == MMPopupViewMultilSeMultiSelection) {
        self.bottomView.hidden = YES;   
    }
 
    CGFloat top =  CGRectGetMaxY(self.sourceFrame);
    //消失的动画
    [UIView animateWithDuration:AnimationDuration animations:^{
        self.frame = CGRectMake(0, top, kScreenWidth, 0);
        self.mainTableView.frame = self.bounds;
        self.shadowView.alpha = 0.0;
    } completion:^(BOOL finished) {
        if (self.superview) {
         [self removeFromSuperview];
        }
    }];
}

- (void)callBackDelegate {
    if ([self.delegate respondsToSelector:@selector(popupView:didSelectedItemsPackagingInArray:atIndex:)]) {
        [self.delegate popupView:self didSelectedItemsPackagingInArray:self.selectedArray  atIndex:self.tag];
        [self.mainTableView reloadData];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self dismiss];
                });
    }
}
#pragma mark - Private Method
- (void)_resetValue{
    //恢复成以前的值
    if (self.isSuccessfulToCallBack == NO) {
        for (MMItem *item in self.item.childrenNodes) {
            item.isSelected = NO;
        }
        for (MMSelectedPath *path in self.temporaryArray) {
            self.item.childrenNodes[path.firstPath].isSelected = YES;
        }
    }
}

- (BOOL)_iscontainsSelectedPath:(MMSelectedPath *)path sourceArray:(NSMutableArray *)array{
    for (MMSelectedPath *selectedpath in array) {
        if (selectedpath.firstPath == path.firstPath ) return YES;
    }
    return NO;
}

- (void)_removePath:(MMSelectedPath *)path sourceArray:(NSMutableArray *)array {
    for (MMSelectedPath *selectedpath in array) {
        if (selectedpath.firstPath == path.firstPath ) {
            [array removeObject:selectedpath];
            return;
        }
    }
}
#pragma mark - Action
- (void)respondsToButtonAction:(UIButton *)sender{
    if (sender.tag == 0) {//取消
      [self dismiss];
    } else if (sender.tag == 1) {//确定
    self.isSuccessfulToCallBack = YES;
    [self callBackDelegate];
    }
}
#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.item.childrenNodes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MMNormalCell *cell = [tableView dequeueReusableCellWithIdentifier:MainCellID forIndexPath:indexPath];
    MMItem *item = self.item.childrenNodes[indexPath.row];
    cell.item = item;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.item.selectedType == MMPopupViewMultilSeMultiSelection) { //多选
        if ([self _iscontainsSelectedPath:[MMSelectedPath pathWithFirstPath:indexPath.row] sourceArray:self.selectedArray]) {
            [self _removePath:[MMSelectedPath pathWithFirstPath:indexPath.row] sourceArray:self.selectedArray];
            self.item.childrenNodes[indexPath.row].isSelected = NO;
        }else {
            [self.selectedArray addObject:[MMSelectedPath pathWithFirstPath:indexPath.row]];
            self.item.childrenNodes[indexPath.row].isSelected = YES;
        }
      [self.mainTableView reloadData];
    }else if (self.item.selectedType == MMPopupViewSingleSelection) { //单选
        //如果点击的已经选中的直接返回
        if ([self _iscontainsSelectedPath:[MMSelectedPath pathWithFirstPath:indexPath.row] sourceArray:self.selectedArray]) return;
           //remove
            MMSelectedPath *lastSelectedPath = self.selectedArray[0] ;
            self.item.childrenNodes[lastSelectedPath.firstPath].isSelected = NO;
            [self.selectedArray removeLastObject];
           //add
            self.item.childrenNodes[indexPath.row].isSelected = YES;
            [self.selectedArray addObject:[MMSelectedPath pathWithFirstPath:indexPath.row]];
        
            [self callBackDelegate];
    }
}


@end
