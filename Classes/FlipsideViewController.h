//
//  FlipsideViewController.h
//  RemoteWeb
//
//  Created by Yos Hashimoto.
//  Copyright Newton Japan Inc. 2009. All rights reserved.
//

@protocol FlipsideViewControllerDelegate;


@interface FlipsideViewController : UIViewController <UIWebViewDelegate> {
	id <FlipsideViewControllerDelegate> delegate;
	
	IBOutlet UIWebView*		webView;
	NSString*				targetURL;
}

@property (nonatomic, assign) id <FlipsideViewControllerDelegate> delegate;
@property (nonatomic, retain) IBOutlet UIWebView*		webView;
@property (nonatomic, retain) NSString*					targetURL;

- (IBAction)done;

@end


@protocol FlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller;
@end

