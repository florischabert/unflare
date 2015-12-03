//
//  ViewController.m
//  UnFlare
//
//  Created by Floris Chabert on 12/1/15.
//  Copyright © 2015 floris. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    UIVisualEffect *blurEffect;
    blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    
    UIVisualEffectView *visualEffectView;
    visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    
    visualEffectView.frame = self.view.frame;
    [self.imageView addSubview:visualEffectView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(launchPhotoLibrary) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [self launchPhotoLibrary];
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)launchPhotoLibrary {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"photos-redirect://"]];
    });
}

@end
