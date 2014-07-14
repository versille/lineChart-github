//
//  LineChartView.m
//  LineChart
//
//  Created by versille on 7/13/14.
//  Copyright (c) 2014 versille. All rights reserved.
//

#import "LineChartView.h"

@interface DotLayer : CAShapeLayer
@property (nonatomic, assign) CGFloat   dotValue;
@property (nonatomic, assign) CGFloat   percentage;
@property (nonatomic, assign) double    startPosition;
@property (nonatomic, assign) double    endPosition;
@property (nonatomic, assign) BOOL      isSelected;
@property (nonatomic, strong) NSString  *text;
@property (nonatomic, strong) UILabel   *barLabel;
- (void)createArcAnimationForKey:(NSString *)key fromValue:(NSNumber *)from toValue:(NSNumber *)to timing:(CFTimeInterval)duration Delegate:(id)delegate;
@end

@implementation DotLayer
- (NSString*)description
{
    return [NSString stringWithFormat:@"calorie:%f, percentage:%0.0f, start:%f, end:%f", _dotValue, _percentage, _startPosition/M_PI*180, _endPosition/M_PI*180];
}
+ (BOOL)needsDisplayForKey:(NSString *)key
{
    if ([key isEqualToString:@"strokeEnd"] || [key isEqualToString:@"strokeStart"]) {
        return YES;
    }
    else {
        return NO;
    }
}
- (id)initWithLayer:(id)layer
{
    if (self = [super initWithLayer:layer])
    {
        if ([layer isKindOfClass:[DotLayer class]]) {
            self.strokeEnd = [(DotLayer *)layer strokeEnd];
            self.strokeStart = [(DotLayer *)layer strokeStart];
            self.isSelected = NO;
        }
    }
    return self;
}
- (void)createArcAnimationForKey:(NSString *)key fromValue:(NSNumber *)from toValue:(NSNumber *)to timing:(CFTimeInterval)duration Delegate:(id)delegate
{
    CABasicAnimation *arcAnimation = [CABasicAnimation animationWithKeyPath:key];
    NSNumber *currentAngle = [[self presentationLayer] valueForKey:key];
    if(!currentAngle) currentAngle = from;
    
    arcAnimation.duration = duration;
    [arcAnimation setFromValue:currentAngle];
    [arcAnimation setToValue:to];
    [arcAnimation setDelegate:delegate];
    [arcAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
    //    [arcAnimation setDuration:10.0];
    [self addAnimation:arcAnimation forKey:key];
    [self setValue:to forKey:key];
}
@end

@interface LineChartView(Private)
- (void) loadXAxisLabels;
- (NSInteger)getCurrentSelectedOnTouch:(CGPoint)point;
- (void) setViewSelectedAtIndex:(NSInteger)currentIndex;
- (void) setViewDeselectedAtIndex:(NSInteger)currentIndex;

@end

@implementation LineChartView
{
    UIView *lineChartView;
    UIView *chartArea;
    NSTimer *animationTimer;
    NSMutableArray *xAxisLabels;
    CGFloat selectedViewData;
    NSInteger selectedViewIndex;
    UILabel *selectedNumberLabel;
    CGFloat numberLabelPercentage;
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        lineChartView = [[UIView alloc] initWithFrame:self.bounds];
        selectedViewIndex = -1;
        selectedViewData = -1;
        numberLabelPercentage = 0.65;
        
        self.barMargin = 20;
        self.xScale = 7;
        self.yScale = 100;
        self.xAxisLabel = [[UILabel alloc] init];
        self.barColor = [UIColor orangeColor];
        self.barCornerRadius = 3.0;
        self.lineWidth = 3.0;
//        self.barStrokeWidth = 3.0;
        self.chartMargin = 15;
        self.barMargin = 0;
        self.labelColor = [UIColor whiteColor];
        self.labelFont = [UIFont boldSystemFontOfSize:MAX((int)self.bounds.size.width/self.xScale, 5)];
        xAxisLabels = [[NSMutableArray alloc]init];
        [self addSubview:lineChartView];
        
        CGRect chartAreaRect = CGRectMake(self.chartMargin, self.chartMargin, lineChartView.frame.size.width - self.chartMargin*2, self.frame.size.height - self.chartMargin*3);
        
        CGRect selectedNumberLabelRect = CGRectMake(self.chartMargin*3, self.chartMargin, lineChartView.frame.size.width - self.chartMargin*5, self.chartMargin*4);
        
        chartArea = [[UIView alloc]initWithFrame:chartAreaRect];
        chartArea.backgroundColor = [UIColor clearColor];
        
        selectedNumberLabel = [[UILabel alloc]initWithFrame:selectedNumberLabelRect];
        selectedNumberLabel.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.3];
        selectedNumberLabel.layer.cornerRadius = self.barCornerRadius*3;
        selectedNumberLabel.layer.masksToBounds = YES;
        selectedNumberLabel.adjustsFontSizeToFitWidth = YES;
        selectedNumberLabel.minimumScaleFactor = 10;
        selectedNumberLabel.textAlignment = NSTextAlignmentCenter;
        selectedNumberLabel.hidden = YES;
        selectedNumberLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:50];
        selectedNumberLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1];
        
        
        [lineChartView addSubview:chartArea];
        [lineChartView addSubview:selectedNumberLabel];
        //        CGRect rect = chartArea.frame;
        
        //add base bars
        int totalBars = 7;
        self.barWidth = (chartArea.frame.size.width - totalBars*self.barMargin) / totalBars;
        
        for (int i=0; i<7; i++) {
            //            CGFloat height = chartArea.frame.size.height;
            
            
            CGFloat currentX = i*(self.barWidth+self.barMargin);
            CGFloat currentY = 0;
            
            CGRect barRect = CGRectMake(currentX, currentY, self.barWidth, chartArea.frame.size.height);
            UIView *baseBar = [[UIView alloc] initWithFrame:barRect];
            baseBar.layer.cornerRadius = 3.0;
            baseBar.layer.masksToBounds = YES;
            baseBar.layer.borderColor = [UIColor clearColor].CGColor;
            baseBar.layer.borderWidth = 3.0;
            if(i==0)
                self.dotSize = baseBar.frame.size.width/6;
            
            //            [baseBars addObject:baseBar];
            [chartArea addSubview:baseBar];
        }
    }
    return self;
}

