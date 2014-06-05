//
//  SNGViewController.m
//  Camera Handler
//
//  Created by Eddy Gammon on 08/05/2014.
//  Copyright (c) 2014 Kudan. All rights reserved.
//

typedef void(^CompletionBlock)();

static void * CapturingStillImageContext = &CapturingStillImageContext;
static void * SessionRunningAndDeviceAuthorizedContext = &SessionRunningAndDeviceAuthorizedContext;

#import "TakePhotoViewController.h"
#import <FacebookSDK/FacebookSDK.h>
#import <Parse/Parse.h>
@import AssetsLibrary;
@import AVFoundation;


@interface TakePhotoViewController () <AVCaptureVideoDataOutputSampleBufferDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIView *cameraView;
@property (weak, nonatomic) IBOutlet UIButton *takePhotoButton;
@property (weak, nonatomic) IBOutlet UIButton *switchCameraButton;


- (IBAction)takePicture:(UIButton *)sender;
- (IBAction)switchCamera:(UIButton *)sender;


- (void)checkDeviceAuthorisationStatus;

// Session management.
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) AVCaptureSession *captureSession;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic) CIContext *ciContext;

// Utilities.
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;
@property (nonatomic, getter = isDeviceAuthorized) BOOL deviceAuthorized;
@property (nonatomic, readonly, getter = isSessionRunningAndDeviceAuthorized) BOOL sessionRunningAndDeviceAuthorized;
@property (nonatomic) BOOL lockInterfaceRotation;

@end

@implementation TakePhotoViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self.takePhotoButton setTitle:CameraString forState:UIControlStateNormal];
    [self.takePhotoButton.titleLabel setFont:[UIFont fontWithName:@"FontAwesome" size:24]];
	self.takePhotoButton.layer.borderColor = [UIColor redColor].CGColor;
    self.takePhotoButton.layer.borderWidth = 5;
    self.takePhotoButton.layer.cornerRadius = self.takePhotoButton.layer.bounds.size.width/2.;
    
	AVCaptureSession *session = [[AVCaptureSession alloc] init];
    
	self.captureSession = session;
    
	[self checkDeviceAuthorisationStatus];
	
	self.ciContext = [CIContext contextWithOptions:nil];
	
	// In general it is not safe to mutate an AVCaptureSession or any of its inputs, outputs, or connections from multiple threads at the same time.
	// Why not do all of this on the main queue?
	// -[AVCaptureSession startRunning] is a blocking call which can take a long time. We dispatch session setup to the sessionQueue so that the main queue isn't blocked (which keeps the UI responsive).
	
	dispatch_queue_t sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
	self.sessionQueue = sessionQueue;
	
	dispatch_async(sessionQueue, ^{
		[self setBackgroundRecordingID:UIBackgroundTaskInvalid];
		
		NSError *error = nil;
		
		AVCaptureDevice *videoDevice = [TakePhotoViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionFront];
		AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
		
		if (error)
		{
			NSLog(@"%@", error);
		}
		
		if ([session canAddInput:videoDeviceInput])
		{
			[session addInput:videoDeviceInput];
			[self setVideoDeviceInput:videoDeviceInput];
		}
		
		AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
		if ([session canAddOutput:stillImageOutput])
		{
			[stillImageOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];
			[session addOutput:stillImageOutput];
			self.stillImageOutput = stillImageOutput;
		}
		
		AVCaptureVideoDataOutput *videoOutput = [AVCaptureVideoDataOutput new];
		self.videoOutput = videoOutput;
		videoOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
		[videoOutput setSampleBufferDelegate:self queue:self.sessionQueue];
		
		if ([session canAddOutput:videoOutput]) {
			
			[session addOutput:videoOutput];
		}
	});
}

- (void)viewWillAppear:(BOOL)animated
{
	dispatch_async(self.sessionQueue, ^{
		[self.captureSession startRunning];
		
	});
}

