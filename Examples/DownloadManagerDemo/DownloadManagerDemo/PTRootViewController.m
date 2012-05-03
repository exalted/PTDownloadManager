//
// Copyright (C) 2012 Ali Servet Donmez. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "PTRootViewController.h"

#import "PTDownloadManager.h"

@interface PTRootViewController ()

@end

@implementation PTRootViewController

@synthesize imageView;
@synthesize downloadLabel;

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
    [self setDownloadLabel:nil];
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
        [file download];
        [file showProgressOnView:self.imageView label:self.downloadLabel];
        double delayInSeconds = 20.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            NSLog(@"HEY!");
            [file showProgressOnView:self.imageView label:self.downloadLabel];
        });
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
    [file showProgressOnView:sender label:nil];
    [file download];
    ////////////////////////////////////////////////////////////////////////////
}

@end
