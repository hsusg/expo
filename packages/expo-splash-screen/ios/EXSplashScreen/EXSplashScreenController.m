// Copyright © 2018 650 Industries. All rights reserved.

#import <EXSplashScreen/EXSplashScreenController.h>
#import <UMCore/UMDefines.h>
#import <UMCore/UMUtilities.h>

@interface EXSplashScreenController ()

@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, strong) UIView *splashScreenView;

@property (nonatomic, weak) NSTimer *warningTimer;

@property (nonatomic, assign) BOOL autoHideEnabled;
@property (nonatomic, assign) BOOL splashScreenShown;
@property (nonatomic, assign) BOOL appContentAppeared;


@end

@implementation EXSplashScreenController

- (instancetype)initWithViewController:(UIViewController *)viewController
              splashScreenViewProvider:(id<EXSplashScreenViewProvider>)splashScreenViewProvider
{
  if (self = [super init]) {
    _viewController = viewController;
    _autoHideEnabled = YES;
    _splashScreenShown = NO;
    _appContentAppeared = NO;
    _splashScreenView = [splashScreenViewProvider createSplashScreenView];
  }
  return self;
}

# pragma mark public methods

- (void)showWithCallback:(void (^)(void))successCallback failureCallback:(void (^)(NSString * _Nonnull))failureCallback
{
  [self showWithCallback:successCallback];
}

- (void)showWithCallback:(nullable void(^)(void))successCallback
{
  [UMUtilities performSynchronouslyOnMainThread:^{
    UIView *rootView = self.viewController.view;
    self.splashScreenView.frame = rootView.bounds;
    [rootView addSubview:self.splashScreenView];
    self.splashScreenShown = YES;
    
    self.warningTimer = [NSTimer scheduledTimerWithTimeInterval:20.0
                                                         target:self
                                                       selector:@selector(showSplashScreenVisibleWarning)
                                                       userInfo:nil
                                                        repeats:NO];
    
    if (successCallback) {
      successCallback();
    }
  }];
}

-(void)showSplashScreenVisibleWarning
{
  
#if DEBUG
  UIView *warningView = [UIView new];
  CGRect warningViewFrame = CGRectMake(0, self.splashScreenView.bounds.size.height - 400, self.splashScreenView.bounds.size.width, 200);
  warningView.frame = warningViewFrame;

  UILabel *warningLabel = [[UILabel alloc] init];
  warningLabel.frame =  CGRectMake(warningViewFrame.origin.x, warningViewFrame.origin.y, warningViewFrame.size.width - 32.0f, 100);
  warningLabel.center = CGPointMake(warningViewFrame.size.width / 2, warningViewFrame.size.height / 2 - 50);

  warningLabel.text = @"Looks like the splash screen has been visible for over 20 seconds - did you forget to hide it?";
  warningLabel.numberOfLines = 0;
  warningLabel.font = [UIFont systemFontOfSize:16.0f];
  warningLabel.textColor = [UIColor darkGrayColor];
  warningLabel.textAlignment = NSTextAlignmentCenter;
  [warningView addSubview: warningLabel];

  [self.splashScreenView addSubview: warningView];
#endif
}

- (void)preventAutoHideWithCallback:(void (^)(BOOL))successCallback failureCallback:(void (^)(NSString * _Nonnull))failureCallback
{
  if (!_autoHideEnabled) {
    return successCallback(NO);
  }

  if (!_splashScreenShown) {
    return failureCallback(@"Native splash screen is already hidden. Call this method before rendering any view.");
  }

  _autoHideEnabled = NO;
  successCallback(YES);
}

- (void)hideWithCallback:(void (^)(BOOL))successCallback failureCallback:(void (^)(NSString * _Nonnull))failureCallback
{
  if (!_splashScreenShown) {
    return successCallback(NO);
  }
  
  [self hideWithCallback:successCallback];
}

- (void)hideWithCallback:(nullable void(^)(BOOL))successCallback
{
  UM_WEAKIFY(self);
  dispatch_async(dispatch_get_main_queue(), ^{
    UM_ENSURE_STRONGIFY(self);
    [self.splashScreenView removeFromSuperview];
    self.splashScreenShown = NO;
    self.autoHideEnabled = YES;
    [self.warningTimer invalidate];
    if (successCallback) {
      successCallback(YES);
    }
  });
}

- (void)onAppContentDidAppear
{
  if (!_appContentAppeared && _autoHideEnabled) {
    _appContentAppeared = YES;
    [self hideWithCallback:nil];
  }
}

- (void)onAppContentWillReload
{
  if (!_appContentAppeared) {
    _autoHideEnabled = YES;
    _appContentAppeared = NO;
    [self showWithCallback:nil];
  }
}

@end
