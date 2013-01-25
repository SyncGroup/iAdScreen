//
//  AdScreenViewController.m
//  AdScreen
//
//  Created by Gabriel Gino Vincent on 17/01/13.
//  Copyright (c) 2013 Sync. All rights reserved.
//

// Configuration
#define AdImageRequestURL @"http://labs.syncmobile.com.br/AdScreen/"
#define DefaultAdScreenImageFile @"AdScreen.png"
#define DismissAdScreenSegueIdentifier @"LeaveAdScreen"
#define WaitTime 3.0

#define HasImageOnCache image
#define InternetIsConnected [[Connection sharedInstance] isConnected]

#import "AdScreenViewController.h"

@interface AdScreenViewController ()

@end

@implementation AdScreenViewController

- (void) dismissAdScreen {
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    [self performSegueWithIdentifier:DismissAdScreenSegueIdentifier sender:self];
}

- (void) loadCachedImage {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = [paths objectAtIndex:0];
    NSString *imagePath = [cacheDirectory stringByAppendingPathComponent:DefaultAdScreenImageFile];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        UIImage *image = [[UIImage alloc] initWithContentsOfFile:imagePath];
        
        if (HasImageOnCache) {
            imageView.image = [UIImage imageWithContentsOfFile:imagePath];
            [self performSelector:@selector(dismissAdScreen) withObject:nil afterDelay:WaitTime];
            NSLog(@"Loading image from cache");
        }
        else {
            image = [UIImage imageNamed:DefaultAdScreenImageFile];
            imageView.image = image;
            NSLog(@"No image on cache. Loading default image");
        }
        
        [self performSelector:@selector(dismissAdScreen) withObject:nil afterDelay:WaitTime];
    });
    
    
}

- (void) imageDidFinishDownload {
    NSLog(@"Downloaded image. Showing it right now.");
    [self performSelector:@selector(dismissAdScreen) withObject:nil afterDelay:WaitTime];
}

- (void) downloadImageFromURL:(NSURL *)url {
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:8.0];
    NSHTTPURLResponse *response = nil;
    NSData *imageData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
    
    if (imageData) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cacheDirectory = [paths objectAtIndex:0];
        NSString *imagePath = [cacheDirectory stringByAppendingPathComponent:DefaultAdScreenImageFile];
        
        UIImage *image = [UIImage imageWithData:imageData];
        imageView.image = image;
        
        imageData = UIImagePNGRepresentation(image);
        [imageData writeToFile:imagePath atomically:YES];
        
        [self imageDidFinishDownload];
    }
    else {
        NSLog(@"Couldn't download image, loading from cache");
        [self loadCachedImage];
    }
}

- (void) requestImageURL {
    
    NSURL *requestURL = [NSURL URLWithString:AdImageRequestURL];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:requestURL cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:8.0];
    NSHTTPURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
    
    if (!data) {
        [self loadCachedImage];
        return;
    }
    
    NSString *cachedURLString = [defaults objectForKey:@"AD_SCREEN_ImageURL"];
    NSString *urlString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if (![cachedURLString isEqualToString:urlString]) {
        NSURL *url = [NSURL URLWithString:urlString];
        [self downloadImageFromURL:url];
        [defaults setObject:urlString forKey:@"AD_SCREEN_ImageURL"];
        [defaults synchronize];
        return;
    }
    
    [self loadCachedImage];
}

- (void) configureImageView {
    
    imageView = [[UIImageView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.view addSubview:imageView];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    defaults = [[NSUserDefaults standardUserDefaults] init];
    [self configureImageView];
    [self requestImageURL];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
