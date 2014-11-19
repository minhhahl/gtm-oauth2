TrustingSocial OAuth2 intergration for iOS
==========

git mirror of http://code.google.com/p/gtm-oauth2/

This is demo app for http://TrustingSocial.com OAuth2

Demo features
========
1. Signup with TrustingSocial from iOS app
2. Get user's TrustingSocial score

Run sample project
========
    git clone git@github.com:minhhahl/gtm-oauth2.git

Open `gtm-oauth2/Examples/OAuth2SampleTouch/OAuth2SampleTouch.xcodeproj`

Note: In this sample project, I had added AppID and AppSecret so you could run it without any setup.

Run on Simulator

Touch `Sign In` button -> Login to your Facebook account -> Login successfully

Waiting about 5-10 seconds for TrustingSocial to process your score

Touch `Fetch score` button to show your TrustingSocial score

Register your TrustingSocial Application
========
Goto https://trustingsocial.com/developer

Signup with Facebook to become TrustingSocial developer.

Create new application

Open file `gtm-oauth2/Examples/OAuth2SampleTouch/OAuth2SampleRootViewControllerTouch.m`

Replace this part with your App info:

    //Test app
    static NSString *const kTrustingSocialClientID = @"10d830d2bb47b36a16b79cd4eaf85b05205128648422a694c10737facf2a883a";
    static NSString *const kTrustingSocialClientSecret = @"580725dcb65c248ddb39296415d105f8975349cae55983429bdea7f3fad8d564";
    // Redirect URL for mobile application is not need to be a real web url but It need to match with your Redirect uri
    static NSString *const kTrustingSocialRedirectUrl = @"http://mobile.com/oAuthCallback";
    // ----

Base on this demo you could intergrate TrustingSocial score in your iOS app now.

Visit website http://trustingsocial.com to know more about TrustingSocial score.

Try your TrustingSocial score on website here http://trustingsocial.com/demo
