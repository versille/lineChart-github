//
//  ViewController.h
//  LineChart
//
//  Created by versille on 7/13/14.
//  Copyright (c) 2014 versille. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LineChartView.h"

@interface ViewController : UIViewController <LineChartViewDataSource>
@property (weak, nonatomic) IBOutlet LineChartView *lineChart;

@end