- (void)checkDeviceAuthorisationStatus
{
	NSString *mediaType = AVMediaTypeVideo;
	
	[AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
        
		if (granted) {
			self.deviceAuthorized = YES;
			
		} else {
            
			dispatch_async(dispatch_get_main_queue(), ^{
				[[[UIAlertView alloc] initWithTitle:@"AVCam!"
											message:@"AVCam doesn't have permission to use Camera, please change privacy settings"
										   delegate:self
								  cancelButtonTitle:@"OK"
								  otherButtonTitles:nil] show];
				self.deviceAuthorized = NO;
			});
		}
	}];
}

+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
	AVCaptureDevice *captureDevice = [devices firstObject];
	
	for (AVCaptureDevice *device in devices)
	{
		if ([device position] == position)
		{
			captureDevice = device;
			break;
		}
	}
	
	return captureDevice;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
	
	[connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
	
	CVPixelBufferRef ref = CMSampleBufferGetImageBuffer(sampleBuffer);
	CIImage *image = [CIImage imageWithCVPixelBuffer:ref];
    CGImageRef cgImage = [self.ciContext createCGImage:image fromRect:[image extent]];
	
    if (!cgImage) {
        return;
    }
    
	dispatch_async(dispatch_get_main_queue(), ^{
		self.cameraView.layer.contents = (id)CFBridgingRelease(cgImage);
	});
}

#pragma mark - UI Stuff
- (IBAction)takePicture:(UIButton *)sender {
	CGImageRef imageRef = (__bridge CGImageRef)(self.cameraView.layer.contents);
	
//	[[[ALAssetsLibrary alloc] init] writeImageToSavedPhotosAlbum:[image CGImage] orientation:ALAssetOrientationUp completionBlock:nil];
    
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    
    [self checkPermissionsWithCompletion:^{
       
        [self presentFBShareWithPhoto:image];
    }];
}

- (IBAction)switchCamera:(UIButton *)sender {
    
	dispatch_async([self sessionQueue], ^{
		AVCaptureDevice *currentVideoDevice = [[self videoDeviceInput] device];
		AVCaptureDevicePosition preferredPosition = AVCaptureDevicePositionUnspecified;
		AVCaptureDevicePosition currentPosition = [currentVideoDevice position];
		
		switch (currentPosition) {
                
			case AVCaptureDevicePositionUnspecified:
				preferredPosition = AVCaptureDevicePositionBack;
				break;
			case AVCaptureDevicePositionBack:
				preferredPosition = AVCaptureDevicePositionFront;
				break;
			case AVCaptureDevicePositionFront:
				preferredPosition = AVCaptureDevicePositionBack;
				break;
		}
		
		AVCaptureDevice *videoDevice = [TakePhotoViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:preferredPosition];
		AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
		
		[self.captureSession beginConfiguration];
		
		[self.captureSession removeInput:[self videoDeviceInput]];
		
		if ([self.captureSession canAddInput:videoDeviceInput]) {
			[self.captureSession addInput:videoDeviceInput];
			[self setVideoDeviceInput:videoDeviceInput];
            
		} else {
			[self.captureSession addInput:[self videoDeviceInput]];
		}
		
		[self.captureSession commitConfiguration];
	});
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return NO;
}

- (IBAction)cancelPressed:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)postWithoutPhoto:(id)sender {
    
    [self checkPermissionsWithCompletion:^{
        
        [self postOpenGraphStoryWithPhoto:nil remoteURI:nil];
    }];
}

- (void)checkPermissionsWithCompletion:(CompletionBlock)completion {
    
    [FBRequestConnection startWithGraphPath:@"/me/permissions" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        
        if (!error) {
            
            NSDictionary *permissions= [(NSArray *)[result data] objectAtIndex:0];
            if (![permissions objectForKey:@"publish_actions"]){

                [self requestPublishPermissionsWithCompletion:completion];
                
            } else {
                completion();
            }
            
        } else {
            [self handleError:error];
        }
    }];
}

