LTInstapaperAPI
===============

This class provides a simple interface to the [Instapaper
API](http://www.instapaper.com/api). It provides a method for each of the
APIs, to which requests are sent asynchronously, and a delegate protocol is
used to let the caller know when the requests have finished. It was developed
for iOS, but may well work on Mac OS X, too. The only prerequisite is
[NSData+Base64](http://cocoawithlove.com/2009/06/base64-encoding-options-on-mac-and.html).

Instance Methods
----------------

### initWithUsername:password:delegate ###

    - (id)initWithUsername:(NSString *)username password:(NSString *)password delegate:(id<LTInstapaperAPIDelegate>)delegate;

#### Paramaters ####

*username* -
Email address or username to use to authenticate to Instapaper.

*password* -
Password to use to authenticate to Instapaper. May be `nil`.

*delegate* -
The delegate of the LTInstapaperAPI object.

#### Discussion ####

The password is optional. You'll want to implement an LTInstapaperAPIDelegate
to handle the success or failure of your API calls.

### authenticate ###

    - (void)authenticate;

#### Discussion ####

Authenticates to the Instapaper API. The authentication call will be made
asynchronously. Upon completion, the `instapaper:authDidFinishWithCode:`
delegate method will be called.

### addURL: ###

    - (void)addURL:(NSString *)url;

#### Paramaters ####

*url* -
String representation of the URL to be added to Instapaper.

#### Discussion ####

Adds a URL to Instapaper. The API call will be made asynchronously. Upon
completion, the `instapaper:addDidFinishWithCode:` delegate method will be
called.

### addURL:title: ###

    - (void)addURL:(NSString *)url title:(NSString *)title;

#### Paramaters ####

*url* -
String representation of the URL to be added to Instapaper.

*title* -
Title to be associated with the URL.

#### Discussion ####

Adds a URL and associated title to Instapaper. The API call will be made
asynchronously. Upon completion, the `instapaper:addDidFinishWithCode:`
delegate method will be called.

### addURL:title:selection ###

    - (void)addURL:(NSString *)url title:(NSString *)title selection:(NSString *)selection;

#### Paramaters ####

*url* -
String representation of the URL to be added to Instapaper.

*title* -
Title to be associated with the URL.

*selection* -
Text to be displayed as the description for the URL in the
Instapaper interface.

#### Discussion ####

Adds a URL and associated title and selection to Instapaper. The API call will
be made asynchronously. Upon completion, the
`instapaper:addDidFinishWithCode:` delegate method will be called.

Delegate Methods
----------------

### instapaper:authDidFinishWithCode: ###

    - (void) instapaper:(LTInstapaperAPI *)instapaper authDidFinishWithCode:(NSUInteger)code;

#### Paramaters ####

*instapaper* -
Instance of LTInstapaperAPI that made the authentication API call.

*code* -
The status code returned by the Instapaper API. As of this writing, the
possible values are:

* **200**: OK
* **403**: Invalid username or password.
* **500**: The service encountered an error. Please try again later.

#### Discussion ####

It's important to check the status code to determine the outcome of the API
call. If the code is 200, save the username and password. If it's 403, prompt
the user again. And if it's 500, suggest that they try again later.

### instapaper:addDidFinishWithCode: ###

    - (void) instapaper:(LTInstapaperAPI *)instapaper addDidFinishWithCode:(NSUInteger)code;

#### Paramaters ####

*instapaper* -
Instance of LTInstapaperAPI that made the authentication API call.

*code* -
The status code returned by the Instapaper API. As of this writing, the
possible values are:

* **201**: This URL has been successfully added to this Instapaper account.
* **400**: Bad request or exceeded the rate limit. Probably missing a required
  parameter, such as `url`.
* **403**: Invalid username or password.
* **500**: The service encountered an error. Please try again later.

#### Discussion ####

It's important to check the status code to determine the outcome of the API
call. If the code is 201, you're done. If it's 400, warn the user that she may
have exceeded Instapaper's rate limit and to try again later. If it's 403,
prompt the user for username and password again. And if it's 500, suggest that
they try again later.

Example
-------

Here's a quick example using the authentication API call:

    - (IBAction)login {
        [super login];
        LTInstapaperAPI *ipaper = [[LTInstapaperAPI alloc]
            initWithUsername:username
                    password:password
                    delegate:self];
        self.instapaper = ipaper;
        [ipaper release];
        [instapaper authenticate];
    }

    - (void)instapaper:(LTInstapaperAPI *)ip authDidFinishWithCode:(NSUInteger)code {
        // http://www.instapaper.com/api
        if (code == 200) {
            [self succeeded];
        } else {
            NSString *message = NSLocalizedString(code == 403
                ? @"Invalid username or password. Please try again."
                : @"The service encountered an error. Please try again later.",
                @""
            );
            [self authFailedWithMessage:message];
        }
    }

Use of the add API is much the same. For storage of the username and password,
you can store the former wherever you like. But I strongly recommend storing
the password in the keychain. The simplest way to do so is to use
[SFHFKeychainUtils](https://github.com/ldandersen/scifihifi-iphone/tree/master/security).
An example of how the `succeeded:` method above might be implemented:

    #import "SFHFKeychainUtils.h"

    - (void)succeeded {
        NSError *error = nil;
        [SFHFKeychainUtils storeUsername:username
                             andPassword:password
                          forServiceName:@"Instapaper" updateExisting:YES error:&error];
        if (error == nil) {
            // All good. Save the username and return.
            [[NSUserDefaults standardUserDefaults] setObject:usernameTextField.text forKey:self.usernameKey];
        } else {
            // Hrm, something went wrong. Try again.
            UIAlertView *alert = [[UIAlertView alloc]
                  initWithTitle:@"Keychain Error"
                        message:@"Hrm, something went wrong with the keychain. Please try again"
                       delegate:nil
              cancelButtonTitle:@"Okay"
              otherButtonTitles:nil];
            [alert show];
            [alert autorelease];
        }
    }

Author
------

[David E. Wheeler](http://www.justatheory.com).

Copyright & License
-------------------

Copyright (c) 2011, Lunar/Theory, LLC.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer. Redistributions in binary
form must reproduce the above copyright notice, this list of conditions and
the following disclaimer in the documentation and/or other materials provided
with the distribution. Neither the name of the Lunar/Theory, LLC nor the names
of its contributors may be used to endorse or promote products derived from
this software without specific prior written permission. THIS SOFTWARE IS
PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
