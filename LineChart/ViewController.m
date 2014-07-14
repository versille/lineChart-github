//
//  ViewController.m
//  LineChart
//
//  Created by versille on 7/13/14.
//  Copyright (c) 2014 versille. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.lineChart.dataSource = self;
	// Do any additional setup after loading the view, typically from a nib.
    [self.lineChart loadLineChart];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSArray *)getData
{
    return [NSArray arrayWithObjects:@11, @22, @34, @9, @88, @37, @29, nil];
}

@end
