//
//  TimeSelectViewController.h
//  TimeSelectPickerView
//
//  Created by DayHR on 2016/12/21.
//  Copyright © 2016年 lisiye. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TimeSelectViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *startTimeB;
@property (weak, nonatomic) IBOutlet UIButton *endTimeB;
@property (weak, nonatomic) IBOutlet UILabel *startLabel;
@property (weak, nonatomic) IBOutlet UILabel *endLabel;
@property (weak, nonatomic) IBOutlet UIButton *chekButton;//验证按钮
//显示结果
@property (weak, nonatomic) IBOutlet UITextField *showResult;

@end
