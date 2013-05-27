//
//  MainViewController.m
//  RemoteWeb
//
//  Created by Yos Hashimoto.
//  Copyright Newton Japan Inc. 2009. All rights reserved.
//

#import "MainViewController.h"
#import "MainView.h"

//static MainViewController *sharedInstance = nil;

@implementation MainViewController

@synthesize textView, serviceInProgress;

int			webAction;
NSString	*targetURL;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		webAction = WA_DO_NOTHING;
    }
    return self;
}


 - (void)viewDidLoad {
	 [super viewDidLoad];
	 [self startService];
 }

- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller {
    
	[self dismissModalViewControllerAnimated:YES];
}


- (IBAction)showInfo {    
	
	FlipsideViewController *controller = [[FlipsideViewController alloc] initWithNibName:@"FlipsideView" bundle:nil];
	controller.delegate = self;
	controller.targetURL = targetURL;
	
	controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:controller animated:YES];
	
	[controller release];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	[self stopService];
}


- (void)dealloc {
    [super dealloc];
}


#pragma mark -
#pragma mark Service Handling

- (void) timerTargetCheck:(NSTimer*) timer
{
	if(webAction == WA_DO_NOTHING) {
		return;
	}

	switch (webAction) {
		case WA_OPEN_URL:
			[self showInfo];
			break;
		case WA_FLIP_BACK:
			[self flipsideViewControllerDidFinish:nil];
			break;
		default:
			break;
	}
	webAction = WA_DO_NOTHING;
}

- (void) timerJob:(NSTimer*) timer
	{
	if (serviceInProgress) {
		[timer invalidate];
		NSHost* myhost =[NSHost currentHost];
		NSString *ip_address = [myhost address];
		[textView setContentToHTMLString:[NSString stringWithFormat:@"<h2>iPhoneサーバ稼働中</h2><p>同一ネットワークに接続されているコンピュータのウェブブラウザで、以下のURLにアクセスしてください。</p><p>　<strong>http://%@</strong></p><p>サービスを停止するにはアプリを終了させてください。</p><br />", 
										  [NSString stringWithFormat:@"%@",ip_address]]];
		return;
	}
	
	[textView setContentToHTMLString:@"<h2>サービス開始リトライ待ち</h2><p>５秒後にリトライします。</p><br /><br />"];
}

- (void) startService
{
	[textView setContentToHTMLString:@"<h2>ウェブサービスを開始しています。</h2><p>しばらくお待ち下さい。</p><br /><br />"];
	serviceInProgress = YES;
	
	[NSThread detachNewThreadSelector:@selector(serverThreadEntry) toTarget:self withObject:NULL];
	
    [NSTimer scheduledTimerWithTimeInterval: 5.0 target: self selector: @selector(timerJob:) userInfo: nil repeats: YES];
    [NSTimer scheduledTimerWithTimeInterval: 0.5 target: self selector: @selector(timerTargetCheck:) userInfo: nil repeats: YES];
}

- (void) stopService
{
	serviceInProgress = NO;
	close(listeningSocket);
}


#pragma mark -
#pragma mark Web Service Thread

// ウェブサービスのスレッドエントリー（TCP/IP）
- (void) serverThreadEntry
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	int connectionSocket;
	socklen_t length;
	static struct sockaddr_in client_address; 
	static struct sockaddr_in server_address;
	
	// リスニングソケットの生成
	if((listeningSocket = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
		serviceInProgress = NO;
		return;
	}
	
	server_address.sin_family = AF_INET;
	server_address.sin_addr.s_addr = htonl(INADDR_ANY);
	server_address.sin_port = htons(HTTP_PORT);
	
	// 待ち受けポートのバインド
	if(bind(listeningSocket, (struct sockaddr *)&server_address,sizeof(server_address)) < 0) {
		serviceInProgress = NO;
		return;
	}
	
	// 待ち受け開始
	if(listen(listeningSocket, QUEUE_SIZE) < 0) {
		serviceInProgress = NO;
		return;
	} 
	
	// リクエスト待ちループ
	while (TRUE) {
		length = sizeof(client_address);
		if((connectionSocket = accept(listeningSocket, (struct sockaddr *)&client_address, &length)) < 0) {
			serviceInProgress = NO;
			break;
			//	return;
		}
		// 接続ソケットのリクエストを処理する
		[self handleRequest:connectionSocket];
	}
	
	[pool release];
}

