#import "APIManager.h"
#import "APIMethods.h"

NS_ASSUME_NONNULL_BEGIN


/*--------------------------------------------------------------------------------------------------------------
 🌐🍑 'APIManager(Utilites)' - contains methods used indirectly in 'APIManager' and its categories.
 ---------------
 Contains methods to help ensure correct functioning of 'APIManager' that cannot be placed
 into any of its other categories due to the fact that they are not included in their range of functional responsibilities.
 
 For example, these can be methods that:
 - convert 'NSDictionary' to 'NSData'.
 - determines the file extension by binary code.
 - converts the 'enum' value to 'NSString'
 --------------------------------------------------------------------------------------------------------------*/
@interface APIManager (Utilites)

/*--------------------------------------------------------------------------------------------------------------
 Converts 'enum' values to 'NSString'
 --------------------------------------------------------------------------------------------------------------*/
+ (NSString*) convertAPIMethodToString:(APIMethod)enumValue;

/*--------------------------------------------------------------------------------------------------------------
 Returns 'mimeType' after parsing 'NSData'
 --------------------------------------------------------------------------------------------------------------*/
+ (NSString *)mimeTypeForData:(NSData*)data;

/*--------------------------------------------------------------------------------------------------------------
 Returns the file extension after parsing 'NSData'
 --------------------------------------------------------------------------------------------------------------*/
+ (NSString *)extensionForData:(NSData *)data;

/*--------------------------------------------------------------------------------------------------------------
 Converts binary to 'NSDictionary'
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable NSDictionary*) convertDataToDict:(NSData*)data withError:(NSError**)error;

@end

NS_ASSUME_NONNULL_END
