//
//  IAPReceiptValidator.m
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 6/21/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

#import "IAPReceiptValidator.h"

#include  "openssl/pkcs7.h"
#include "openssl/x509.h"
#include "openssl/bio.h"
#include "openssl/pem.h"
#import "openssl/evp.h"


typedef void (^receiptCompletionHandler)(NSArray *array,NSError *error);

@interface IAPReceiptValidator ()
@property (nonatomic,strong) NSMutableDictionary<NSString *,receiptCompletionHandler> *dict;
@property (nonatomic,strong) NSMutableArray *nextHandlers;
@end

@implementation IAPReceiptValidator 

#pragma mark - Public methods

- (void)forceCheckReceiptWithCompletionHandler:(receiptCompletionHandler)handler
{
    @synchronized([self class]) {
        if (!self.dict.count) {
                self.dict = [NSMutableDictionary dictionary];
            [self askForReceipt:handler];
        }
        else {
            if (!self.nextHandlers)
                self.nextHandlers = [NSMutableArray array];
            
            [self.nextHandlers addObject:handler];
        }
    }
    
}
#pragma mark -
#pragma  mark - SKRequestDelegate's methods

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"error %@",error);
    
    
    [self completionRefreshRequest:request purchasesInfo:nil withError:error];
    
}

- (void)requestDidFinish:(SKRequest *)request {
    
    [self completionRefreshRequest:request purchasesInfo:[self checkReceiptInternal] withError:nil];
}

- (void)completionRefreshRequest:(SKRequest *)request purchasesInfo:(NSArray *)purchasesInfo withError:(NSError *)error
{
    NSString *key = [NSString stringWithFormat:@"%p", request];
    receiptCompletionHandler completionHandler = self.dict[key] ;
    
    if (completionHandler) {
        completionHandler(purchasesInfo,error);
    }
    
    @synchronized([self class]) {
        if ([self.dict objectForKey:key])
            [self.dict removeObjectForKey:key];
        else if (self.dict.count == 1)
            [self.dict removeAllObjects];
        
        if (self.nextHandlers.count) {
            receiptCompletionHandler nextHandler = [self.nextHandlers objectAtIndex:0];
            [self.nextHandlers removeObjectAtIndex:0];
            [self askForReceipt:nextHandler];
        }
    }
}

#pragma mark -
#pragma mark - Check & Ask methods

- (void)askForReceipt:(receiptCompletionHandler)handler {
    
    NSDictionary<NSString *,id> *properties = nil;
    
#ifdef DEBUG
    properties = @{SKReceiptPropertyIsExpired:@(NO),
                   SKReceiptPropertyIsRevoked:@(NO)
                   };
#endif
    
    
    SKReceiptRefreshRequest *req =[[SKReceiptRefreshRequest alloc]initWithReceiptProperties:properties];
    req.delegate = self;
    [req start];
    
    @synchronized([self class]) {
        
        self.dict[[NSString stringWithFormat:@"%p", req]] = handler;
    }
}

- (NSArray *)checkReceiptInternal {
    return [self checkReceiptInternalWithParam:nil];
}

- (NSArray *)checkReceiptInternalWithParam:(out BOOL*)needToAskPtr {
    
    // OS X 10.7 and later / iOS 7 and later
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSURL *receiptURL = [mainBundle appStoreReceiptURL];
    NSError *receiptError = nil;
    BOOL isPresent = [receiptURL checkResourceIsReachableAndReturnError:&receiptError];
    if (isPresent && !receiptError) {
        // Validation fails
        NSArray * result = [self checkReceiptWithURL:receiptURL];
        isPresent = result.count;
        if (isPresent) {
            if (needToAskPtr != nil) {
                *needToAskPtr = false;
            }
            return result;
        }
    }
    
#ifdef DEBUG
    if (receiptError)
        NSLog(@"Receipt Error %@",receiptError);
#endif
    
    if (!isPresent && needToAskPtr != nil) {
        *needToAskPtr = true;
    }
    return nil;
}

