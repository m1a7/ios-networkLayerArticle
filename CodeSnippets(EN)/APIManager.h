//
//  APIManager.h
//  GitHubAPI
//
//  Created by Admin on 13/05/2020.
//  Copyright © 2020 iOS-Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "APIConsts.h"
#import "AuthProtocol.h"
#import <RXNetworkOperation/RXNO_OperationProtocols.h>


NS_ASSUME_NONNULL_BEGIN

// models
@class Friend;
@class UserProfile;
@class WallPost;
@class Photo;
@class PhotoGalleryCollection;


/*--------------------------------------------------------------------------------------------------------------
 🌐🕹 'APIManager' - manages all network connections.
 ---------------
 The main task of the class is to create, modify, and perform network operations.
 ---------------
 [⚖️] Duties:
 - Provide methods for interacting with the product API.
 - Be a delegate and conform the <Auth2_0_Delegate> protocol to support authentication.
 - Manage the received token. Store property, write and delete from memory.
 --------------------------------------------------------------------------------------------------------------*/


@interface APIManager : NSObject <Auth2_0_Delegate>

#pragma mark - URLSession
/*--------------------------------------------------------------------------------------------------------------
 This class supports several ways to implement Internet connection.
 1) The execution of all requests using 'RXNetworkOperation'.
 2) Self-configuring operations using 'NSURLSession' itself.
 3) You can also have as many custom sessions as you want for different situations.
 ---
 (⚠️) You may also have a situation where you want to work together with 'RXNetworkOperation' but you need to
 to customize the session as much as possible, then in the 'operation.privateSession' property, you can assign
 each operation value of 'APIManager.defaultSession'
 --------------------------------------------------------------------------------------------------------------*/
@property (class, nonatomic, readonly, strong) NSURLSession* defaultSession;


#pragma mark - Queues
/*--------------------------------------------------------------------------------------------------------------
 The queues where all network operations are performed by default.
 We recommend performing group operations on a synchronous queue.
 --------------------------------------------------------------------------------------------------------------*/
@property (class, nonatomic, readonly, strong) NSOperationQueue* aSyncQueue;

@property (class, nonatomic, readonly, strong) NSOperationQueue* syncQueue;


#pragma mark - Token Property
/*--------------------------------------------------------------------------------------------------------------
 Property stores the token received from the server. If you previously received it and then restarted the app, the
 redefined getter will extract the token from the 'Keychain' itself.
 --------------------------------------------------------------------------------------------------------------*/
@property (class, nonatomic, strong, nullable) Token* token;



#pragma mark - BaseURL & EndPoint
/*--------------------------------------------------------------------------------------------------------------
 Property was created for the convenience of configuring requests in the future. You can specify the base prefix
 'https://api.vk.com/method/' which will be added to all API requests
 --------------------------------------------------------------------------------------------------------------*/
@property (class, nonatomic, strong, nullable) NSString* baseURL;


/*--------------------------------------------------------------------------------------------------------------
 Возвращает результат соединения двух строк. 'baseURL' и значение из аргумента 'method'.
 --------------------------------------------------------------------------------------------------------------*/
+ (NSString*) baseURLappend:(NSString*)method;


#pragma mark - Customization
/*--------------------------------------------------------------------------------------------------------------
 Метод создан для возможности дополнительной настройки 'APIManager'a перед использованием.
 Например вы хотите задать некие дополнительные пользовательские параметры.
 В можете сделать это, вызывав данный метод внутри 'didFinishLaunchingWithOptions:..'.
 --------------------------------------------------------------------------------------------------------------*/
+ (void) prepareAPIManagerBeforeUsing:(nullable void(^)(void))completion;