- (void)loadXAxisLabels
{
    
    //    xAxisLabels = [NSMutableArray arrayWithObjects:@"9/1",@"9/2",@"9/3",@"9/4",@"9/5",@"9/6",@"9/7", nil];
    [self getDateLabelsForLastWeek];
    CGRect xAxisLabelViewRect = CGRectMake( chartArea.frame.origin.x, chartArea.frame.size.height,chartArea.frame.size.width, self.chartMargin*2);
    UIView *xAxisLabelView = [[UIView alloc] initWithFrame:xAxisLabelViewRect];
    CGFloat labelWidth = (chartArea.frame.size.width-xAxisLabels.count*self.barMargin) / 7.0;
    [xAxisLabels enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UILabel *xLabel = [[UILabel alloc] initWithFrame:CGRectMake(idx*(labelWidth+self.barMargin)+self.barMargin, self.chartMargin, labelWidth, self.chartMargin*2)];
        xLabel.text = [NSString stringWithFormat:@"%@",obj];
        xLabel.textColor = [UIColor blackColor];
        xLabel.font = [xLabel.font fontWithSize:12];
        [xAxisLabelView addSubview:xLabel];
    }];
    [lineChartView addSubview:xAxisLabelView];
}

- (void)getDateLabelsForLastWeek
{
    NSDate *today = [NSDate date];
    NSTimeInterval secondsPerDay = 60*60*24;
    NSDate *dayIter = [today dateByAddingTimeInterval:secondsPerDay*(-7)];
    
    for (int i=0;i<7;i++)
    {
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:dayIter];
        NSInteger day = [components day];
        NSInteger month = [components month];
        NSString *newDateString = [NSString stringWithFormat:@"%2ld/%2ld", month ,day];
        NSLog(@"%@", newDateString);
        [xAxisLabels addObject:newDateString];
        dayIter = [dayIter dateByAddingTimeInterval:secondsPerDay];
    }
    
}


