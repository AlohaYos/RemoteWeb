//
//  MainViewController.h
//  RemoteWeb
//
//  Created by Yos Hashimoto.
//  Copyright Newton Japan Inc. 2009. All rights reserved.
//

#import "FlipsideViewController.h"
#import <UIKit/UIKit.h>
#include <netdb.h>

#define HTTP_PORT		80
#define BUFFER_SIZE		8192
#define QUEUE_SIZE		32

#define	WA_DO_NOTHING	0
#define	WA_OPEN_URL		1
#define	WA_FLIP_BACK	2

@interface MainViewController : UIViewController <FlipsideViewControllerDelegate> {
	int					listeningSocket;
	BOOL				serviceInProgress;
	IBOutlet UITextView	*textView;
}

@property (nonatomic, retain)	IBOutlet UITextView		*textView;
@property (nonatomic)			BOOL					serviceInProgress;

- (IBAction)showInfo;

@end