#pragma mark - Network Operations

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
 .__   __.  _______ .___________.____    __    ____  ______   .______       __  ___
 |  \ |  | |   ____||           |\   \  /  \  /   / /  __  \  |   _  \     |  |/  /
 |   \|  | |  |__   `---|  |----` \   \/    \/   / |  |  |  | |  |_)  |    |  '  /
 |  . `  | |   __|      |  |       \            /  |  |  |  | |      /     |    <
 |  |\   | |  |____     |  |        \    /\    /   |  `--'  | |  |\  \----.|  .  \
 |__| \__| |_______|    |__|         \__/  \__/     \______/  | _| `._____||__|\__\
 
   ______   .______    _______ .______          ___   .___________. __    ______   .__   __.      _______.
  /  __  \  |   _  \  |   ____||   _  \        /   \  |           ||  |  /  __  \  |  \ |  |     /       |
 |  |  |  | |  |_)  | |  |__   |  |_)  |      /  ^  \ `---|  |----`|  | |  |  |  | |   \|  |    |   (----`
 |  |  |  | |   ___/  |   __|  |      /      /  /_\  \    |  |     |  | |  |  |  | |  . `  |     \   \
 |  `--'  | |  |      |  |____ |  |\  \----./  _____  \   |  |     |  | |  `--'  | |  |\   | .----)   |
  \______/  | _|      |_______|| _| `._____/__/     \__\  |__|     |__|  \______/  |__| \__| |_______/
 */
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*--------------------------------------------------------------------------------------------------------------
 Возвращает массив информации о пользователях
 --------------------------------------------------------------------------------------------------------------*/
+ (DTO*) usersGet:(NSArray<NSString*>*)userIDs
           fields:(NSArray<NSString*>* _Nullable)fields
       completion:(nullable void(^)(NSArray<UserProfile*>* _Nullable userProfiles, BO* op))completion;


/*--------------------------------------------------------------------------------------------------------------
 Возвращает все фотографии пользователя или сообщества в антихронологическом порядке.
 --------------------------------------------------------------------------------------------------------------*/
+ (DTO*) photosCollectionFromID:(nullable NSString*)ownerID
                         offset:(NSInteger)offset
                          count:(NSInteger)count
                     completion:(nullable void(^)(PhotoGalleryCollection* _Nullable photoCollection, BO* op))completion;

/*--------------------------------------------------------------------------------------------------------------
 Возвращает массив записей со стены пользователя или сообщества
 --------------------------------------------------------------------------------------------------------------*/
+ (DTO*) wallGet:(nullable NSString*)ownerID
          offset:(NSInteger)offset
           count:(NSInteger)count
          filter:(nullable NSString*)filter
      completion:(nullable void(^)(NSArray<WallPost*>* _Nullable wallPosts, BO* op))completion;


/*--------------------------------------------------------------------------------------------------------------
 Позволяет создать запись на стене. Метод принимает массив attachments и самостоятельно выгружает их по одиночке.
 --------------------------------------------------------------------------------------------------------------*/
+ (GO*) wallPost:(nullable NSString*)ownerID
         message:(nullable NSString*)message
  attachmentsArr:(nullable NSArray<NSData*>*)attachments
       fromGroup:(BOOL)fromGroup
      completion:(nullable void(^)(NSNumber* _Nonnull postID, BO* op))completion;


/*--------------------------------------------------------------------------------------------------------------
 Позволяет создать запись на стене. Метод принимает строку attachments (то есть требует адресса уже загруженного контента)
 --------------------------------------------------------------------------------------------------------------*/
+ (DTO*) wallPost:(nullable NSString*)ownerID
          message:(nullable NSString*)message
      attachments:(nullable NSString*)attachments
        fromGroup:(BOOL)fromGroup
       completion:(nullable void(^)(NSNumber* _Nullable postID, BO* op))completion;


/*--------------------------------------------------------------------------------------------------------------
 Метод загружает массив изображений на сервер.
 Ограничения: не более 6 фотографий за один раз в методе.
 --------------------------------------------------------------------------------------------------------------*/
+ (GO*) uploadImages:(NSArray<NSData*>*)imagesData
              userID:(nullable NSString*)userID
             groupID:(nullable NSString*)groupID
          completion:(nullable void(^)(NSArray<NSDictionary*>* _Nullable savedImages, GO* op))completion;


/*--------------------------------------------------------------------------------------------------------------
 Returns a list of the user's friends
 --------------------------------------------------------------------------------------------------------------*/
+ (DTO*) friendListForUserID:(nullable NSString*)ownerID
                       order:(nullable NSString*)order
                      fields:(NSArray<NSString*>* _Nullable)fields
                       count:(NSInteger)count
                      offset:(NSInteger)offset
                  completion:(void(^)(NSArray<Friend*>* _Nullable friends, BO* op))completion;


/*--------------------------------------------------------------------------------------------------------------
 Makes a request to the server. Clears cookies in 'WKWebsiteDataStore'.
 Resets the 'APIManager.token' value and removes the token from the 'KeyChain'.
 --------------------------------------------------------------------------------------------------------------*/
+ (DTO*) logout:(nullable void(^)(void)) completion;




#pragma mark - <Auth2_0_Delegate>

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
   ______        ___      __    __  .___________. __    __      ___        ___
  /  __  \      /   \    |  |  |  | |           ||  |  |  |    |__ \      / _ \
 |  |  |  |    /  ^  \   |  |  |  | `---|  |----`|  |__|  |       ) |    | | | |
 |  |  |  |   /  /_\  \  |  |  |  |     |  |     |   __   |      / /     | | | |
 |  `--'  |  /  _____  \ |  `--'  |     |  |     |  |  |  |     / /_   __| |_| |
  \______/  /__/     \__\ \______/      |__|     |__|  |__|    |____| (__)\___/
 */
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*--------------------------------------------------------------------------------------------------------------
 'AuthViewController' calls this method from its delegate and passes the received token to it.
 --------------------------------------------------------------------------------------------------------------*/
+ (void) receiveTokenFromWebViewAuth:(nullable Token*)token error:(nullable NSError*)error;

/*--------------------------------------------------------------------------------------------------------------
 Using 'Router', it shows 'AuthViewController' and starts the authentication process
 --------------------------------------------------------------------------------------------------------------*/
+ (void) authenticationProcess:(nullable AuthenticationCompletion)completion;



#pragma mark - Token Access Methods

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
 .___________.  ______    __  ___  _______ .__   __.
 |           | /  __  \  |  |/  / |   ____||  \ |  |
 `---|  |----`|  |  |  | |  '  /  |  |__   |   \|  |
     |  |     |  |  |  | |    <   |   __|  |  . `  |
     |  |     |  `--'  | |  .  \  |  |____ |  |\   |
     |__|      \______/  |__|\__\ |_______||__| \__|
 */
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (BOOL) isThereTokenInKeychain;                //  Returns 'YES' if the token is written to the 'KeyChain'
+ (nullable Token*) restoreTokenFromKeychain;   //  Restores from 'KeyChain'

+ (void)     removeTokenInKeychain;             //  Deletes from 'KeyChain'
+ (NSError*) saveTokenInKeychain:(Token*)token; //  Saves in 'KeyChain'

/*--------------------------------------------------------------------------------------------------------------
 Updates the values for '@property token' and writes a new instance to the 'KeyChain'
 --------------------------------------------------------------------------------------------------------------*/
+ (void) updateToken:(NSString*)accessToken expiresAfter:(NSString*)expiresAfter userID:(NSString*)userID;



#pragma mark - Helpers - Syntax Sugar

///////////////////////////////////////////////////////////////////////////////
/*
  __    __   _______  __      .______    _______ .______          _______.
 |  |  |  | |   ____||  |     |   _  \  |   ____||   _  \        /       |
 |  |__|  | |  |__   |  |     |  |_)  | |  |__   |  |_)  |      |   (----`
 |   __   | |   __|  |  |     |   ___/  |   __|  |      /        \   \
 |  |  |  | |  |____ |  `----.|  |      |  |____ |  |\  \----.----)   |
 |__|  |__| |_______||_______|| _|      |_______|| _| `._____|_______/
 */
///////////////////////////////////////////////////////////////////////////////

/*--------------------------------------------------------------------------------------------------------------
 Ниже будут представленны методы который позволяют сократить синтаксис кода при работе с сетевым слоем.
 --------------------------------------------------------------------------------------------------------------*/

/*--------------------------------------------------------------------------------------------------------------
 Метод вызывается внутри групповых операций, чтобы прекращать выполнение последующих операций если текущая была
 завершена с ошибкой. Метод вызывает переданный 'completion' блок если операция содержит 'error'.
 --------------------------------------------------------------------------------------------------------------*/
+ (NSError*) callCompletion:(nullable void(^)(NSError* _Nullable error))completion ifOccuredErrorInOperation:(BO*)op;

/*--------------------------------------------------------------------------------------------------------------
 Метод создан для сокращения синтаксиса.
 Вызывается внутри 'completion' блоков методов класса APIManager.
 --------------------------------------------------------------------------------------------------------------*/
+ (NSError*) callCompletionWithTwoArg:(nullable void(^)(NSError* _Nullable error, id _Nullable arg1))completion ifOccuredErrorInOperation:(BO*)op;

+ (NSError*) callCompletionWithThreeArg:(nullable void(^)(NSError* _Nullable error, id _Nullable arg1, id _Nullable arg2))completion ifOccuredErrorInOperation:(BO*)op;

@end