- (void)loadLineChart
{
    [self loadXAxisLabels];
    CAShapeLayer *axisLayer = [DotLayer layer];
    
    //draw Axis
    UIBezierPath *axisPath = [UIBezierPath bezierPath];
    [axisPath moveToPoint:CGPointMake(self.chartMargin, self.chartMargin)];
    [axisPath addLineToPoint:CGPointMake(self.chartMargin, self.frame.size.height-self.chartMargin*2)];
    [axisPath addLineToPoint:CGPointMake(self.frame.size.width-self.chartMargin, self.frame.size.height-self.chartMargin*2)];
    
    axisLayer.path = axisPath.CGPath;
    
    axisLayer.fillColor = [UIColor clearColor].CGColor;
    axisLayer.strokeColor = [UIColor grayColor].CGColor;
    axisLayer.lineWidth = 5.0;
    axisLayer.lineCap = kCALineCapRound;
    [lineChartView.layer addSublayer:axisLayer];
    
    // add running stroke to base bars in chart area
    NSArray *barArray = [chartArea subviews];
    NSArray *dataArray = [self.dataSource getData];
    
    double sum = 0;
    selectedViewData = -1;
    selectedViewIndex= -1;
    
    for (int i=0; i<dataArray.count; i++) {
        double currentValue = [(NSNumber*)[dataArray objectAtIndex:i] doubleValue];
        sum = sum+currentValue;
        if( currentValue > selectedViewData )
        {
            selectedViewIndex = i;
            selectedViewData = currentValue;
        }
    }
    double maxPercentage = selectedViewData/sum;
    self.yScale = numberLabelPercentage/maxPercentage;
    
    for (int i=0; i< barArray.count; i++) {
        
        UIView* baseBarView = [barArray objectAtIndex:i];

        DotLayer *dotLayer = [DotLayer layer];
        CAShapeLayer *lineLayer = [CAShapeLayer layer];
        DotLayer *selectDotLayer = [DotLayer layer];

        int currentDataValue = [(NSNumber*)[dataArray objectAtIndex:i] intValue];
        int previousDataValue = 0;
        int nextDataValue = 0;
        previousDataValue = (i==0)? currentDataValue : [(NSNumber*)[dataArray objectAtIndex:i-1] intValue];
        nextDataValue = (i==dataArray.count-1)? currentDataValue : [(NSNumber*)[dataArray objectAtIndex:i+1] intValue];

        double currentPercentage = currentDataValue/sum;
        double nextPercentage = nextDataValue/sum;
        double previousPercentage = previousDataValue/sum;
        
        CGFloat currentX = baseBarView.frame.size.width/2;
        CGFloat nextX = (i==dataArray.count-1)? currentX : (baseBarView.frame.size.width*1.5 +self.barMargin);
        CGFloat prevoiusX = (i==0) ? currentX : (0 - baseBarView.frame.size.width/2 - self.barMargin);

        
        CGFloat currentY = baseBarView.frame.size.height *(1-currentPercentage*self.yScale);
        CGFloat nextY = (i==dataArray.count-1)? currentY : (baseBarView.frame.size.height *(1-nextPercentage*self.yScale));
        CGFloat prevoiusY = (i==0) ? currentY : (baseBarView.frame.size.height *(1-previousPercentage*self.yScale));
        
        CGRect box = CGRectMake(currentX-self.dotSize, currentY-self.dotSize, baseBarView.frame.size.width/3, baseBarView.frame.size.width/3);
        UIBezierPath *dotPath = [UIBezierPath bezierPathWithOvalInRect:box];
        
        UIBezierPath *linePath = [UIBezierPath bezierPath];
        [linePath moveToPoint:CGPointMake(prevoiusX, prevoiusY)];
        [linePath addLineToPoint:CGPointMake(currentX, currentY)];
        [linePath addLineToPoint:CGPointMake(nextX, nextY)];
        linePath.lineCapStyle = kCGLineCapRound;
        
        lineLayer.path = linePath.CGPath;
        lineLayer.strokeColor = [UIColor yellowColor].CGColor;
        lineLayer.lineWidth = self.lineWidth;
        lineLayer.fillColor = [UIColor clearColor].CGColor;
        dotLayer.path = dotPath.CGPath;
//        bar.lineWidth = self.barWidth;
        dotLayer.fillColor = [UIColor yellowColor].CGColor;
//        dotLayer.strokeColor = [UIColor yellowColor].CGColor;
//        bar.strokeEnd    = 0.0;
//        bar.cornerRadius = self.barCornerRadius;
        dotLayer.dotValue = currentDataValue;
        
        
        [baseBarView.layer addSublayer:dotLayer];
        [baseBarView.layer addSublayer:lineLayer];
        [baseBarView.layer addSublayer:selectDotLayer];
        
        CGRect rect = baseBarView.frame;
        selectDotLayer.frame = CGRectMake(currentX - 2*self.dotSize, currentY-2*self.dotSize, self.dotSize*4, self.dotSize*4);
        selectDotLayer.cornerRadius = self.dotSize*2;
        selectDotLayer.masksToBounds = YES;
        
        if (i==selectedViewIndex) {
            selectDotLayer.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.3].CGColor;
            selectedNumberLabel.text = [NSString stringWithFormat:@"%2ld", (NSInteger)dotLayer.dotValue];
            selectedNumberLabel.hidden = NO;
         
        }
        
//        [dotLayer createArcAnimationForKey:@"strokeEnd" fromValue:@0.0 toValue:[NSNumber numberWithDouble:self.yScale*percentage] timing:2.0 Delegate:self];
//        dotLayer.strokeEnd = self.yScale*percentage;
    }
    
}