// HTTP-GETリクエストに対してのサービス
- (void) handleRequest:(int)connectionSocket
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	static char buffer[BUFFER_SIZE+1];
	
	int len = read(connectionSocket, buffer, BUFFER_SIZE); 	
	buffer[len] = '\0';
	
	NSString *request = [NSString stringWithCString:buffer];
	NSLog(request);
	NSArray *requests = [request componentsSeparatedByString:@"\n"];
	NSString *get_request = [[requests objectAtIndex:0] substringFromIndex:4];

	NSRange range = [get_request rangeOfString:@"HTTP/"];
	if (range.location == NSNotFound) {
		close(connectionSocket);
		return;
	}
	
	NSString *filereq = [[get_request substringToIndex:range.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
	NSString *outcontent = [NSString stringWithFormat:@"HTTP/1.0 200 OK\r\nContent-Type: text/html\r\n\r\n"];
	write(connectionSocket, [outcontent UTF8String], [outcontent length]);

	NSMutableString *outdata = [[NSMutableString alloc] init];

	[outdata appendFormat:@"<html> \n<head> \n<title>Remote Web</title> \n"];
	[outdata appendString:@"<style>html {background-color:#ddffdd} body { background-color:#FFFFFF; margin-left:5%; margin-right:5%; border:2px groove #00FF00; padding:5px; } </style> \n"];
	[outdata appendFormat:@"</head> \n<body> \n"];
	[outdata appendFormat:@"<h1>Remote Web</h1> \n"];

	// URLパラメータの指定がない場合（"/"）
	if ([filereq isEqualToString:@"/"]) {
		[outdata appendString:@"<p>iPhoneへ送るURLを入れて下さい</p> \n"];
		[outdata appendString:@"<form method='get' action='/'> \n"];
		[outdata appendString:@"<input type='hidden' name='cmd' value='web' /> \n"];
		[outdata appendString:@"http://<input type='text' name='address' /><br /> \n"];
		[outdata appendString:@"<input type='submit' value='Open' /> \n"];
		[outdata appendString:@"</form> \n"];
	}
	// URLパラメータの指定がある場合
	else {
		NSString* tmpStr = (NSString*)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (CFStringRef)filereq, CFSTR(""), kCFStringEncodingUTF8);
		NSRange range_cmd = [tmpStr rangeOfString:@"cmd="];
		if (range_cmd.location != NSNotFound) {
			NSArray *reqs_cmd = [request componentsSeparatedByString:@"cmd="];
			NSArray *reqs_cmd2 = [[reqs_cmd objectAtIndex:1] componentsSeparatedByString:@"&"];
			NSArray *reqs_cmd3 = [[reqs_cmd2 objectAtIndex:0] componentsSeparatedByString:@" "];
			NSString *getreq_cmd = [[reqs_cmd3 objectAtIndex:0] substringFromIndex:0];
			
			
			if([getreq_cmd isEqualToString:@"web"]) {
				reqs_cmd = [request componentsSeparatedByString:@"address="];
				reqs_cmd2 = [[reqs_cmd objectAtIndex:1] componentsSeparatedByString:@"&"];
				reqs_cmd3 = [[reqs_cmd2 objectAtIndex:0] componentsSeparatedByString:@" "];
				NSString *getreq_address = [[reqs_cmd3 objectAtIndex:0] substringFromIndex:0];
				targetURL = [[NSString stringWithFormat:@"http://%@", getreq_address] copy];
				webAction = WA_OPEN_URL;
				[outdata appendString:@"<p>iPhoneでウェブサイトを表示しました</p> \n"];
				[outdata appendString:@"<form method='get' action='/'> \n"];
				[outdata appendString:@"<input type='hidden' name='cmd' value='done' /> \n"];
				[outdata appendString:@"<input type='submit' value='Flip Back' /> \n"];
				[outdata appendString:@"</form> \n"];
			}
			else if([getreq_cmd isEqualToString:@"done"]) {
				webAction = WA_FLIP_BACK;
				[outdata appendString:@"<p>フリップバックしました</p> \n"];
				[outdata appendString:@"<form method='get' action='/'> \n"];
				[outdata appendString:@"<input type='hidden' name='cmd' value='web' /> \n"];
				[outdata appendString:@"http://<input type='text' name='address' /><br /> \n"];
				[outdata appendString:@"<input type='submit' value='Open' /> \n"];
				[outdata appendString:@"</form> \n"];
			}
			else {
				[outdata appendString:@"<p>URLパラメータが間違っているようです</p> \n"];
			}
		}
		else {
			[outdata appendString:@"<p>URLパラメータが間違っているようです</p> \n"];
		}
	}
	[outdata appendFormat:@"</body> \n</html> \n"];
	write(connectionSocket, [outdata UTF8String], [outdata length]);

	// 接続ソケットのクローズ
	close(connectionSocket);
	
	[pool release];
}


@end