- (NSArray *)checkReceiptWithURL:(NSURL *)receiptURL {
    // Load the receipt file
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    
    // Create a memory buffer to extract the PKCS #7 container
    BIO *receiptBIO = BIO_new(BIO_s_mem());
    BIO_write(receiptBIO, [receiptData bytes], (int) [receiptData length]);
    PKCS7 *receiptPKCS7 = d2i_PKCS7_bio(receiptBIO, NULL);
    NSArray * res = nil;
    if (receiptPKCS7 &&
        PKCS7_type_is_signed(receiptPKCS7) &&
        PKCS7_type_is_data(receiptPKCS7->d.sign->contents)) {
        // Validation continue
        
        // Load the Apple Root CA (downloaded from https://www.apple.com/certificateauthority/)
        NSURL *appleRootURL = [[NSBundle mainBundle] URLForResource:@"AppleIncRootCertificate" withExtension:@"cer"];
        NSData *appleRootData = [NSData dataWithContentsOfURL:appleRootURL];
        BIO *appleRootBIO = BIO_new(BIO_s_mem());
        BIO_write(appleRootBIO, (const void *) [appleRootData bytes], (int) [appleRootData length]);
        X509 *appleRootX509 = d2i_X509_bio(appleRootBIO, NULL);
        
        // Create a certificate store
        X509_STORE *store = X509_STORE_new();
        X509_STORE_add_cert(store, appleRootX509);
        
        // Be sure to load the digests before the verification
        OpenSSL_add_all_digests();
        
        // Check the signature
        int result = PKCS7_verify(receiptPKCS7, NULL, store, NULL, NULL, 0);
        if (result == 1) {
            // Validation OK
            res = [self parsingReceiptAndCheck:receiptPKCS7];
        }
        
        if (store)
            X509_STORE_free(store);
        
        if (appleRootBIO)
            BIO_free(appleRootBIO);
        
    }
    
    if (receiptBIO)
        BIO_free(receiptBIO);
    
    return res;
}

- (NSArray *)parsingReceipts:(const unsigned char *)ptr  end:(const unsigned char *)end {
    
    const unsigned char *str_ptr;
    
    int type = 0, str_type = 0;
    int xclass = 0, str_xclass = 0;
    long length = 0, str_length = 0;
    
        // Decode payload (a SET is expected)
        ASN1_get_object(&ptr, &length, &type, &xclass, end - ptr);
        if (type != V_ASN1_SET) {
            // Validation fails
            return nil;
        }
        
        NSMutableArray *resInfo = [NSMutableArray array];
        NSMutableDictionary *curDic = [NSMutableDictionary dictionary];
    
    // Date formatter to handle RFC 3339 dates in GMT time zone
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
        while (ptr < end) {
            ASN1_INTEGER *integer;
            
            // Parse the attribute sequence (a SEQUENCE is expected)
            ASN1_get_object(&ptr, &length, &type, &xclass, end - ptr);
            if (type != V_ASN1_SEQUENCE) {
                // Validation fails
                return nil;
            }
            
            const unsigned char *seq_end = ptr + length;
            long attr_type = 0;
            long attr_version = 0;
            
            // Parse the attribute type (an INTEGER is expected)
            ASN1_get_object(&ptr, &length, &type, &xclass, end - ptr);
            if (type != V_ASN1_INTEGER) {
                // Validation fails
                return false;
            }
            integer = c2i_ASN1_INTEGER(NULL, &ptr, length);
            attr_type = ASN1_INTEGER_get(integer);
            ASN1_INTEGER_free(integer);
            
            // Parse the attribute version (an INTEGER is expected)
            ASN1_get_object(&ptr, &length, &type, &xclass, end - ptr);
            if (type != V_ASN1_INTEGER) {
                // Validation fails
                return false;
            }
            integer = c2i_ASN1_INTEGER(NULL, &ptr, length);
            attr_version = ASN1_INTEGER_get(integer);
            ASN1_INTEGER_free(integer);
            
            // Check the attribute value (an OCTET STRING is expected)
            ASN1_get_object(&ptr, &length, &type, &xclass, end - ptr);
            if (type != V_ASN1_OCTET_STRING) {
                // Validation fails
                return nil;
            }
            
            NSString *key = nil;
            switch (attr_type) {
                case 1701:
                    //quantity
                    str_ptr = ptr;
                    ASN1_get_object(&str_ptr, &str_length, &str_type, &str_xclass, seq_end - str_ptr);
                    if (str_type != V_ASN1_INTEGER) {
                        // Validation fails
                        return nil;
                    }
                    ASN1_INTEGER  *integer1;
                    
                    integer1 = c2i_ASN1_INTEGER(NULL, &str_ptr, str_length);
                    long quantity = ASN1_INTEGER_get(integer1);
                    ASN1_INTEGER_free(integer1);
                    
                    
                    [self appendDic:curDic toArray:resInfo ifKeyMet:@"quantity" value:@(quantity)];
                    
                    
                    break;
                    
                case 1702:
                    if (key == nil)
                        key = @"productIdentifier";
                case 1703:
                    if (key == nil)
                        key = @"transactionIdentifier";
                case 1705:
                    if (key == nil)
                        key = @"originalTransactionIdentifier";
                    
                    str_ptr = ptr;
                    ASN1_get_object(&str_ptr, &str_length, &str_type, &str_xclass, seq_end - str_ptr);
                    if (str_type == V_ASN1_UTF8STRING) {
                        // We store both the decoded string and the raw data for later
                        // The raw is data will be used when computing the GUID hash
                        NSString *value = [[NSString alloc] initWithBytes:str_ptr length:str_length encoding:NSUTF8StringEncoding];
                        [self appendDic:curDic toArray:resInfo ifKeyMet:key value:value];
                    
                        
                        key = nil;
                    }
                    break;
                case 1704:
                    if (key == nil)
                        key = @"purchaseDate";
                case 1706:
                    if (key == nil)
                        key = @"originalPurchaseDate";
                case 1712:
                    if (key == nil)
                        key = @"cancellationDate";
                    
                    str_ptr = ptr;
                    ASN1_get_object(&str_ptr, &str_length, &str_type, &str_xclass, seq_end - str_ptr);
                    if (str_type == V_ASN1_IA5STRING) {
                        // The date is stored as a string that needs to be parsed
                        NSString *dateString = [[NSString alloc] initWithBytes:str_ptr length:str_length encoding:NSASCIIStringEncoding];
                        [self appendDic:curDic toArray:resInfo ifKeyMet:key value:dateString];
                        key = nil;
                    }
                    
                    break;
                default:
                    break;
            }
            // Move past the value
            ptr += length;
        }
    
        if (curDic.count !=0) {
            [resInfo addObject:[curDic copy]];
            [curDic removeAllObjects];
        }
    
    NSMutableArray *resInfo2 = [NSMutableArray arrayWithCapacity:resInfo.count];
    
    for (NSUInteger i =0;i<resInfo.count;i++) {
        NSDictionary *curDic = resInfo[i];
        
        NSString *cDateStr = curDic[@"cancellationDate"];
        
        if (cDateStr.length == 0)
            [resInfo2 addObject:curDic];
    }
    resInfo = nil;
    
    return resInfo2.count ?  resInfo2 : nil;
}