- (NSInteger)getCurrentSelectedOnTouch:(CGPoint)point
{
    __block NSUInteger selectedIndex = -1;
    
    //    CGAffineTransform transform = CGAffineTransformIdentity;
    
    NSArray *barViews = [chartArea subviews];
    
    [barViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIView *barView = (UIView *)obj;
        
        if (CGRectContainsPoint(barView.frame, point)) {
            selectedIndex = idx;
        }
    }];
    return selectedIndex;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesMoved:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:chartArea];
    [self getCurrentSelectedOnTouch:point];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:chartArea];
    NSInteger currentIndex = [self getCurrentSelectedOnTouch:point];
    if (currentIndex!=-1) {
        if(currentIndex != selectedViewIndex)
        {
            [self setViewSelectedAtIndex:currentIndex];
            if (selectedViewIndex!=-1) {
                [self setViewDeselectedAtIndex:selectedViewIndex];
            }
            selectedViewIndex = currentIndex;
        }
        else
        {
            //            [self setViewDeselectedAtIndex:selectedViewIndex];
            //            selectedViewIndex = -1;
        }
    }
    
}

- (void)setViewSelectedAtIndex:(NSInteger)currentIndex
{
    UIView *barView = [[chartArea subviews] objectAtIndex:currentIndex];
    //add gray shade to the barstroke
    DotLayer *currentLayer = [[barView.layer sublayers] objectAtIndex:2];
    currentLayer.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.3].CGColor;
    //get the value of stroke to show in number Label
    currentLayer = [[barView.layer sublayers] objectAtIndex:0];
    selectedViewData = currentLayer.dotValue;
    selectedNumberLabel.text = [NSString stringWithFormat:@"%2ld", (NSInteger)currentLayer.dotValue];
    selectedNumberLabel.hidden = NO;
}

-(void)setViewDeselectedAtIndex:(NSInteger)currentIndex
{
    UIView *barView = [[chartArea subviews] objectAtIndex:currentIndex];
    DotLayer *selectBarLayer = [[barView.layer sublayers] objectAtIndex:2];
    selectBarLayer.backgroundColor = [UIColor clearColor].CGColor;
    
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
