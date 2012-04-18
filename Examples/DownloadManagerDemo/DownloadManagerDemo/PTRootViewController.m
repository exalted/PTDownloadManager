//
//  PTRootViewController.m
//  DownloadManagerDemo
//
//  Created by Ali Servet Donmez on 18.4.12.
//  Copyright (c) 2012 Apex-net srl. All rights reserved.
//

#import "PTRootViewController.h"

#import "PTDownloadManager.h"

@interface PTRootViewController ()

@end

@implementation PTRootViewController

@synthesize imageView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [self setImageView:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        ////////////////////////////////////////////////////////////////////////
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://bit.ly/HTAA1e"]];
        PTFile *file = [[PTDownloadManager sharedManager] addFileWithName:@"divisorio.pdf" date:[NSDate date] request:request];
        [file downloadWithProgressOnView:self.imageView];
        ////////////////////////////////////////////////////////////////////////
    });
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)buttonAction:(id)sender {
    ////////////////////////////////////////////////////////////////////////////
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://bit.ly/JcwvQ9"]];
    PTFile *file = [[PTDownloadManager sharedManager] addFileWithName:@"poliespanso.mp4" date:[NSDate date] request:request];
    [file downloadWithProgressOnView:sender];
    ////////////////////////////////////////////////////////////////////////////
}

@end