- (void)requestPublishPermissionsWithCompletion:(CompletionBlock)completion {
    
    [FBSession.activeSession requestNewPublishPermissions:[NSArray arrayWithObject:@"publish_actions"] defaultAudience:FBSessionDefaultAudienceFriends completionHandler:^(FBSession *session, NSError *error) {
        
        if (!error) {
            
            if ([FBSession.activeSession.permissions indexOfObject:@"publish_actions"] == NSNotFound) {
                // Permission not granted, tell the user we will not publish
                NSString *alertTitle = @"Permission not granted";
                NSString *alertText = @"Your action will not be published to Facebook.";
                [[[UIAlertView alloc] initWithTitle:alertTitle message:alertText delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            } else {
                
                completion();
            }
            
        } else {
            [self handleError:error];
        }
    }];
}

- (void)presentFBShareWithPhoto:(UIImage *)image {
    
    [FBRequestConnection startForUploadStagingResourceWithImage:image completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        
        if(!error) {
            // Log the uri of the staged image
            NSLog(@"Successfuly staged image with staged URI: %@", [result objectForKey:@"uri"]);
            [self presentShareDialogWithPhoto:image remoteURI:[result objectForKey:@"uri"]];
            
        } else {
            [self handleError:error];
        }
    }];
}

- (void)presentShareDialogWithPhoto:(UIImage *)image remoteURI:(NSString *)remoteURI {
    
    if ([FBDialogs canPresentShareDialogWithPhotos]) {
        
        FBPhotoParams *params = [[FBPhotoParams alloc] initWithPhotos:@[image]];
        
        [FBDialogs presentShareDialogWithPhotoParams:params clientState:nil handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
            if (error) {
                NSLog(@"Error: %@", error.description);
            } else {
                NSLog(@"Success!");
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }];
    } else {
        // The user doesn't have the Facebook for iOS app installed.  You
        // may be able to use a fallback.
        NSLog(@"Problem!");
        [self postOpenGraphStoryWithPhoto:image remoteURI:remoteURI];
    }
}

- (void)postOpenGraphStoryWithPhoto:(UIImage *)image remoteURI:(NSString *)remoteURI {
    
    NSMutableDictionary<FBGraphObject> *action = [FBGraphObject graphObject];
    action[@"user"] = [PFUser currentUser];
    
    [FBRequestConnection startForPostWithGraphPath:@"me/cuddlrapp:cuddle" graphObject:action completionHandler:^(FBRequestConnection *connection,id result, NSError *error) {

        if (!error) {
            
            NSMutableDictionary<FBOpenGraphObject>* object = [self openGraphObjectForRemoteURI:remoteURI];
            
            [FBRequestConnection startForPostOpenGraphObject:object completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                
                if (!error) {
                    
                    // get the object ID for the Open Graph object that is now stored in the Object API
                    NSString *objectId = [result objectForKey:@"id"];
                    NSLog(@"object id: %@", objectId);
                    
                } else {
                    [self handleError:error];
                }
            }];
        } else {
            [self handleError:error];
        }
    }];
}

- (NSMutableDictionary<FBOpenGraphObject> *)openGraphObjectForRemoteURI:(NSString *)remoteURI {
    
    NSString *title = [NSString stringWithFormat:@"%@ just cuddled with Cuddlr!", [PFUser currentUser].username];
#warning Need description
    NSString *description = @"";
    NSArray *imageArray = @[@{@"url": remoteURI, @"user_generated" : @"true" }];
#warning Replace FB page or iTunes URL
    NSString *url = @"cuddlrAppURL.com";
    
    NSMutableDictionary<FBOpenGraphObject> *object = [FBGraphObject openGraphObjectForPostWithType:@"cuddlrapp:cuddle" title:title image:imageArray url:url description:description];
    return object;
}

- (void)handleError:(NSError *)error {
    // See https://developers.facebook.com/docs/ios/errors/
    if ([FBErrorUtility shouldNotifyUserForError:error]) {
        [[[UIAlertView alloc] initWithTitle:@"Network error" message:[FBErrorUtility userMessageForError:error] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

@end
