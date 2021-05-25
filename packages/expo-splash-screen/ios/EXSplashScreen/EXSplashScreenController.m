// Copyright © 2018 650 Industries. All rights reserved.

#import <EXSplashScreen/EXSplashScreenController.h>
#import <UMCore/UMDefines.h>
#import <UMCore/UMUtilities.h>

@interface EXSplashScreenController ()

@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, strong) UIView *splashScreenView;

@property (nonatomic, weak) NSTimer *warningTimer;
@property (nonatomic, strong) UIButton *warningButton;

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
    _warningButton = [UIButton new];
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
  int warningViewHeight = 100;
  float paddingHorizontal = 32.0f;
  float marginVertical = 16.0f;
  
  UIEdgeInsets safeAreaInsets = [self.splashScreenView safeAreaInsets];
  
  CGRect warningViewFrame = CGRectMake(self.splashScreenView.bounds.origin.x + paddingHorizontal, self.splashScreenView.bounds.size.height - safeAreaInsets.bottom - warningViewHeight - marginVertical, self.splashScreenView.bounds.size.width - paddingHorizontal * 2, warningViewHeight);

  [_warningButton addTarget:self action:@selector(hideWarningView) forControlEvents:UIControlEventTouchUpInside];
  
  _warningButton.frame = warningViewFrame;
  _warningButton.backgroundColor = [UIColor whiteColor];
  _warningButton.layer.cornerRadius = 4.0f;
  _warningButton.layer.shadowRadius  = 1.5f;
  _warningButton.layer.shadowColor   = [[UIColor lightGrayColor] CGColor];
  _warningButton.layer.shadowOpacity = 0.6f;
  _warningButton.layer.shadowOffset = CGSizeMake(0, 1.5f);
  _warningButton.layer.masksToBounds = NO;
  
  int warningLabelHeight = 80;
  UILabel *warningLabel = [[UILabel alloc] init];
  warningLabel.frame = CGRectMake(warningViewFrame.origin.x, warningViewFrame.origin.y, warningViewFrame.size.width - 32.0f, warningLabelHeight);
  warningLabel.center = CGPointMake(warningViewFrame.size.width / 2, warningViewFrame.size.height / 2);
  warningLabel.text = @"Looks like the splash screen has been visible for over 20 seconds - did you forget to hide it?";
  warningLabel.numberOfLines = 0;
  warningLabel.font = [UIFont systemFontOfSize:16.0f];
  warningLabel.textColor = [UIColor darkGrayColor];
  warningLabel.textAlignment = NSTextAlignmentCenter;
  [_warningButton addSubview: warningLabel];
  
  [self.splashScreenView addSubview: _warningButton];
#endif
}

-(void)hideWarningView {
  _warningButton.hidden = true;
  [_warningButton removeFromSuperview];
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
