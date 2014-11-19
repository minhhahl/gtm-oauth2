/* Copyright (c) 2011 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// OAuth2SampleRootViewControllerTouch.m

#import "OAuth2SampleRootViewControllerTouch.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "GTMOAuth2SignIn.h"

static NSString *const kKeychainItemName = @"OAuth Sample: Google Contacts";
static NSString *const kShouldSaveInKeychainKey = @"shouldSaveInKeychain";

static NSString *const kTrustingSocialAppServiceName = @"OAuth Sample: TrustingSocial";
static NSString *const kTrustingSocialServiceName = @"TrustingSocial";

static NSString *kTrustingSocialDomain = @"https://trustingsocial.com";
//static NSString *kTrustingSocialDomain = @"http://localhost:3000";
#define kTrustingSocialTokenUrl [NSString stringWithFormat:@"%@/oauth/token", kTrustingSocialDomain]
#define kTrustingSocialAuthorizeUrl [NSString stringWithFormat:@"%@/oauth/authorize", kTrustingSocialDomain]

#warning "Replace with your TrustingSocial app"
// Signup TrustingSocial developer account on
// https://trustingsocial.com/developer
// Create application or view developer api to know more about TrustingSocial api

//local
//static NSString *const kTrustingSocialClientID = @"5c8f7b23743932f94ad734e5b5619b39f57e02f3a1232cfbb195cbef56d99aa4";
//static NSString *const kTrustingSocialClientSecret = @"1aeb66e5b527cf993369a1b9f1452316a61ce2fb3e16d93e93393e9bc0c34271";
// Redirect URL for mobile application is not need to be a real web url but I need to match with your Redirect uri
//static NSString *const kTrustingSocialRedirectUrl = @"http://localhost:3001/users/auth/trustingsocial/callback";

//Test app
static NSString *const kTrustingSocialClientID = @"10d830d2bb47b36a16b79cd4eaf85b05205128648422a694c10737facf2a883a";
static NSString *const kTrustingSocialClientSecret = @"580725dcb65c248ddb39296415d105f8975349cae55983429bdea7f3fad8d564";
// Redirect URL for mobile application is not need to be a real web url but I need to match with your Redirect uri
static NSString *const kTrustingSocialRedirectUrl = @"http://mobile.com/oAuthCallback";
// ----

@interface OAuth2SampleRootViewControllerTouch()
- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)auth
                 error:(NSError *)error;
- (void)incrementNetworkActivity:(NSNotification *)notify;
- (void)decrementNetworkActivity:(NSNotification *)notify;
- (void)signInNetworkLostOrFound:(NSNotification *)notify;
- (GTMOAuth2Authentication *)authForTrustingSocial;
- (void)doAnAuthenticatedAPIFetch;
- (void)displayAlertWithMessage:(NSString *)str;
- (BOOL)shouldSaveInKeychain;
- (void)saveClientIDValues;
- (void)loadClientIDValues;

@end

@implementation OAuth2SampleRootViewControllerTouch

@synthesize clientIDField = mClientIDField,
            clientSecretField = mClientSecretField,
            serviceNameField = mServiceNameField,
            emailField = mEmailField,
            expirationField = mExpirationField,
            accessTokenField = mAccessTokenField,
            refreshTokenField = mRefreshTokenField,
            fetchButton = mFetchButton,
            expireNowButton = mExpireNowButton,
            serviceSegments = mServiceSegments,
            shouldSaveInKeychainSwitch = mShouldSaveInKeychainSwitch,
            signInOutButton = mSignInOutButton;

@synthesize auth = mAuth;

// NSUserDefaults keys
static NSString *const kGoogleClientIDKey          = @"GoogleClientID";
static NSString *const kGoogleClientSecretKey      = @"GoogleClientSecret";
static NSString *const kTrustingSocialClientIDKey     = @"TrustingSocialClientID";
static NSString *const kTrustingSocialClientSecretKey = @"TrustingSocialClientSecret";

- (void)saveTrustingSocialClientInfo {
    // Save the client ID and secret from the text fields into the prefs
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([defaults stringForKey:kTrustingSocialClientIDKey].length == 0)
    {
        [defaults setObject:kTrustingSocialClientID forKey:kTrustingSocialClientIDKey];
        [defaults setObject:kTrustingSocialClientSecret forKey:kTrustingSocialClientSecretKey];
    }
}

- (void)awakeFromNib {
    [self saveTrustingSocialClientInfo];
    [self.serviceSegments addTarget:self action:@selector(serviceChanged:) forControlEvents:UIControlEventValueChanged];
    
  // Listen for network change notifications
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self selector:@selector(incrementNetworkActivity:) name:kGTMOAuth2WebViewStartedLoading object:nil];
  [nc addObserver:self selector:@selector(decrementNetworkActivity:) name:kGTMOAuth2WebViewStoppedLoading object:nil];
  [nc addObserver:self selector:@selector(incrementNetworkActivity:) name:kGTMOAuth2FetchStarted object:nil];
  [nc addObserver:self selector:@selector(decrementNetworkActivity:) name:kGTMOAuth2FetchStopped object:nil];
  [nc addObserver:self selector:@selector(signInNetworkLostOrFound:) name:kGTMOAuth2NetworkLost  object:nil];
  [nc addObserver:self selector:@selector(signInNetworkLostOrFound:) name:kGTMOAuth2NetworkFound object:nil];

    self.serviceSegments.selectedSegmentIndex = 1;
    [self.serviceSegments sendActionsForControlEvents:UIControlEventValueChanged];
    
  // Fill in the Client ID and Client Secret text fields
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  // First, we'll try to get the saved Google authentication, if any, from
  // the keychain

  // Normal applications will hardcode in their client ID and client secret,
  // but the sample app allows the user to enter them in a text field, and
  // saves them in the preferences
  NSString *clientID = [defaults stringForKey:kGoogleClientIDKey];
  NSString *clientSecret = [defaults stringForKey:kGoogleClientSecretKey];

  GTMOAuth2Authentication *auth = nil;

  if (clientID && clientSecret) {
    auth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName
                                                                      clientID:clientID
                                                                  clientSecret:clientSecret];
      
      if (auth.canAuthorize) {
          // Select the Google service segment
          self.serviceSegments.selectedSegmentIndex = 0;
        [self.serviceSegments sendActionsForControlEvents:UIControlEventValueChanged];
      } else {
          auth = nil;
      }
  }

  
  if (auth == nil) {
    // There is no saved Google authentication
    //
    // Perhaps we have a saved authorization for TrustingSocial instead; try getting
    // that from the keychain

    clientID = [defaults stringForKey:kTrustingSocialClientIDKey];
    clientSecret = [defaults stringForKey:kTrustingSocialClientSecretKey];

    if (clientID && clientSecret) {
      auth = [self authForTrustingSocial];
      if (auth) {
        auth.clientID = clientID;
        auth.clientSecret = clientSecret;

        BOOL didAuth = [GTMOAuth2ViewControllerTouch authorizeFromKeychainForName:kTrustingSocialAppServiceName
                                                                   authentication:auth
                                                                            error:NULL];
        if (didAuth) {
          // select the TrustingSocial radio button
          self.serviceSegments.selectedSegmentIndex = 1;
          [self.serviceSegments sendActionsForControlEvents:UIControlEventValueChanged];
        }
      }
    }
  }

  // Save the authentication object, which holds the auth tokens and
  // the scope string used to obtain the token.  For Google services,
  // the auth object also holds the user's email address.
  self.auth = auth;

  // Update the client ID value text fields to match the radio button selection
  [self loadClientIDValues];

  BOOL isRemembering = [self shouldSaveInKeychain];
  self.shouldSaveInKeychainSwitch.on = isRemembering;
  [self updateUI];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [mServiceSegments release];
  [mClientIDField release];
  [mClientSecretField release];
  [mServiceNameField release];
  [mEmailField release];
  [mAccessTokenField release];
  [mExpirationField release];
  [mRefreshTokenField release];
  [mFetchButton release];
  [mExpireNowButton release];
  [mShouldSaveInKeychainSwitch release];
  [mSignInOutButton release];
  [mAuth release];

  [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
  // Returns non-zero on iPad, but backward compatible to SDKs earlier than 3.2.
  if (UI_USER_INTERFACE_IDIOM()) {
    return YES;
  }
  return [super shouldAutorotateToInterfaceOrientation:orientation];
}

- (BOOL)isSignedIn {
  BOOL isSignedIn = self.auth.canAuthorize;
  return isSignedIn;
}

- (BOOL)isGoogleSegmentSelected {
  NSInteger segmentIndex = self.serviceSegments.selectedSegmentIndex;
  return (segmentIndex == 0);
}

- (void)serviceChanged:(id)sender {
    [mFetchButton setTitle:([self isGoogleSegmentSelected] ? @"Fetch Feed" : @"Fetch Score") forState:UIControlStateNormal];
}

- (IBAction)serviceSegmentClicked:(id)sender {
  [self loadClientIDValues];
}

- (IBAction)signInOutClicked:(id)sender {
  [self saveClientIDValues];

  if (![self isSignedIn]) {
    // Sign in
    if ([self isGoogleSegmentSelected]) {
      [self signInToGoogle];
    } else {
      [self signInToTrustingSocial];
    }
  } else {
    // Sign out
    [self signOut];
  }
  [self updateUI];
}

- (IBAction)fetchClicked:(id)sender {
  // Just to prove we're signed in, we'll attempt an authenticated fetch for the
  // signed-in user
  [self doAnAuthenticatedAPIFetch];
}

- (IBAction)expireNowClicked:(id)sender {
  NSDate *date = self.auth.expirationDate;
  if (date) {
    self.auth.expirationDate = [NSDate dateWithTimeIntervalSince1970:0];
    [self updateUI];
  }
}

// UISwitch does the toggling for us. We just need to read the state.
- (IBAction)toggleShouldSaveInKeychain:(UISwitch *)sender {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setBool:sender.isOn forKey:kShouldSaveInKeychainKey];
}

- (void)signOut {
  if ([self.auth.serviceProvider isEqual:kGTMOAuth2ServiceProviderGoogle]) {
    // remove the token from Google's servers
    [GTMOAuth2ViewControllerTouch revokeTokenForGoogleAuthentication:self.auth];
  }

  // remove the stored Google authentication from the keychain, if any
  [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kKeychainItemName];

  // remove the stored TrustingSocial authentication from the keychain, if any
  [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kTrustingSocialAppServiceName];

  // Discard our retained authentication object.
  self.auth = nil;

  [self updateUI];
}

- (void)signInToGoogle {
  [self signOut];

  NSString *keychainItemName = nil;
  if ([self shouldSaveInKeychain]) {
    keychainItemName = kKeychainItemName;
  }

  // For Google APIs, the scope strings are available
  // in the service constant header files.
  NSString *scope = @"https://www.googleapis.com/auth/plus.me";

  // Typically, applications will hardcode the client ID and client secret
  // strings into the source code; they should not be user-editable or visible.
  //
  // But for this sample code, they are editable.
  NSString *clientID = self.clientIDField.text;
  NSString *clientSecret = self.clientSecretField.text;

  if ([clientID length] == 0 || [clientSecret length] == 0) {
    NSString *msg = @"The sample code requires a valid client ID and client secret to sign in.";
    [self displayAlertWithMessage:msg];
    return;
  }

  // Note:
  // GTMOAuth2ViewControllerTouch is not designed to be reused. Make a new
  // one each time you are going to show it.

  // Display the autentication view.
  SEL finishedSel = @selector(viewController:finishedWithAuth:error:);

  GTMOAuth2ViewControllerTouch *viewController;
  viewController = [GTMOAuth2ViewControllerTouch controllerWithScope:scope
                                                            clientID:clientID
                                                        clientSecret:clientSecret
                                                    keychainItemName:keychainItemName
                                                            delegate:self
                                                    finishedSelector:finishedSel];

  // You can set the title of the navigationItem of the controller here, if you
  // want.

  // If the keychainItemName is not nil, the user's authorization information
  // will be saved to the keychain. By default, it saves with accessibility
  // kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly, but that may be
  // customized here. For example,
  //
  //   viewController.keychainItemAccessibility = kSecAttrAccessibleAlways;

  // During display of the sign-in window, loss and regain of network
  // connectivity will be reported with the notifications
  // kGTMOAuth2NetworkLost/kGTMOAuth2NetworkFound
  //
  // See the method signInNetworkLostOrFound: for an example of handling
  // the notification.

  // Optional: Google servers allow specification of the sign-in display
  // language as an additional "hl" parameter to the authorization URL,
  // using BCP 47 language codes.
  //
  // For this sample, we'll force English as the display language.
  NSDictionary *params = [NSDictionary dictionaryWithObject:@"en"
                                                     forKey:@"hl"];
  viewController.signIn.additionalAuthorizationParameters = params;

  // By default, the controller will fetch the user's email, but not the rest of
  // the user's profile.  The full profile can be requested from Google's server
  // by setting this property before sign-in:
  //
  //   viewController.signIn.shouldFetchGoogleUserProfile = YES;
  //
  // The profile will be available after sign-in as
  //
  //   NSDictionary *profile = viewController.signIn.userProfile;

  // Optional: display some html briefly before the sign-in page loads
  NSString *html = @"<html><body bgcolor=silver><div align=center>Loading sign-in page...</div></body></html>";
  viewController.initialHTMLString = html;

  [[self navigationController] pushViewController:viewController animated:YES];

  // The view controller will be popped before signing in has completed, as
  // there are some additional fetches done by the sign-in controller.
  // The kGTMOAuth2UserSignedIn notification will be posted to indicate
  // that the view has been popped and those additional fetches have begun.
  // It may be useful to display a temporary UI when kGTMOAuth2UserSignedIn is
  // posted, just until the finished selector is invoked.
}

- (GTMOAuth2Authentication *)authForTrustingSocial {
  // https://trustingsocial.com/api
  NSURL *tokenURL = [NSURL URLWithString:kTrustingSocialTokenUrl];

  // We'll make up an arbitrary redirectURI.  The controller will watch for
  // the server to redirect the web view to this URI, but this URI will not be
  // loaded, so it need not be for any actual web page.
  NSString *redirectURI = kTrustingSocialRedirectUrl;

  NSString *clientID = self.clientIDField.text;
  NSString *clientSecret = self.clientSecretField.text;
    
    if (clientID.length == 0) {
        clientID = kTrustingSocialClientIDKey;
    }
    
    if (clientSecret.length == 0) {
        clientSecret = kTrustingSocialClientSecretKey;
    }

  GTMOAuth2Authentication *auth;
  auth = [GTMOAuth2Authentication authenticationWithServiceProvider:kTrustingSocialServiceName
                                                           tokenURL:tokenURL
                                                        redirectURI:redirectURI
                                                           clientID:clientID
                                                       clientSecret:clientSecret];
  return auth;
}

- (void)signInToTrustingSocial {
  [self signOut];

  GTMOAuth2Authentication *auth = [self authForTrustingSocial];
//    TrustingSocial do not use scope at this time
//  auth.scope = @"public";

  if ([auth.clientID length] == 0 || [auth.clientSecret length] == 0) {
    NSString *msg = @"The sample code requires a valid client ID and client secret to sign in.";
    [self displayAlertWithMessage:msg];
    return;
  }

  NSString *keychainItemName = nil;
  if ([self shouldSaveInKeychain]) {
    keychainItemName = kKeychainItemName;
  }

  NSURL *authURL = [NSURL URLWithString:kTrustingSocialAuthorizeUrl];

  // Display the authentication view
  SEL sel = @selector(viewController:finishedWithAuth:error:);

  GTMOAuth2ViewControllerTouch *viewController;
  viewController = [GTMOAuth2ViewControllerTouch controllerWithAuthentication:auth
                                                             authorizationURL:authURL
                                                             keychainItemName:keychainItemName
                                                                     delegate:self
                                                             finishedSelector:sel];

  // We can set a URL for deleting the cookies after sign-in so the next time
  // the user signs in, the browser does not assume the user is already signed
  // in
  viewController.browserCookiesURL = [NSURL URLWithString:kTrustingSocialDomain];

  // You can set the title of the navigationItem of the controller here, if you want

  // Now push our sign-in view
  [[self navigationController] pushViewController:viewController animated:YES];
}

- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)auth
                 error:(NSError *)error {
  if (error != nil) {
    // Authentication failed (perhaps the user denied access, or closed the
    // window before granting access)
    NSLog(@"Authentication error: %@", error);
    NSData *responseData = [[error userInfo] objectForKey:@"data"]; // kGTMHTTPFetcherStatusDataKey
    if ([responseData length] > 0) {
      // show the body of the server's authentication failure response
      NSString *str = [[[NSString alloc] initWithData:responseData
                                             encoding:NSUTF8StringEncoding] autorelease];
      NSLog(@"%@", str);
    }

    self.auth = nil;
  } else {
    // Authentication succeeded
    //
    // At this point, we either use the authentication object to explicitly
    // authorize requests, like
    //
    //  [auth authorizeRequest:myNSURLMutableRequest
    //       completionHandler:^(NSError *error) {
    //         if (error == nil) {
    //           // request here has been authorized
    //         }
    //       }];
    //
    // or store the authentication object into a fetcher or a Google API service
    // object like
    //
    //   [fetcher setAuthorizer:auth];

    // save the authentication object
    self.auth = auth;
  }

  [self updateUI];
}

- (void)doAnAuthenticatedAPIFetch {
  NSString *urlStr;
  if ([self isGoogleSegmentSelected]) {
    // Google Plus feed
    urlStr = @"https://www.googleapis.com/plus/v1/people/me/activities/public";
  } else {
    // TrustingSocial score
    urlStr = [NSString stringWithFormat:@"%@/v1/me", kTrustingSocialDomain];
  }

  NSURL *url = [NSURL URLWithString:urlStr];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  [self.auth authorizeRequest:request
            completionHandler:^(NSError *error) {
              NSString *output = nil;
              if (error) {
                output = [error description];
              } else {
                // Synchronous fetches like this are a really bad idea in Cocoa applications
                //
                // For a very easy async alternative, we could use GTMHTTPFetcher
                NSURLResponse *response = nil;
                NSData *data = [NSURLConnection sendSynchronousRequest:request
                                                     returningResponse:&response
                                                                 error:&error];
                if (data) {
                  // API fetch succeeded
                  output = [[[NSString alloc] initWithData:data
                                                  encoding:NSUTF8StringEncoding] autorelease];
                } else {
                  // fetch failed
                  output = [error description];
                }
              }

              [self displayAlertWithMessage:output];

              // the access token may have changed
              [self updateUI];
            }];
}

#pragma mark -

- (void)incrementNetworkActivity:(NSNotification *)notify {
  ++mNetworkActivityCounter;
  if (mNetworkActivityCounter == 1) {
    UIApplication *app = [UIApplication sharedApplication];
    [app setNetworkActivityIndicatorVisible:YES];
  }
}

- (void)decrementNetworkActivity:(NSNotification *)notify {
  --mNetworkActivityCounter;
  if (mNetworkActivityCounter == 0) {
    UIApplication *app = [UIApplication sharedApplication];
    [app setNetworkActivityIndicatorVisible:NO];
  }
}

- (void)signInNetworkLostOrFound:(NSNotification *)notify {
  if ([[notify name] isEqual:kGTMOAuth2NetworkLost]) {
    // network connection was lost; alert the user, or dismiss
    // the sign-in view with
    //   [[[notify object] delegate] cancelSigningIn];
  } else {
    // network connection was found again
  }
}

#pragma mark -

- (void)updateUI {
  // update the text showing the signed-in state and the button title
  // A real program would use NSLocalizedString() for strings shown to the user.
  if ([self isSignedIn]) {
    // signed in
    self.serviceNameField.text = self.auth.serviceProvider;
    self.emailField.text = self.auth.userEmail;
    self.accessTokenField.text = self.auth.accessToken;
    self.expirationField.text = [self.auth.expirationDate description];
    self.refreshTokenField.text = self.auth.refreshToken;

    self.signInOutButton.title = @"Sign Out";
    self.fetchButton.enabled = YES;
    self.expireNowButton.enabled = YES;
  } else {
    // signed out
    self.serviceNameField.text = @"-Not signed in-";
    self.emailField.text = @"";
    self.accessTokenField.text = @"-No access token-";
    self.expirationField.text = @"";
    self.refreshTokenField.text = @"-No refresh token-";

    self.signInOutButton.title = @"Sign In";
    self.fetchButton.enabled = NO;
    self.expireNowButton.enabled = NO;
  }

  BOOL isRemembering = [self shouldSaveInKeychain];
  self.shouldSaveInKeychainSwitch.on = isRemembering;
}

- (void)displayAlertWithMessage:(NSString *)message {
  UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"OAuth2Sample"
                                                   message:message
                                                  delegate:nil
                                         cancelButtonTitle:@"OK"
                                         otherButtonTitles:nil] autorelease];
  [alert show];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
  [self saveClientIDValues];
}

- (BOOL)shouldSaveInKeychain {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  BOOL flag = [defaults boolForKey:kShouldSaveInKeychainKey];
  return flag;
}

#pragma mark Client ID and Secret

//
// Normally an application will hardwire the client ID and client secret
// strings in the source code.  This sample app has to allow them to be
// entered by the developer, so we'll save them across runs into preferences.
//

- (void)saveClientIDValues {
  // Save the client ID and secret from the text fields into the prefs
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *clientID = self.clientIDField.text;
  NSString *clientSecret = self.clientSecretField.text;

  if ([self isGoogleSegmentSelected]) {
    [defaults setObject:clientID forKey:kGoogleClientIDKey];
    [defaults setObject:clientSecret forKey:kGoogleClientSecretKey];
  } else {
    [defaults setObject:clientID forKey:kTrustingSocialClientIDKey];
    [defaults setObject:clientSecret forKey:kTrustingSocialClientSecretKey];
  }
}

- (void)loadClientIDValues {
  // Load the client ID and secret from the prefs into the text fields
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  if ([self isGoogleSegmentSelected]) {
    self.clientIDField.text = [defaults stringForKey:kGoogleClientIDKey];
    self.clientSecretField.text = [defaults stringForKey:kGoogleClientSecretKey];
  } else {
    self.clientIDField.text = [defaults stringForKey:kTrustingSocialClientIDKey];
    self.clientSecretField.text = [defaults stringForKey:kTrustingSocialClientSecretKey];
  }
}

@end
