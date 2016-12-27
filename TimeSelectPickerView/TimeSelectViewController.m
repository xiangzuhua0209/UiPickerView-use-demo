//
//  TimeSelectViewController.m
//  TimeSelectPickerView
//
//  Created by DayHR on 2016/12/21.
//  Copyright © 2016年 lisiye. All rights reserved.
//

#import "TimeSelectViewController.h"

@interface TimeSelectViewController ()<UIPickerViewDelegate,UIPickerViewDataSource>
@property(nonatomic,strong)UIPickerView * pickerView;//选择器
@property(nonatomic,assign)float pickerViewHeight;//选择器的高度
@property(nonatomic,strong)UIView * coverView;//蒙版
@property(nonatomic,strong)NSMutableArray *pickerViewDataArr;//存储常规的日期数据分五个数组
@property(nonatomic,strong)NSMutableArray *nowPickerViewDataArr;//存储当前时间数组
@property(nonatomic,assign)NSInteger selectRow0;//第一例选择的行数
@property(nonatomic,assign)NSInteger selectRow1;//第一例选择的行数
@property(nonatomic,assign)NSInteger selectRow2;//第一例选择的行数
@property(nonatomic,assign)NSInteger selectRow3;//第一例选择的行数
@property(nonatomic,assign)NSInteger selectRow4;//第一例选择的行数
@property(nonatomic,assign)NSInteger defaultYear;//当前时间年
@property(nonatomic,assign)NSInteger defaultMonth;//当前时间月
@property(nonatomic,assign)NSInteger defaultDay;//当前时间日
@property(nonatomic,assign)NSInteger defaultHour;//当前时间时
@property(nonatomic,assign)NSInteger defaultMinute;//当前时间分
@property(nonatomic,strong)UIView * pickerBackView;//时间选择器的背景视图
@property(nonatomic,assign)NSInteger selectedB;//记录是选择开始还是结束时间按钮 0 为没有   1为开始时间 2为结束时间
@property(nonatomic,strong)NSTimer * timer;//定时器  一分钟加载一次时间选择器的数据，并刷新
@end
//当前设备的屏幕宽度
#define kScreenWidth [UIScreen mainScreen].bounds.size.width
//当前设备的屏幕高度
#define kScreenHeight [UIScreen mainScreen].bounds.size.height
@implementation TimeSelectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initObject];
    [self getData];
    [self initView];
}
#pragma mark -- 初始化对象
-(void)initObject{
    self.selectRow0 =0;
    self.selectRow1 =0;
    self.selectRow2 = 0;
    self.selectRow3 = 0;
    self.selectRow4 = 0;
    self.selectedB = 0;
    //初始化定时器
    self.timer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(timerAction:) userInfo:nil repeats:YES];
}
#pragma mark -- 获取数据
-(void)getData{
    /*
     获取时间数据分为两种情况，一种是常规数据，如一个月28/29/30/31天，一天24小时,一小时60分钟等，这个数据很好获取
     另一种情况是当前的数据，当前时间数据比较复杂，前提条件：分钟只需要取10钟一间隔得数据即：0、10、20、30、40、50，这样获取数据的时候需要在当前时间加10分钟，这样的话 在50~59分，小时数据是没有当前的小时值可选的；在23时50~59分，当前天数是不可选的；在每月的最后一天和每年的最后一天都有类似的特殊情况，同时需要每个一分钟更新一次当前的时间的数据
     */
    //在当前时间加10分钟，然后获取年月日时分的值
    NSDate * date = [NSDate dateWithTimeIntervalSinceNow:60*10];//提前10分钟
    NSCalendar * canlendar = [NSCalendar currentCalendar];
    NSInteger unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents * components = [canlendar components:unitFlags fromDate:date];
    NSInteger nowY = [components year];
    NSInteger nowM = [components month];
    NSInteger nowD = [components day];
    NSInteger nowH = [components hour];
    NSInteger nowF = [components minute];
    //给当前值赋值--这些值主要是用于时间选择器的第一次打开时显示当前时间
    self.defaultYear = [components year];
    self.defaultMonth = [components month];
    self.defaultDay = [components day];
    self.defaultHour = [components hour];
    NSLog(@"%ld",[components minute]);
    self.defaultMinute = ([components minute]/10)*10 ;
    //获取当前月的天数
    NSRange range = [canlendar rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:date];
    NSUInteger numberOfDaysInMonth = range.length;
    NSMutableArray * nowPickerViewDataArr0 = [[NSMutableArray alloc] init];
    NSMutableArray * nowPickerViewDataArr1 = [[NSMutableArray alloc] init];
    NSMutableArray * nowPickerViewDataArr2 = [[NSMutableArray alloc] init];
    NSMutableArray * nowPickerViewDataArr3 = [[NSMutableArray alloc] init];
    NSMutableArray * nowPickerViewDataArr4 = [[NSMutableArray alloc] init];
    //获取当前分钟数
    if (nowF >= 50) {//大于50分到59之间分钟数需要特殊处理
        self.defaultMinute = 0;
        self.defaultHour+=1;
        if (self.defaultHour == 24) {
            self.defaultHour = 0;
        }
        for (int i = 0; i < 6; i++) {
            [nowPickerViewDataArr4 addObject:[NSNumber numberWithInteger:i*10]];
        }
    }else{//小于50分，则只获取当前可选的分钟值
        for (NSInteger i = self.defaultMinute/10; i < 6; i++) {
            [nowPickerViewDataArr4 addObject:[NSNumber numberWithInteger:i*10]];
        }
    }
    //获取当前小时数
    if (nowH >= 23&&nowH>=50) {//23点50分到59之间，当前小时数需要特殊处理
        self.defaultHour+=1;
        self.defaultDay+=1;
        if (self.defaultDay >numberOfDaysInMonth) {
            self.defaultDay = 1;
        }
        for (int i = 0; i < 24; i++) {
            [nowPickerViewDataArr3 addObject:[NSNumber numberWithInteger:i]];
        }
    }else{//
        for (NSInteger i = self.defaultHour; i < 24; i++) {
            [nowPickerViewDataArr3 addObject:[NSNumber numberWithInteger:i]];
        }
    }
    //获取当前日数
    if (nowD >= numberOfDaysInMonth&&nowH >= 23&&nowH>=50) {//每月最后一天23点50分到59之间，当前小时数需要特殊处理
        self.defaultDay+=1;
        self.defaultMonth+=1;
        if (self.defaultMonth >12) {
            self.defaultMonth = 1;
        }
        for (int i = 1; i <= numberOfDaysInMonth; i++) {
            [nowPickerViewDataArr2 addObject:[NSNumber numberWithInteger:i]];
        }
    }else{//
        for (NSInteger i = self.defaultDay; i <= numberOfDaysInMonth; i++) {
            [nowPickerViewDataArr2 addObject:[NSNumber numberWithInteger:i]];
        }
    }
    //获取当前月份数
    if (nowM >= 12&&nowD >= numberOfDaysInMonth&&nowH >= 23&&nowH>=50) {//每年12月最后一天23点50分到59之间，当前小时数需要特殊处理
        self.defaultMonth+=1;
        self.defaultYear+=1;
        if (self.defaultYear >nowY) {
            self.defaultYear = nowY+1;
        }
        for (int i = 1; i <= 12; i++) {
            [nowPickerViewDataArr1 addObject:[NSNumber numberWithInteger:i]];
        }
    }else{//
        for (NSInteger i = self.defaultMonth; i <= 12; i++) {
            [nowPickerViewDataArr1 addObject:[NSNumber numberWithInteger:i]];
        }
    }
    //获取年份
    for (int i = 0; i < 3; i++) {
        [nowPickerViewDataArr0 addObject:[NSNumber numberWithInteger:i+self.defaultYear]];
    }
    //将当前时间的数据存到数组
    [self.nowPickerViewDataArr addObject:nowPickerViewDataArr0];
    [self.nowPickerViewDataArr addObject:nowPickerViewDataArr1];
    [self.nowPickerViewDataArr addObject:nowPickerViewDataArr2];
    [self.nowPickerViewDataArr addObject:nowPickerViewDataArr3];
    [self.nowPickerViewDataArr addObject:nowPickerViewDataArr4];
    //获取常规数值
    NSMutableArray * pickerViewDataArr1 = [[NSMutableArray alloc] init];
    NSMutableArray * pickerViewDataArr2 = [[NSMutableArray alloc] init];
    NSMutableArray * pickerViewDataArr3 = [[NSMutableArray alloc] init];
    NSMutableArray * pickerViewDataArr4 = [[NSMutableArray alloc] init];
    //分钟
    for (int i = 0; i < 6; i++) {
        [pickerViewDataArr4 addObject:[NSNumber numberWithInteger:i*10]];
    }
    //小时
    for (NSInteger i = 0; i < 24; i++) {
        [pickerViewDataArr3 addObject:[NSNumber numberWithInteger:i]];
    }
    //天数
    for (NSInteger i = 1; i <= numberOfDaysInMonth; i++) {
        [pickerViewDataArr2 addObject:[NSNumber numberWithInteger:i]];
    }
    //月数
    for (NSInteger i = 1; i <= 12; i++) {
        [pickerViewDataArr1 addObject:[NSNumber numberWithInteger:i]];
    }
    [self.pickerViewDataArr addObject:nowPickerViewDataArr0];
    [self.pickerViewDataArr addObject:pickerViewDataArr1];
    [self.pickerViewDataArr addObject:pickerViewDataArr2];
    [self.pickerViewDataArr addObject:pickerViewDataArr3];
    [self.pickerViewDataArr addObject:pickerViewDataArr4];
}
#pragma mark -- 初始化视图
-(void)initView{
    //起止时间框
    self.startTimeB.layer.cornerRadius = 3;
    self.endTimeB.layer.cornerRadius = 3;
    self.startTimeB.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    self.endTimeB.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    //验证按钮
    self.chekButton.layer.cornerRadius = 3;
    //时间选择器及按钮
    //根据手机的尺寸确定时间选择器的高度
    if (kScreenHeight ==736 ) {//7p
        self.pickerViewHeight = 216;
    } else if(kScreenHeight == 667){//7
        self.pickerViewHeight = 180;
    }else{//se
        self.pickerViewHeight = 162;
    }
    //添加时间选择器的背景视图
    self.pickerBackView = [[UIView alloc] initWithFrame:CGRectMake(0, kScreenHeight, kScreenWidth, self.pickerViewHeight+30)];
    [self.view addSubview:self.pickerBackView];
    //添加取消按钮
    UIButton * cancelButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
    [cancelButton setFrame:CGRectMake(0, 0, 50, 30)];
    [cancelButton setTitle:@"取消" forState:(UIControlStateNormal)];
    [cancelButton setTitleColor:[UIColor blackColor] forState:(UIControlStateNormal)];
    cancelButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [cancelButton addTarget:self action:@selector(cancelButtonAction1:) forControlEvents:(UIControlEventTouchUpInside)];
    [self.pickerBackView addSubview:cancelButton];
    //添加确认按钮
    UIButton * sureButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
    [sureButton setFrame:CGRectMake(kScreenWidth - 50, 0, 50, 30)];
    [sureButton setTitle:@"确定" forState:(UIControlStateNormal)];
    [sureButton setTitleColor:[UIColor blackColor] forState:(UIControlStateNormal)];
    sureButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [sureButton addTarget:self action:@selector(sureButtonAction1:) forControlEvents:(UIControlEventTouchUpInside)];
    [self.pickerBackView addSubview:sureButton];
    self.pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 30, kScreenWidth, self.pickerViewHeight)];
    self.pickerBackView.backgroundColor = [UIColor whiteColor];
    [self.pickerBackView addSubview:self.pickerView];
    self.pickerView.delegate = self;
    self.pickerView.dataSource = self;
    //在时间选择器上天机年月日时分
    NSArray * labelArr = @[@"年",@"月",@"日",@"时",@"分"];
    for (int i = 0; i < 5; i++) {
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(kScreenWidth/5*(i+1) - 20, self.pickerViewHeight/2-15, 20, 30)];
        label.text = labelArr[i];
        label.font = [UIFont systemFontOfSize:15];
        label.textColor = [UIColor blackColor];
        [self.pickerView addSubview:label];
    }
}
#pragma mark -- 代理方法
#pragma mark -- UIPickerViewDelegate
-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    if (component == 0) {
        return [self.nowPickerViewDataArr[0] count];
    } else if(component == 1){
        if (self.selectRow0 == 0) {
            return [self.nowPickerViewDataArr[1] count];
        } else {
            return [self.pickerViewDataArr[1] count];
        }
    }else if (component ==2){
        if (self.selectRow0 == 0&&self.selectRow1 == 0) {
            return [self.nowPickerViewDataArr[2] count];
        } else {
            return [self.pickerViewDataArr[2] count];
        }
    }else if (component == 3){
        if (self.selectRow2 == 0&&self.selectRow1 == 0&&self.selectRow0 == 0) {
            return [self.nowPickerViewDataArr[3] count];
        } else {
            return [self.pickerViewDataArr[3] count];
        }
    }else{
        if (self.selectRow3 ==0&&self.selectRow2 == 0&&self.selectRow1 == 0&&self.selectRow0 == 0) {
            return [self.nowPickerViewDataArr[4] count];
        } else {
            return [self.pickerViewDataArr[4] count];
        }
    }
}
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 5;
}
-(CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component{
    return kScreenWidth/5;
}
-(CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component{
    return 30;
}
-(UIView*)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    //添加一个label
    UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth/5, 30)];
    label.textColor = [UIColor grayColor];
    label.font = [UIFont systemFontOfSize:15];
    label.textAlignment = NSTextAlignmentLeft;
    //对每一列都需要做特殊和非特殊的判断，一遍给到正确的值
    if (component == 0) {
        label.text = [NSString stringWithFormat:@"%@",self.nowPickerViewDataArr[0][row]];
    } else if(component == 1){
        if (self.selectRow0 == 0) {
            label.text = [NSString stringWithFormat:@"%@",self.nowPickerViewDataArr[1][row]];
        } else {
            label.text = [NSString stringWithFormat:@"%@",self.pickerViewDataArr[1][row]];
        }
    }else if (component ==2){
        if (self.selectRow0 == 0&&self.selectRow1 == 0) {
            label.text = [NSString stringWithFormat:@"%@",self.nowPickerViewDataArr[2][row]];
        } else {
            label.text = [NSString stringWithFormat:@"%@",self.pickerViewDataArr[2][row]];
        }
    }else if (component == 3){
        if (self.selectRow2 == 0&&self.selectRow1 == 0&&self.selectRow0 == 0) {
            label.text = [NSString stringWithFormat:@"%@",self.nowPickerViewDataArr[3][row]];
        } else {
            label.text = [NSString stringWithFormat:@"%@",self.pickerViewDataArr[3][row]];
        }
    }else{
        if (self.selectRow3 ==0&&self.selectRow2 == 0&&self.selectRow1 == 0&&self.selectRow0 == 0) {
            label.text = [NSString stringWithFormat:@"%@",self.nowPickerViewDataArr[4][row]];
        } else {
            label.text = [NSString stringWithFormat:@"%@",self.pickerViewDataArr[4][row]];
        }
    }
    return label;
}
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    
    //获取选中的列数
    self.selectRow0 = [pickerView selectedRowInComponent:0];
    self.selectRow1 = [pickerView selectedRowInComponent:1];
    self.selectRow2 = [pickerView selectedRowInComponent:2];
    self.selectRow3 = [pickerView selectedRowInComponent:3];
    self.selectRow4 = [pickerView selectedRowInComponent:4];
    //先清空之前的数据，在重新获取数据
    self.pickerViewDataArr = nil;
    self.nowPickerViewDataArr = nil;
    [self getData];
    //刷新后面的列
    if (component == 0) {//选择完成后加载后面的列的数据但是不刷新当前列
        [pickerView reloadComponent:1];
        [pickerView reloadComponent:2];
        [pickerView reloadComponent:3];
        [pickerView reloadComponent:4];
    } else if(component == 1){
        [pickerView reloadComponent:2];
        [pickerView reloadComponent:3];
        [pickerView reloadComponent:4];
    }else if(component == 2){
        [pickerView reloadComponent:3];
        [pickerView reloadComponent:4];
    }else if(component == 3){
        [pickerView reloadComponent:4];
    }
}
#pragma mark -- 点击事件
//返回按钮
- (IBAction)backAction:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
//开始时间按钮点击事件
- (IBAction)startTimeBaction:(UIButton *)sender {
    [self addCoverView];
    self.selectedB = 1;
}
//结束时间按钮点击事件
- (IBAction)endTimeBAction:(UIButton *)sender {
    [self addCoverView];
    self.selectedB = 2;
}
//点击空白，恢复界面
-(void)tapAction{
    [self deleteCoverView];
}
//点击时间选择器上面的取消和确认按钮
-(void)cancelButtonAction1:(UIButton*)sender{
    //恢复界面
    [self deleteCoverView];
}
-(void)sureButtonAction1:(UIButton*)sender{
    
    //改变按钮的文字--先获取到数据,再拼接，再赋值
    NSString * timeString = @"";
    for (int i =0; i < 5; i++) {
        NSInteger temprow = [self.pickerView selectedRowInComponent:i];
        UILabel * templable = (UILabel*)[self.pickerView viewForRow:temprow forComponent:i];
        //个位数的加零
        NSInteger value = [templable.text integerValue];
        NSString * tempString;
        if (value < 10&&i>0) {
            tempString = [NSString stringWithFormat:@"0%ld",value];
        }else{
            tempString = [NSString stringWithFormat:@"%ld",value];
        }
        if (i== 0) {
            timeString = tempString;
        }else if(i == 1||i == 2){
            timeString = [timeString stringByAppendingString:[NSString stringWithFormat:@"-%@",tempString]];
        }else if(i == 3){
            timeString = [timeString stringByAppendingString:[NSString stringWithFormat:@" %@",tempString]];
        }else{
            timeString = [timeString stringByAppendingString:[NSString stringWithFormat:@":%@",tempString]];
        }
    }
    //判断是选择哪个时间按钮
    if (self.selectedB == 1) {//开始按钮
        self.startLabel.text = timeString;
    }else{//结束按钮
        self.endLabel.text = timeString;
    }
    //恢复界面
    [self deleteCoverView];
}
//验证时间按钮
- (IBAction)checkButtonAction:(UIButton *)sender {
    //判断两个时间是否都有
    if ([self.startLabel.text isEqualToString:@"请选择开始时间"]) {
        self.showResult.text = @"请选择开始时间";
        return;
    }
    if ([self.endLabel.text isEqualToString:@"请选择结束时间"]) {
        self.showResult.text = @"请选择结束时间";
        return;
    }
    //获取开始时间的秒数
    NSTimeInterval time1 = [self getTimeIntervalWith:self.startLabel.text];
    //获取结束时间的秒数
    NSTimeInterval time2 = [self getTimeIntervalWith:self.endLabel.text];
    //对比结果  判断然后显示验证结果
    if (time1 < time2) {//时间正确
        self.showResult.text = @"时间选择正确";
    }else{//时间错误
        self.showResult.text = @"结束时间大于或等于开始时间";
    }
}
//定时器触发运行事件
-(void)timerAction:(NSTimer*)sender{
    //清空原来的数据
    self.nowPickerViewDataArr = nil;
    self.pickerViewDataArr = nil;
    //获取数据
    [self getData];
    //刷新列表
    [self.pickerView reloadAllComponents];
}
#pragma mark -- 私有方法
//添加蒙版和显示时间选择器
-(void)addCoverView{
    if (![self.view.subviews containsObject:self.coverView]) {
        self.coverView = [[UIView alloc] initWithFrame:CGRectMake(0,0, kScreenWidth, kScreenHeight)];
        self.coverView.backgroundColor = [UIColor blackColor];
        self.coverView.alpha = 0.3;
        [self.view addSubview:self.coverView];
        UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
        [self.coverView addGestureRecognizer:tap];
    }
    [UIView animateWithDuration:0.4 animations:^{
        CGRect fram = self.pickerBackView.frame;
        fram.origin.y = kScreenHeight - self.pickerViewHeight-30;
        self.pickerBackView.frame = fram;
    }];
    [self.view insertSubview:self.pickerBackView aboveSubview:self.coverView];
    //pickerView显示今天的时间
    [self showTodayDate];
}
//删除蒙版、隐藏时间选择器、按钮行回复图标和文字颜色
-(void)deleteCoverView{
    //删除蒙版
    if ([self.view.subviews containsObject:self.coverView]) {
        [self.coverView removeFromSuperview];
    }
    if ([self.view.subviews containsObject:self.pickerView]) {
        [self.pickerView removeFromSuperview];
    }
    //隐藏时间选择器
    [UIView animateWithDuration:0.4 animations:^{
        CGRect frame = self.pickerBackView.frame;
        frame.origin.y = kScreenHeight;
        self.pickerBackView.frame = frame;
    }];
    //恢复选择按钮标识
    self.selectedB = 0;
}
//获取指定年月的天数
- (NSMutableArray*)howManyDaysInThisYear:(NSInteger)year month:(NSInteger)imonth {
    NSInteger count = 0;
    NSMutableArray * dayArr = [[NSMutableArray alloc] init];
    if((imonth == 1)||(imonth == 3)||(imonth == 5)||(imonth == 7)||(imonth == 8)||(imonth == 10)||(imonth == 12)){
        count = 31 ;
    }else if((imonth == 4)||(imonth == 6)||(imonth == 9)||(imonth == 11)){
        count = 30;
    }else{
        //不能被4整除的不是闰年
        if((year%4 == 1)||(year%4 == 2)||(year%4 == 3)) count = 28;
        //能被400和100整除的是闰年
        if(year%400 == 0&&year%100 == 0)count = 29;
        //能被100整除但不能被400整除的不是闰年
        if(year%100 == 0&&year%400 != 0)count = 28;
        //能被4整除，但不能被100整除的是闰年
        if (year%4 == 0&&year%100 != 0)count = 29;
    }
    for (int i = 0; i < count; i++) {
        if (i<9) {
            [dayArr addObject:[NSString stringWithFormat:@"0%d",i+1]];
        } else {
            [dayArr addObject:[NSString stringWithFormat:@"%d",i+1]];
        }
    }
    return dayArr;
}
//显示今天的时间
-(void)showTodayDate{
    //获取今天的年月日在选择器数组中的下标
    NSInteger indxY = [self.nowPickerViewDataArr[0] indexOfObject:[NSNumber numberWithInteger:self.defaultYear]];
    NSInteger indexM = [self.nowPickerViewDataArr[1] indexOfObject:[NSNumber numberWithInteger:self.defaultMonth]];
    NSInteger indexD = [self.nowPickerViewDataArr[2] indexOfObject:[NSNumber numberWithInteger:self.defaultDay]];
    NSInteger indexH = [self.nowPickerViewDataArr[3] indexOfObject:[NSNumber numberWithInteger:self.defaultHour]];
    NSInteger indexMi = [self.nowPickerViewDataArr[4] indexOfObject:[NSNumber numberWithInteger:self.defaultMinute]];

    //pickerView显示当前的日期
    [self.pickerView selectRow:indxY inComponent:0 animated:NO];
    [self.pickerView selectRow:indexM inComponent:1 animated:NO];
    [self.pickerView selectRow:indexD inComponent:2 animated:NO];
    [self.pickerView selectRow:indexH inComponent:3 animated:NO];
    [self.pickerView selectRow:indexMi inComponent:4 animated:NO];
}
//传入字符串：YY-mm-DD hh:MM获取秒数时间戳
-(NSTimeInterval)getTimeIntervalWith:(NSString*)timeString{
    //获取完整的字符串
    NSString * lastStr = [timeString stringByAppendingString:@":00"];
    //获取对应时间格式的NSDate对象
    NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
    [inputFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    [inputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate* inputDate = [inputFormatter dateFromString:lastStr];
    //获取时间戳
    NSTimeInterval timeStamp= [inputDate timeIntervalSince1970];
    return timeStamp;
}
#pragma mark -- 懒加载
-(NSMutableArray *)pickerViewDataArr{
    if (!_pickerViewDataArr) {
        _pickerViewDataArr = [[NSMutableArray alloc] init];
    }
    return _pickerViewDataArr;
}
-(NSMutableArray *)nowPickerViewDataArr{
    if (!_nowPickerViewDataArr) {
        _nowPickerViewDataArr = [[NSMutableArray alloc] init];
    }
    return _nowPickerViewDataArr;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark -- dealloc
-(void)viewWillDisappear:(BOOL)animated{
    [self.timer invalidate];
    self.timer = nil;
}
-(void)viewDidAppear:(BOOL)animated{
    //初始化定时器
    self.timer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(timerAction:) userInfo:nil repeats:YES];
}


@end
