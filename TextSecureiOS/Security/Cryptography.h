//
//  Cryptography.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/26/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSMessageKeys.h"

@interface Cryptography : NSObject
+(NSMutableData*) generateRandomBytes:(int)numberBytes;
#pragma mark SHA and HMAC methods
+(NSString*)truncatedSHA1Base64EncodedWithoutPadding:(NSString*)string;
+ (NSString*)computeSHA1DigestForString:(NSString*)input;

+(NSData*) computeSHA256HMAC:(NSData*)dataToHMAC withHMACKey:(NSData*)HMACKey;
+(NSData*) computeSHA1HMAC:(NSData*)dataToHMAC withHMACKey:(NSData*)HMACKey;
+(NSData*) truncatedSHA1HMAC:(NSData*)dataToHMAC withHMACKey:(NSData*)HMACKey truncation:(int)bytes;

+(NSData*)decryptCTRMode:(NSData*)ciphertext withKeys:(TSMessageKeys*)keys;

+(NSData*)encryptCTRMode:(NSData*)dataToEncrypt withKeys: (TSMessageKeys*)keys computedHMAC:(NSData**)hmac hmacData:(NSData*)hmacdata;
#pragma mark decrypt symmetrically with key given to server this first layer just hides from apple encrypted protobufs message
+(NSData*) decryptAppleMessagePayload:(NSData*)payload withSignalingKey:(NSString*)signalingKeyString;

#pragma mark encrypt and decrypt attachment data
+(NSData*) decryptAttachment:(NSData*) dataToDecrypt withKey:(NSData*) key ;

+(NSData*) encryptAttachment:(NSData*) attachment withRandomKey:(NSData**)key;
#pragma mark general encryption/decryption
+(NSData*) decrypt:(NSData*) dataToDecrypt withKey:(NSData*) key withIV:(NSData*) iv withVersion:(NSData*)version withHMACKey:(NSData*) HMACKey forHMAC:(NSData *)hmac;

+(NSData*)encrypt:(NSData*) dataToEncrypt withKey:(NSData*) key withIV:(NSData*) iv withVersion:(NSData*)version  withHMACKey:(NSData*) HMACKey computedHMAC:(NSData**)hmac;


@end
