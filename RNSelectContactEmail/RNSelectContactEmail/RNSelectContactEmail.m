//
//  RNSelectContactEmail.m
//  RNSelectContactEmail
//
//  Created by Ross Haker on 10/22/15.
//  Copyright (c) 2015 Facebook. All rights reserved.
//

#import "RNSelectContactEmail.h"

@implementation RNSelectContactEmail

// Expose this module to the React Native bridge
RCT_EXPORT_MODULE()

// Persist data
RCT_EXPORT_METHOD(selectEmail:(BOOL *)boolType
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    
    // save the resolve promise
    self.resolve = resolve;
    
    // set up an error message
    NSError *error = [
                      NSError errorWithDomain:@"some_domain"
                      code:200
                      userInfo:@{
                                 NSLocalizedDescriptionKey:@"ios8 or higher required"
                                 }];
    
    
    // detect the ios version
    NSString *ver = [[UIDevice currentDevice] systemVersion];
    float ver_float = [ver floatValue];
    
    // check that ios is version 8.0 or higher
    if (ver_float < 8.0) {
        
        reject(@"500", @"ios8 or higher required", error);
        
    } else {
        
        // check permissions
        if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied ||
            ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusRestricted){
            
            // permission denied
            error = [
                     NSError errorWithDomain:@"some_domain"
                     code:300
                     userInfo:@{
                                NSLocalizedDescriptionKey:@"Permissions denied by user."
                                }];
            
            reject(@"500", @"Permissions denied by user.", error);
            
        } else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized){
            
            // permission authorized
            ABPeoplePickerNavigationController *picker;
            picker = [[ABPeoplePickerNavigationController alloc] init];
            picker.peoplePickerDelegate = self;
            
            UIViewController *vc = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
            [vc presentViewController:picker animated:YES completion:nil];
            
        } else {
            
            // not determined - request permissions
            ABAddressBookRequestAccessWithCompletion(ABAddressBookCreateWithOptions(NULL, nil), ^(bool granted, CFErrorRef error) {
                
                if (!granted){
                    
                    // user denied access
                    NSError *errorDenied = [
                                            NSError errorWithDomain:@"some_domain"
                                            code:300
                                            userInfo:@{
                                                       NSLocalizedDescriptionKey:@"Permissions denied by user."
                                                       }];
                    
                    reject(@"500", @"Permissions denied by user.", errorDenied);
                    return;
                }
                
                // user authorized access
                ABPeoplePickerNavigationController *picker;
                picker = [[ABPeoplePickerNavigationController alloc] init];
                picker.peoplePickerDelegate = self;
                
                UIViewController *vc = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
                [vc presentViewController:picker animated:YES completion:nil];
                
            });
            
        }
        
    }
    
    
}

- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker didSelectPerson:(ABRecordRef)person
{
    
    // set the fields from the adddress book
    NSString *email = nil;
    
    // get the email
    if (ABRecordCopyValue(person, kABPersonPhoneProperty)) {
        ABMultiValueRef emails = (ABMultiValueRef) ABRecordCopyValue(person, kABPersonEmailProperty);
        CFStringRef emailID = ABMultiValueCopyValueAtIndex(emails, 0);
        email = (__bridge_transfer NSString *)emailID;
    }
    
    UIViewController *vc = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    [vc dismissViewControllerAnimated:YES completion:nil];
    
    // resolve the email
    self.resolve(email);
}

-(BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier{
    return NO;
}

-(void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker{
    
    UIViewController *vc = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    [vc dismissViewControllerAnimated:YES completion:nil];
}

@end
