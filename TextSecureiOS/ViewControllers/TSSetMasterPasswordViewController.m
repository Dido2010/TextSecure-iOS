//
//  TSSetMasterPasswordViewController.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 10/12/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSSetMasterPasswordViewController.h"
#import "TSStorageError.h"
#import "TSRegisterPrekeysRequest.h"
#import "TSUserKeysDatabase.h"
#import "TSStorageMasterKey.h"
#import "TSMessagesDatabase.h"
#import "TSWaitingPushMessageDatabase.h"
#import "TSECKeyPair.h"
#import "RMStepsController.h"

#define pickPassword @"Pick your password"
#define reenterPassword @"Please re-enter your password"

@interface TSSetMasterPasswordViewController ()

@end

@implementation TSSetMasterPasswordViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.nextButton.enabled = NO;
    
    self.pass.delegate = self;
    
    self.instruction.text = pickPassword;
    self.navigationController.navigationBarHidden = YES;

}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.pass becomeFirstResponder];
}


- (IBAction) nextWasTapped:(id)sender{
    if (self.firstPass == nil) {
        self.firstPass = self.pass.text;
        self.instruction.text = reenterPassword;
        self.pass.text = @"";
		self.nextButton.enabled = NO;

    } else {
        if ([self.pass.text isEqualToString:self.firstPass]) {
            [self setupDatabase];
        } else{
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Passwords don't match" message:@"Both entered passwords don't match. Please try again." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
            self.firstPass = nil;
            self.pass.text = @"";
            [self.pass becomeFirstResponder];
            self.instruction.text = pickPassword;
        }
    }
}

- (void) setupDatabase {
    NSError *error = nil;
    
    
    // Create and store the storage master key from the user's password so we can then create DBs
    if (![TSStorageMasterKey createStorageMasterKeyWithPassword:self.pass.text error:&error]) {
        @throw [NSException exceptionWithName:@"Storage master key creation failed" reason:[error localizedDescription] userInfo:nil];
    }
    
    // Create the messages DB
    if(![TSMessagesDatabase databaseCreateWithError:&error]) {
        @throw [NSException exceptionWithName:@"Initial setup of messages DB failed" reason:[error localizedDescription] userInfo:nil];
    }
    
    // Create the user keys DB and generate the user's identity key and prekeys
    if (![TSUserKeysDatabase databaseCreateUserKeysWithError:&error]) {
        @throw [NSException exceptionWithName:@"Initial setup of cryptography keys failed" reason:[error localizedDescription] userInfo:nil];
    }
    
    if(![TSWaitingPushMessageDatabase databaseCreateWaitingPushMessageDatabaseWithError:&error]) {
        @throw [NSException exceptionWithName:@"Initial setup of waiting push message database failed" reason:[error localizedDescription] userInfo:nil];        
    }
    
    // Send the user's newly generated keys to the API
    // TODO: Error handling & retry if network error
    
    NSArray *preKeys = [TSUserKeysDatabase allPreKeys];
    TSECKeyPair *identityKey = [TSUserKeysDatabase identityKey];
    
    [[TSNetworkManager sharedManager] queueAuthenticatedRequest:[[TSRegisterPrekeysRequest alloc] initWithPrekeyArray:preKeys identityKey:identityKey] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        switch (operation.response.statusCode) {
            case 200:
            case 204:
                DLog(@"Device registered prekeys");
                break;
                
            default:
                DLog(@"Issue registering prekeys response %ld, %@",operation.response.statusCode,operation.response.description);
#warning Add error handling if not able to send the prekeys
                break;
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
#warning Add error handling if not able to send the token
        DLog(@"failure %ld, %@",operation.response.statusCode,operation.response.description);
    }];
//    [self.stepsController showNextStep];

    [self performSegueWithIdentifier:@"BeginUsingApp" sender:self];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {

	// What's the password field going to contain if we let this change occur?
	NSString *newPass = [textField.text stringByReplacingCharactersInRange:range withString:string];

	// If they entered a character or pasted then we're ok
	// TODO: enforce a minimum password length in here.
	if (newPass.length > 0) {
        self.nextButton.enabled = YES;
	} else {
        self.nextButton.enabled = NO;
	}

    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