- (void)appendDic:(NSMutableDictionary *)curDic toArray:(NSMutableArray *)resInfo ifKeyMet:(NSString *)key value:(id)value
{
    if (curDic.count != 0 && curDic[key] != nil) {
        [resInfo addObject:[curDic copy]];
        [curDic removeAllObjects];
    }
    curDic[key] = value;
}

- (NSArray *)parsingReceiptAndCheck:(PKCS7 *)receiptPKCS7 {
   
    // Get a pointer to the ASN.1 payload
    ASN1_OCTET_STRING *octets = receiptPKCS7->d.sign->contents->d.data;
    const unsigned char *ptr = octets->data;
    const unsigned char *end = ptr + octets->length;
    const unsigned char *str_ptr;
    
    int type = 0, str_type = 0;
    int xclass = 0, str_xclass = 0;
    long length = 0, str_length = 0;
    
    // Store for the receipt information
    NSString *bundleIdString = nil;
    NSString *bundleVersionString = nil;
    NSData *bundleIdData = nil;
    NSData *hashData = nil;
    NSData *opaqueData = nil;
    NSDate *expirationDate = nil;
    
    // Date formatter to handle RFC 3339 dates in GMT time zone
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    // Decode payload (a SET is expected)
    ASN1_get_object(&ptr, &length, &type, &xclass, end - ptr);
    if (type != V_ASN1_SET) {
        // Validation fails
        return nil;
    }
    NSMutableArray * receipts =[NSMutableArray array];
    while (ptr < end) {
        ASN1_INTEGER *integer;
        
        // Parse the attribute sequence (a SEQUENCE is expected)
        ASN1_get_object(&ptr, &length, &type, &xclass, end - ptr);
        if (type != V_ASN1_SEQUENCE) {
            // Validation fails
            return nil;
        }
        
        const unsigned char *seq_end = ptr + length;
        long attr_type = 0;
        long attr_version = 0;
        
        // Parse the attribute type (an INTEGER is expected)
        ASN1_get_object(&ptr, &length, &type, &xclass, end - ptr);
        if (type != V_ASN1_INTEGER) {
            // Validation fails
            return nil;
        }
        integer = c2i_ASN1_INTEGER(NULL, &ptr, length);
        attr_type = ASN1_INTEGER_get(integer);
        ASN1_INTEGER_free(integer);
        
        // Parse the attribute version (an INTEGER is expected)
        ASN1_get_object(&ptr, &length, &type, &xclass, end - ptr);
        if (type != V_ASN1_INTEGER) {
            // Validation fails
            return nil;
        }
        integer = c2i_ASN1_INTEGER(NULL, &ptr, length);
        attr_version = ASN1_INTEGER_get(integer);
        ASN1_INTEGER_free(integer);
        
        // Check the attribute value (an OCTET STRING is expected)
        ASN1_get_object(&ptr, &length, &type, &xclass, end - ptr);
        if (type != V_ASN1_OCTET_STRING) {
            // Validation fails
            return nil;
        }
        
        switch (attr_type) {
            case 2:
                // Bundle identifier
                str_ptr = ptr;
                ASN1_get_object(&str_ptr, &str_length, &str_type, &str_xclass, seq_end - str_ptr);
                if (str_type == V_ASN1_UTF8STRING) {
                    // We store both the decoded string and the raw data for later
                    // The raw is data will be used when computing the GUID hash
                    bundleIdString = [[NSString alloc] initWithBytes:str_ptr length:str_length encoding:NSUTF8StringEncoding];
                    bundleIdData = [[NSData alloc] initWithBytes:(const void *)ptr length:length];
                }
                break;
                
            case 3:
                // Bundle version
                str_ptr = ptr;
                ASN1_get_object(&str_ptr, &str_length, &str_type, &str_xclass, seq_end - str_ptr);
                if (str_type == V_ASN1_UTF8STRING) {
                    // We store the decoded string for later
                    bundleVersionString = [[NSString alloc] initWithBytes:str_ptr length:str_length encoding:NSUTF8StringEncoding];
                }
                break;
                
            case 4:
                // Opaque value
                opaqueData = [[NSData alloc] initWithBytes:(const void *)ptr length:length];
                break;
                
            case 5:
                // Computed GUID (SHA-1 Hash)
                hashData = [[NSData alloc] initWithBytes:(const void *)ptr length:length];
                break;
                
            case 21:
                // Expiration date
                str_ptr = ptr;
                ASN1_get_object(&str_ptr, &str_length, &str_type, &str_xclass, seq_end - str_ptr);
                if (str_type == V_ASN1_IA5STRING) {
                    // The date is stored as a string that needs to be parsed
                    NSString *dateString = [[NSString alloc] initWithBytes:str_ptr length:str_length encoding:NSASCIIStringEncoding];
                    expirationDate = [formatter dateFromString:dateString];
                }
                break;
                
                // You can parse more attributes...
            case 17:
            {
                //purchases
                NSArray * receiptsExtra = [self parsingReceipts:ptr end:seq_end];
                if (receiptsExtra.count)
                    [receipts addObjectsFromArray:receiptsExtra];
                else
                    return nil;
                break;
            }
            default:
                break;
        }
        
        // Move past the value
        ptr += length;
    }
    
    
    if (![bundleIdString isEqualToString:[NSBundle mainBundle].bundleIdentifier])
        return nil;
    
    NSString *realBundleVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)@"CFBundleVersion"];
    
    
    if (![bundleVersionString isEqualToString:realBundleVersion])
        return nil;
    
    // Be sure that all information is present
    if (opaqueData == nil ||
        hashData == nil) {
        // Validation fails
        return nil;
    }
    
    UIDevice *device = [UIDevice currentDevice];
    NSUUID *identifier = [device identifierForVendor];
    uuid_t uuid;
    [identifier getUUIDBytes:uuid];
    NSData *guidData = [NSData dataWithBytes:(const void *)uuid length:16];
    
    
    unsigned char hash[20];
    
    // Create a hashing context for computation
    SHA_CTX ctx;
    SHA1_Init(&ctx);
    SHA1_Update(&ctx, [guidData bytes], (size_t) [guidData length]);
    SHA1_Update(&ctx, [opaqueData bytes], (size_t) [opaqueData length]);
    SHA1_Update(&ctx, [bundleIdData bytes], (size_t) [bundleIdData length]);
    SHA1_Final(hash, &ctx);
    
    // Do the comparison
    NSData *computedHashData = [NSData dataWithBytes:hash length:20];
    if (![computedHashData isEqualToData:hashData]) {
        // Validation fails
        return nil;
    }
    
    return receipts.count ? receipts : nil;
}

@end