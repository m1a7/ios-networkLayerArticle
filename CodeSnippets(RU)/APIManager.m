//
//  APIManager.m
//  GitHubAPI
//
//  Created by Admin on 13/05/2020.
//  Copyright © 2020 iOS-Team. All rights reserved.
//

#import "APIManager.h"
// Own Categories
#import "APIManager+Utilites.h"

// Other Network layer components
#import "NetworkRequestConstructor.h"
#import "Validator.h"
#import "Parser.h"
#import "Mapper.h"
#import "NSError+ShortStyle.h"

// Models
#import "Token.h"
#import "Friend.h"
#import "UserProfile.h"
#import "WallPost.h"

#import "OwnerPost.h"
#import "GroupOwnerPost.h"
#import "UserOwnerPost.h"

#import "Attachment.h"
#import "Photo.h"
#import "PhotoGalleryCollection.h"

// Router
#import "Router.h"

// Thirt-party libraries
#import "KFKeychain.h"
#import <RXNetworkOperation/RXNetworkOperation.h>
#import "FEMDeserializer.h"
#import "RealReachability.h"

// WKWebView
#import <WebKit/WebKit.h>
// Foundation
#import "MultiThreads.h"
// Another Classes
#import "Templater.h"


// Key for writing the token to the keyChain
#define vkAccessToken @"vkAccessToken"


static NSString         *_baseURL        = nil;
static NSURLSession     *_defaultSession = nil;
static NSOperationQueue *_aSyncQueue     = nil;
static NSOperationQueue *_syncQueue      = nil;

static Token            *_token                       = nil;
static BOOL              _isOpenAuthenticationProcess = NO;
static AuthenticationCompletion  _authenticationCompletion = nil;



@interface APIManager ()

@property (class, nonatomic, readwrite, strong) NSURLSession* defaultSession;
@property (class, nonatomic, readwrite, strong) NSOperationQueue* aSyncQueue;
@property (class, nonatomic, readwrite, strong) NSOperationQueue* syncQueue;

/*--------------------------------------------------------------------------------------------------------------
 Для этого проперти значение устанавливается в методе 'authenticationProcess:'.
 Далее данный блок вызывается после завершения (успешного или неудачного) процесса аутентификации.
 --------------------------------------------------------------------------------------------------------------*/
@property (class, nonatomic, copy) AuthenticationCompletion authenticationCompletion;

/*--------------------------------------------------------------------------------------------------------------
 Если операция завершилась с ошибкой 401 (ошибка аутентификации), она добавляется в массив "отложенных операций",
 а затем вызывается метод 'authenticationProcess:', который покажет UI и позволит пользователю ввести логин и пароль.

 Поскольку сразу несколько операций могут закончиться этой ошибкой, поэтому несколько операций могут вызвать
 метод 'authenticationProcess:'. Эта переменная была сделана, чтобы избежать коллизий и одновременного представления 
 нескольких контроллеров.

Это позволяет коду внутри эauthenticationProcess:» выполняться, только если значение у этой переменной равняется 'NO'.
 --------------------------------------------------------------------------------------------------------------*/
@property (class, nonatomic, assign) BOOL isOpenAuthenticationProcess;

@end


@implementation APIManager

@dynamic defaultSession;
@dynamic token;


#pragma mark - BaseURL & EndPoint
/*--------------------------------------------------------------------------------------------------------------
 Возвращает результат соединения двух строк. 'baseURL' и значение из аргумента 'method'.
 --------------------------------------------------------------------------------------------------------------*/
+ (NSString*) baseURLappend:(NSString*)method
{
    if (method.length < 1){
        return [API baseURL];
    }
    return [[API baseURL] stringByAppendingString:method];
}

#pragma mark - Customization
/*--------------------------------------------------------------------------------------------------------------
 Метод создан для возможности дополнительной настройки 'APIManager'a перед использованием.
 Например вы хотите задать некие дополнительные пользовательские параметры.
 В можете сделать это, вызывав данный метод внутри 'didFinishLaunchingWithOptions:..'.
 --------------------------------------------------------------------------------------------------------------*/
+ (void) prepareAPIManagerBeforeUsing:(nullable void(^)(void))completion
{
    [API setBaseURL:@"https://api.vk.com/method/"];
    
    GLobalRealReachability.hostForPing  = @"www.google.com";
    GLobalRealReachability.hostForCheck = @"www.goolge.com";
    
    if (completion) completion();
}


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
       completion:(nullable void(^)(NSArray<UserProfile*>* _Nullable userProfiles, BO* op))completion
{
    // NetworkRequestConstructor
    NSURLRequest* request = [NetworkRequestConstructor buildRequestForMethod_UsersGet:userIDs
                                                                               fields:fields
                                                                             nameCase:nil];
    // NetworkOpeation
     DTO* netOp =
    [DTO request:request uploadProgress:nil downloadProgress:nil completion:^(DTO * _Nonnull op, NSError * _Nullable error) {
       
        // Check on 401 and other server's error
        if ([APIManager checkOnServerAndOtherError:op apiMethodCompletion:completion]){
            return;
        }
            
        error = [Validator validateResponse:op.json fromAPIMethod:APIMethod_UserGet];
        if ([API callCompletionIfOccuredErrorInOp:op result:nil error:error block:completion]){
            return;
        }
        
        // Mapper
        NSArray<UserProfile*>* userProfiles = [Mapper usersGetFromJSON:op.json error:&error];
        if ([API callCompletionIfOccuredErrorInOp:op result:userProfiles error:error block:completion]){
            return;
        }
        
        // Call completion
        if (completion) completion(userProfiles,op);
    }];
    //netOp.privateSession = self.defaultSession;
    return netOp;
}


/*--------------------------------------------------------------------------------------------------------------
 Возвращает все фотографии пользователя или сообщества в антихронологическом порядке.
 --------------------------------------------------------------------------------------------------------------*/
+ (DTO*) photosCollectionFromID:(nullable NSString*)ownerID
                         offset:(NSInteger)offset
                          count:(NSInteger)count
                     completion:(nullable void(^)(PhotoGalleryCollection* _Nullable photoCollection, BO* op))completion
{
    // NetworkRequestConstructor
    NSURLRequest* request = [NetworkRequestConstructor buildRequestForMethod_PhotosGetAll:ownerID offset:offset count:count];
    
    // NetworkOpeation
     DTO* netOp =
    [DTO request:request uploadProgress:nil downloadProgress:nil completion:^(DTO * _Nonnull op, NSError * _Nullable error) {
        
        // Check server error. For example 401 - failed authentication
        if ([APIManager checkOnServerAndOtherError:op apiMethodCompletion:completion]){
            return;
        }
        
        // Validator. Looking for errors in json structure.
        error = [Validator validateResponse:op.json fromAPIMethod:APIMethod_PhotosGetAll];
        if ([API callCompletionIfOccuredErrorInOp:op result:nil error:error block:completion]){
            return;
        }
        
        // Mapper
        PhotoGalleryCollection* collection = [Mapper photosCollectionFromJSON:op.json[@"response"] error:&error];
        if ([API callCompletionIfOccuredErrorInOp:op result:collection error:error block:completion]){
            return;
        }
        
        // Call completion
        if (completion) completion(collection,op);
    }];
    //netOp.privateSession = self.defaultSession;
    return netOp;
}


/*--------------------------------------------------------------------------------------------------------------
 Возвращает список друзей пользователя
 --------------------------------------------------------------------------------------------------------------*/
+ (DTO*) friendListForUserID:(nullable NSString*)ownerID
                       order:(nullable NSString*)order
                      fields:(NSArray<NSString*>* _Nullable)fields
                       count:(NSInteger)count
                      offset:(NSInteger)offset
                  completion:(void(^)(NSArray<Friend*>* _Nullable friends, BO* op))completion
{
    // NetworkRequestConstructor
    NSURLRequest* request = [NetworkRequestConstructor buildRequestForMethod_FriendsGet:ownerID
                                                                                  order:order
                                                                                 fields:fields
                                                                                  count:count
                                                                                 offset:offset];
    // NetworkOpeation
    DTO* netOp =
    [DTO request:request uploadProgress:nil downloadProgress:nil completion:^(DTO * _Nonnull op, NSError * _Nullable error) {
        
        // Check server error. For example 401 - failed authentication
        if ([APIManager checkOnServerAndOtherError:op apiMethodCompletion:completion]){
            return;
        }
        
        // Validator. Looking for errors in json structure.
        error = [Validator validateResponse:op.json fromAPIMethod:APIMethod_FriendsGet];
        if ([API callCompletionIfOccuredErrorInOp:op result:nil error:error block:completion]){
            return;
        }
        
        // Mapper
        NSArray<Friend*>* friends = [Mapper friendsFromJSON:op.json[@"response"] error:&error];
        if ([API callCompletionIfOccuredErrorInOp:op result:friends error:error block:completion]){
            return;
        }
        
        // Prepare data for calling completion block
        op.result = friends;
        
        // Call completion
        if (completion) completion(friends,op);
    }];
    netOp.privateSession = self.defaultSession;
    return netOp;
}


/*--------------------------------------------------------------------------------------------------------------
 Возвращает массив записей со стены пользователя или сообщества
 --------------------------------------------------------------------------------------------------------------*/
+ (DTO*) wallGet:(nullable NSString*)ownerID
          offset:(NSInteger)offset
           count:(NSInteger)count
          filter:(nullable NSString*)filter
      completion:(nullable void(^)(NSArray<WallPost*>* _Nullable wallPosts, BO* op))completion
{
    // NetworkRequestConstructor
    NSURLRequest* request = [NetworkRequestConstructor buildRequestForMethod_WallGet:ownerID offset:offset count:count filter:filter];
    
    // NetworkOpeation
     DTO* netOp =
    [DTO request:request uploadProgress:nil downloadProgress:nil completion:^(DTO * _Nonnull op, NSError * _Nullable error) {
        
        // Check server error. For example 401 - failed authentication
        if ([APIManager  checkOnServerAndOtherError:op apiMethodCompletion:completion]){
            return;
        }
        
        // Validator. Looking for errors in json structure.
        error = [Validator validateResponse:op.json fromAPIMethod:APIMethod_WallGet];
        if ([API callCompletionIfOccuredErrorInOp:op result:nil error:error block:completion]){
            return;
        }
        
        // Mapper
        NSArray<WallPost*>* wallPosts = [Mapper wallPostsFromJSON:op.json[@"response"] error:&error];
        if ([API callCompletionIfOccuredErrorInOp:op result:wallPosts error:error block:completion]){
            return;
        }
        
        // Prepare data for calling completion block
        op.result = wallPosts;
        
        // Call completion
        if (completion) completion(wallPosts,op);
    }];
    netOp.privateSession = self.defaultSession;
    return netOp;
}


/*--------------------------------------------------------------------------------------------------------------
 Позволяет создать запись на стене. Метод принимает массив attachments и самостоятельно выгружает их по одиночке.
 Ниже имеется метод '+(DTO*)wallPost:...', он работает по другому приниципу. В его параметр 'attachments' вы
 должны передать ссылки на уже ранее загруженные материалы.
 --------------------------------------------------------------------------------------------------------------*/
+ (GO*) wallPost:(nullable NSString*)ownerID
          message:(nullable NSString*)message
   attachmentsArr:(nullable NSArray<NSData*>*)attachments
        fromGroup:(BOOL)fromGroup
       completion:(nullable void(^)(NSNumber* _Nonnull postID, BO* op))completion
{
    NSInteger ownerIDintger = [ownerID integerValue];
    
    // Инициализируем групповую операцию для загрузки прикрепленных фотографий на сервер
    GO* groupOp = [GO groupOperation:^(GO * _Nonnull op){
        
        // Загружаем фото (если есть data в массиве attachments)
        NSMutableString* stringAttachments = [NSMutableString new];
        if (attachments.count > 0)
        {
            // Загрузка каждой фотографии это сложно-составной процесс из нескольких сетевых операций.
            // Поэтому для этого используются тоже групповые операции.
            // Несмотря на возможность одновременной загрузки до 6 фотографий, мы каждую фотографию загружем отдельно.
            for (NSData* imageData in attachments) {
                [[APIManager uploadImages:@[imageData]
                                   userID:(ownerIDintger > 0) ? ownerID : nil
                                  groupID:(ownerIDintger < 0) ? ownerID : nil
                               completion:^(NSArray<NSDictionary *> * _Nullable savedImages, GO *uploadGroupOp) {
                
                                   NSDictionary* saveWallJSON = uploadGroupOp.result;

                                   if ((uploadGroupOp.error) || (!saveWallJSON)) {
                                       return;
                                   }
                                   
                                   NSArray<NSDictionary*>* responses = saveWallJSON[@"response"];
                                   
                                   // Проходим по циклу и к 'uri' каждой загруженной фотографии добавляем
                                   // 'owner_id' - это id владельца
                                   // 'id' - это номер самой фотографии.
                                   // В последствии строку 'stringAttachments' мы передаедим в метод 'wallPost',
                                   // Чтобы эти адресса этих фотографий были прикрплены к посту
                                   for (NSDictionary* response in uploadGroupOp.result[@"response"]) {
                                       
                                       NSInteger ownerId = [response[@"owner_id"] integerValue];
                                       NSInteger photoId = [response[@"id"]       integerValue];
                                       
                                       [stringAttachments appendFormat:@"photo%@_%@",@(ownerId),@(photoId)];
                                       if (![[responses lastObject] isEqual:response]){
                                             [stringAttachments appendString:@","];
                                       }
                                   }
                }] start];
            }
        }
        
        // Вызываем метод выгрузки поста
        [[API wallPost:ownerID message:message attachments:stringAttachments fromGroup:fromGroup completion:^(NSNumber* postID, BO *op) {
            if (completion) completion(postID,op);
        }] syncStart];
    }];
    return groupOp;
}


/*--------------------------------------------------------------------------------------------------------------
 Позволяет создать запись на стене. Метод принимает строку attachments в которой должны через запятую перечисляться
 адресса УЖЕ РАНЕЕ загруженных фотографий.
 --------------------------------------------------------------------------------------------------------------*/
+ (DTO*) wallPost:(nullable NSString*)ownerID
          message:(nullable NSString*)message
      attachments:(nullable NSString*)attachments
        fromGroup:(BOOL)fromGroup
       completion:(nullable void(^)(NSNumber* _Nullable postID, BO* op))completion
{
    if (!ownerID) ownerID = APIManager.token.userID;
    
    // NetworkRequestConstructor
    NSDictionary* requestParams = @{ @"owner_id" : ownerID,
                                     @"message"  : message,
                                     @"attachments" : attachments,
                                     @"from_group"  : @(fromGroup)
                                     };
    NSURLRequest* request = [NetworkRequestConstructor buildRequestForMethod_WallPost:requestParams];
    
    // NetworkOpeation
     DTO* netOp =
    [DTO request:request uploadProgress:nil downloadProgress:nil completion:^(DTO * _Nonnull op, NSError * _Nullable error) {
        
        // Check server error. For example 401 - failed authentication
        if ([APIManager  checkOnServerAndOtherError:op apiMethodCompletion:completion]){
            return;
        }
        
        // Validator. Looking for errors in json structure.
        error = [Validator validateResponse:op.json fromAPIMethod:APIMethod_WallPost];
        if ([API callCompletionIfOccuredErrorInOp:op result:nil error:error block:completion]){
            return;
        }
    
        // Parser
        NSNumber* postID = [Parser postIDInWallPostMethod:op.json error:&error];

        // Call completion
        if (completion) completion(postID,op);
    }];
    netOp.privateSession = self.defaultSession;
    return netOp;
}


/*--------------------------------------------------------------------------------------------------------------
 Метод загружает массив изображений на сервер.
 Ограничения: не более 6 фотографий за один раз в методе.
 --------------------------------------------------------------------------------------------------------------*/
+ (GO*) uploadImages:(NSArray<NSData*>*)imagesData
              userID:(nullable NSString*)userID
             groupID:(nullable NSString*)groupID
          completion:(nullable void(^)(NSArray<NSDictionary*>* _Nullable savedImages, GO* op))completion
{
     __block RXNO_GroupOperation* group =
    [RXNO_GroupOperation groupOperation:^(GO * _Nonnull groupOp){
       
        NSString* prgrsDesc = nil; // Variable to shorten the syntax
        BO*       netOp     = nil; // Variable to shorten the syntax
        
        //-------------------------------------------photos.getWallUploadServer---------------------------------------------------------------//
        // NetworkOpeation
        __block DTO* getWallUploadServerOp =
        [APIManager photosGetWallUploadServerForUserID:userID groupID:groupID completion:^(NSString * _Nonnull uploadURL, BO *op) {
            getWallUploadServerOp = (DTO*)op;
        }];
        [getWallUploadServerOp syncStart];
        netOp = getWallUploadServerOp;  // Assign a new value in order to use this link with a short name to shorten the syntax

        
        // Handle Error & Call progress blocks
        if ([APIManager callCompletionIfOccuredErrorInGO:groupOp result:nil error:getWallUploadServerOp.error block:completion]){
            prgrsDesc = str(@"+[uploadImages] The first stage was completed failed. Performing will be interrupted. op.json: %@ | error: %@",netOp.json,netOp.error);
            [API callProgressDescription:prgrsDesc doneOperations:@(1) totalCount:@(3) inGO:groupOp];
            return;
        }else {
            // Call ProgressDescriptions - gives the user a description of the completed task/stage
            prgrsDesc = str(@"+[uploadImages] The first stage was completed successfully op.json: %@ | error: %@",netOp.json,netOp.error);
            [API callProgressDescription:prgrsDesc doneOperations:@(1) totalCount:@(3) inGO:groupOp];
        }


        //-------------------------------------------uploadURL---------------------------------------------------------------//
        // Prepare images to uploading
        NSString* uploadURL = getWallUploadServerOp.result;
        
        // NetworkOpeation
        __block UO* uploadImageOp =
        [APIManager uploadImages:imagesData toURL:uploadURL progress:nil completion:^(NSDictionary * _Nullable response, BO *op) {
            uploadImageOp = (UO*)op;
        }];
        [uploadImageOp syncStart];
        netOp = uploadImageOp;  // Assign a new value in order to use this link with a short name to shorten the syntax

        // Handle Error & Call progress blocks
        if ([APIManager callCompletionIfOccuredErrorInGO:groupOp result:nil error:uploadImageOp.error block:completion]){
            prgrsDesc = str(@"+[uploadImages] The second stage was completed failed. Performing will be interrupted. op.json: %@ | error: %@",netOp.json,netOp.error);
            [API callProgressDescription:prgrsDesc doneOperations:@(2) totalCount:@(3) inGO:groupOp];
            return;
        }else {
            // Call ProgressDescriptions - gives the user a description of the completed task/stage
            prgrsDesc = str(@"+[uploadImages] The second stage was completed successfully. op.json: %@ | error: %@",netOp.json,netOp.error);
            [API callProgressDescription:prgrsDesc doneOperations:@(2) totalCount:@(3) inGO:groupOp];
        }

        //-------------------------------------------photos.saveWallPhoto---------------------------------------------------------------//
        // NetworkOpeation
        __block DTO* saveWallPhotoOp =
        [APIManager saveWallPhotoForUserID:userID groupID:groupID uploadServerResponse:uploadImageOp.json completion:^(NSDictionary * _Nullable response, BO *op) {
            saveWallPhotoOp = (DTO*)op;
        }];
        [saveWallPhotoOp syncStart];
        netOp = saveWallPhotoOp; // Assign a new value in order to use this link with a short name to shorten the syntax

        // Handle Error
        if ([APIManager callCompletionIfOccuredErrorInGO:groupOp result:nil error:saveWallPhotoOp.error block:completion]){
            prgrsDesc = str(@"+[uploadImages] The thrid stage was completed failed. Performing will be interrupted. op.json: %@ | error: %@",netOp.json,netOp.error);
            [API callProgressDescription:prgrsDesc doneOperations:@(3) totalCount:@(3) inGO:groupOp];
            return;
        }else {
            prgrsDesc = str(@"+[uploadImages] The thrid stage was completed successfully. op.json: %@ | error: %@",netOp.json,netOp.error);
            [API callProgressDescription:prgrsDesc doneOperations:@(3) totalCount:@(3) inGO:groupOp];
        }
    
        // Prepare data for calling completion block
        groupOp.result = saveWallPhotoOp.json;
        NSArray<NSDictionary*>* responses = saveWallPhotoOp.json[@"response"];
        if (completion) completion(responses,groupOp);
    }];
    return group;
}


/*--------------------------------------------------------------------------------------------------------------
 Совершает запрос к серверу. Удаляет файлы cookie в 'WKWebsiteDataStore'.
 Сбрасывает значение 'APIManager.token' и удаляет токен из 'KeyChain'.
 --------------------------------------------------------------------------------------------------------------*/
+ (DTO*) logout:(nullable void(^)(void)) completion
{
    // NetworkRequestConstructor
    NSURLRequest* request = [NetworkRequestConstructor buildRequestForMethod_logout];
    
    // NetworkOpeation
     DTO* netOp =
    [DTO request:request uploadProgress:nil downloadProgress:nil completion:^(DTO * _Nonnull op, NSError * _Nullable error) {
        
        MainQueue(^{
            // Clear cookies
            WKWebsiteDataStore *dateStore = [WKWebsiteDataStore defaultDataStore];
            [dateStore fetchDataRecordsOfTypes:[WKWebsiteDataStore allWebsiteDataTypes] completionHandler:^(NSArray<WKWebsiteDataRecord *> * __nonnull records) {
                
                for (WKWebsiteDataRecord *record  in records)
                {
                    if ([record.displayName containsString:@"vk.com"]) {
                        [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:record.dataTypes forDataRecords:@[record] completionHandler:^{}];
                    }
                }
            }];
        });
        
        APIManager.token = nil;
        [APIManager removeTokenInKeychain];
        if (completion) completion();
    }];
    netOp.privateSession = self.defaultSession;
    return netOp;
}


#pragma mark - Internal Network Operations

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
  __  .__   __. .___________. _______ .______      .__   __.      ___       __
 |  | |  \ |  | |           ||   ____||   _  \     |  \ |  |     /   \     |  |
 |  | |   \|  | `---|  |----`|  |__   |  |_)  |    |   \|  |    /  ^  \    |  |
 |  | |  . `  |     |  |     |   __|  |      /     |  . `  |   /  /_\  \   |  |
 |  | |  |\   |     |  |     |  |____ |  |\  \----.|  |\   |  /  _____  \  |  `----.
 |__| |__| \__|     |__|     |_______|| _| `._____||__| \__| /__/     \__\ |_______|
 
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
 Ниже будут представлены скрытые методы которые доступны только для внутреннего использования APIManager.
 Данные методы будут использоваться как компоненты для групповых операций.
 Например метод который по загружает фото на сервер по указанному URL.
 
 Политика APIManager заключается в том, что конечный пользователь должен получать необходимые для него данные
 вызывая лишь один метод.
 В случае получения "простых" данных, например список друзей это возможно реализовать с помощью обычных сетевых операций.
 Но если для выполнения некого логического действия (например загрузка фото) требуется последовательное выполненние
 нескольких операций, то для таких целей мы создаем 'GroupOperation', которое в себе осуществляет последовательное
 исполненние мелких операций.
 Методы для этих мелких операций будут располагаться ниже.
 --------------------------------------------------------------------------------------------------------------*/

/*--------------------------------------------------------------------------------------------------------------
 [Internal method] Запрашивает адресс сервера для выгрузки на него фотографий
 --------------------------------------------------------------------------------------------------------------*/
+ (DTO*) photosGetWallUploadServerForUserID:(nullable NSString*)userID
                                    groupID:(nullable NSString*)groupID
                                 completion:(nullable void(^)(NSString* _Nonnull uploadURL, BO* op))completion
{
    NSURLRequest* request = [NetworkRequestConstructor buildRequestForMethod_PhotosGetWallUploadServer:userID groupID:groupID];
    DTO* netOp =
    [DTO request:request uploadProgress:nil downloadProgress:nil completion:^(DTO * _Nonnull op, NSError * _Nullable error) {
        
        // Check server error. For example 401 - failed authentication
        if ([APIManager checkOnServerAndOtherError:op apiMethodCompletion:nil]){
            return;
        }
        
        // Validator. Looking for errors in json structure.
        error = [Validator validateResponse:op.json fromAPIMethod:APIMethod_PhotosGetWallUploadServer];
        if ([API callCompletionIfOccuredErrorInOp:op result:nil error:error block:completion]){
            return;
        }
        // Parsing & Mapping
        NSString* uploadURL = nil;
        if (op.json[@"response"]){
            uploadURL = op.json[@"response"][@"upload_url"];
        }
        
        // Prepare data for calling completion
        op.result = uploadURL;
        // Call completion
        if (completion) completion(uploadURL,op);
    }];
    netOp.privateSession = self.defaultSession;
    return netOp;
}


/*--------------------------------------------------------------------------------------------------------------
  [Internal method] Выгружает массив фотографий по указанному в 'uploadURL' адресу
 --------------------------------------------------------------------------------------------------------------*/
+ (UO*) uploadImages:(NSArray<NSData*>*)imagesData
               toURL:(NSString*)uploadURL
            progress:(nullable void(^)(UO* op, UOUpProgress p))progress
          completion:(nullable void(^)(NSDictionary* _Nullable response, BO* op))completion
{
    // NetworkRequestConstructor
    NSURLRequest* request = [NetworkRequestConstructor buildRequestForMethod_UploadImages:imagesData uploadURL:uploadURL];
    
    // Prepare progress block in optimization-way
    void(^progressBlock)(UO* op, UOUpProgress p) = nil;
    if (progress) progressBlock =  progress;

    // Network Operation
    UO* netOp =
    [UO uploadByRequest:request progress:progressBlock completion:^(UO * _Nonnull op, NSError * _Nullable error) {
        // Check server error. For example 401 - failed authentication
        if ([APIManager checkOnServerAndOtherError:op apiMethodCompletion:nil]){
            return;
        }
        // Call completion
        if (completion) completion(op.json,op);
    }];
    
    netOp.privateSession = self.defaultSession;
    return netOp;
}

/*--------------------------------------------------------------------------------------------------------------
 [Internal method] Совершает запрос с просьбой серверу сохранить ранее загруженные фотографии
 --------------------------------------------------------------------------------------------------------------*/
+ (DTO*) saveWallPhotoForUserID:(nullable NSString*)userID
                        groupID:(nullable NSString*)groupID
           uploadServerResponse:(NSDictionary*)uploadServerResponse
                     completion:(nullable void(^)(NSDictionary* _Nullable response, BO* op))completion
{
    NSDictionary* upResponse = uploadServerResponse;
    if ((!upResponse[@"photo"]) || (!upResponse[@"server"]) || (!upResponse[@"hash"])){
        return nil;
    }
    
    NSString* photo  =  upResponse[@"photo"];
    NSInteger server = [upResponse[@"server"] integerValue];
    NSString* hash   =  upResponse[@"hash"];
    
    // NetworkRequestConstructor
    NSURLRequest* saveWallPhotoRequest =
    [NetworkRequestConstructor buildRequestForMethod_PhotosSaveWallPhoto:userID groupID:groupID photo:photo server:server hash:hash];
    
    // Network Operation
     DTO* netOp =
    [DTO request:saveWallPhotoRequest uploadProgress:nil downloadProgress:nil completion:^(DTO * _Nonnull op, NSError * _Nullable error) {
        
        // Check server error. For example 401 - failed authentication
        if ([APIManager checkOnServerAndOtherError:op apiMethodCompletion:nil]){
            return;
        }
        // Call completion
        if (completion) completion(op.json,op);
    }];
    netOp.privateSession = self.defaultSession;
    return netOp;
}

#pragma mark - Logic

///////////////////////////////////////////////////////////////////////////////
/*
  __        ______     _______  __    ______
 |  |      /  __  \   /  _____||  |  /      |
 |  |     |  |  |  | |  |  __  |  | |  ,----'
 |  |     |  |  |  | |  | |_ | |  | |  |
 |  `----.|  `--'  | |  |__| | |  | |  `----.
 |_______| \______/   \______| |__|  \______|
 */
///////////////////////////////////////////////////////////////////////////////

/*--------------------------------------------------------------------------------------------------------------
 Метод вызывается из completion блоков сетевых операций (инициализированных внутри методов APIManager'a).
 Из принятного аргумента 'op' - алгоритм выявляет ошибки возникшией во время выполнения операции.
 Если в аргумент 'completion' будет передан блок, то алгоритм в случае выявления ошибки, самостоятельно вызовет
 completionBlock метода APIManager'a (Это позволяет существенно сократить синтаксис).
 --------------------------------------------------------------------------------------------------------------*/
+ (NSError* _Nullable) checkOnServerAndOtherError:(BO*)op apiMethodCompletion:(nullable void(^)(id value, BO* op))completion
{
    // Обрабатываем случай когда запрос дошел до сервера, но был составлен неудачно и вернулся с ошибкой
    if (op.json[@"error"])
    {
        NSString* domain = [NSString stringWithFormat:@"Error code %@",op.json[@"error"][@"error_msg"]];
        op.error = [NSError errorWithDomain:domain code:0 userInfo:op.json[@"error"]];
        
        // User authorization failed.
        if ([op.json[@"error"][@"error_code"] integerValue] == 5){
            NSLog(@"Error 401");
            // ⚠️ Запрещаем разблокировать поток если операция завершилась с кодом 401
            // Нужно обновить токен, выполнить операцию, а потом уже разрешать отпускать семафор
            if (op.isSync) { op.isMayUnlockSemaphore = NO; }
            [BO postponeOperation:op];
            
            // Запускаем процесс аунтетификации или получения свежего токена
            [APIManager authenticationProcess:^(NSError * _Nullable error) {
  
                // Если во время получения токена произошла ошибка, то в метод 'receiveTokenFromWebViewAuth:'
                // пройдет циклом по массиву 'RXNO_BaseOperation.postponedOperations' и сделает следующие вещи:
                // 1. Установит значение 'YES' в свойство 'isMayUnlockSemaphore'.
                // 2. Устновит собственное значение в свойство 'json'.
                // 3. Вызовет данный 'completion' блок.
                // 4. Вызовет метод 'unlockSemaphoreForAllPostponned'
                // 5. Вызовет метод 'removeAllPostponedOperations'
                if (error) {
                    // Сразу вызываем completion той операции которая первая завершилась ошибкой.
                    // Чтобы она имела эксключивное право пробросить сигнал во view, а view могло
                    // отобразить единственное 'UIAlertView'.
                    if (completion) completion(nil,op);
                
                    for (BO* postponedOp in RXNO_BaseOperation.postponedOperations)
                    {
                        // Вызываем 'completion' блоки всех остальные отложенных сетевых операции
                        if ((![postponedOp isEqual:op]) && (postponedOp.completion)){
                              postponedOp.completion(postponedOp, error);
                        }
                    }
                }
                
            }];
            return op.error;//[NSError initWithMsg:@"401 User authorization failed"];
        }
    } else if (op.error.code == -1009){
               op.error = [NSError initWithMsg:@"No Internet connection" code:-1009];
    }
    
    // Handling Other Errors ...
    if ((completion) && (op.error)) completion(nil,op);
    
    return op.error;
}


/*--------------------------------------------------------------------------------------------------------------
 [Method was created to shorten the syntax].
 Метод вызывает 'completionBlock' если объект 'error' внутри сетевой операции не равняется 'nil'
 --------------------------------------------------------------------------------------------------------------*/
+ (BOOL) callCompletionIfOccuredErrorInOp:(BO*)op result:(nullable id)result error:(nullable NSError*)error block:(nullable void(^)(id value, BO* op))completion
{
    op.error = (op.error) ? op.error : error;
    
    if (result) op.result = result;
    
    BOOL isOccuredError = (op.error) ? YES : NO;
    
    if ((op.error) && (completion)){
        completion(result,op);
    }
    return isOccuredError;
}

/*--------------------------------------------------------------------------------------------------------------
 [Method was created to shorten the syntax].
 Метод вызывает 'completionBlock' если объект 'error' внутри групповой операции не равняется 'nil'
 --------------------------------------------------------------------------------------------------------------*/
+ (BOOL) callCompletionIfOccuredErrorInGO:(GO*)op result:(nullable id)result error:(nullable NSError*)error block:(nullable void(^)(id value, GO* op))completion
{
    op.error = (op.error) ? op.error : error;
    
    if (result) op.result = result;
    
    BOOL isOccuredError = (op.error) ? YES : NO;
    
    if ((op.error) && (completion)){
        completion(result,op);
    }
    return isOccuredError;
}

/*--------------------------------------------------------------------------------------------------------------
 [Method was created to shorten the syntax].
 Вызывает 'progressDescription' и 'progressCount' у групповой операции, если эти блоки были проинициализированны.
 --------------------------------------------------------------------------------------------------------------*/
+ (void) callProgressDescription:(nullable NSString*)msg
                  doneOperations:(nullable NSNumber*)doneOperation
                      totalCount:(nullable NSNumber*)count
                            inGO:(GO*)groupOp
{
    if (!groupOp) return;
    if ((msg) && (groupOp.progressDescription)) groupOp.progressDescription(msg);
    
    if ((doneOperation) && (count)){
        if (groupOp.progressCount) groupOp.progressCount((int)[doneOperation integerValue],(int)[count integerValue]);
    }
}

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
  'AuthViewController' вызывает этот метод у своего делегата и передает ему полученный токен.
 --------------------------------------------------------------------------------------------------------------*/
+ (void) receiveTokenFromWebViewAuth:(nullable Token*)token error:(nullable NSError*)error
{
    // ⚠️ Помните, если токен по какой-либо причине не был получен, то синхронные операции способны бесконечно
    // удерживать поток с которого были вызван.
    // Для избежания 'deadlock' обрабатывайте случаи неудачного получения нового токена.
    // В таком случае вызывайте у синхронных операций методы '-unlockSemaphore'
    if (error){
        for (BO* op in RXNO_BaseOperation.postponedOperations) {
             op.isMayUnlockSemaphore = YES;
            
            NSMutableDictionary* userInfoError =  @{ @"message" : @"Token was received with error" }.mutableCopy;
            if (error.userInfo){
                userInfoError[@"error"] = error.userInfo;
            }
            op.json = userInfoError;
        }
        // Разблокируем ранее замороженные потоки
        [BO unlockSemaphoreForAllPostponned];

        // Вызываем 'completion' метода 'authenticationProcess', чтобы сущность вызвавшая его
        // могла вызвать блоки 'completion' сетевых операций., чтобы те в свою очередь передали
        // сообщение о случившейся ошибки далее по цепочки -> viewModel -> view.
        if (APIManager.authenticationCompletion) APIManager.authenticationCompletion(error);

        // Удаляем все отложенные операции.
        [BO removeAllPostponedOperations];
        APIManager.isOpenAuthenticationProcess = NO;
        return;
    }
    // Ниже обрабатывается случай успешного получения свежего токена.
    // Записываем в keychain и записываем в RAM
    [APIManager saveTokenInKeychain:token];
    [APIManager updateToken:token.access_token expiresAfter:token.expiresAfter userID:token.userID];
    
    // Вызываем метод выполнения отложенных операций.
    // Вставляем свежый токен в параметры каждой операции которые были завершены с ошибкой.
    [BO performPostponedOperationsOnQueue:APIManager.aSyncQueue
                     updateOperationBlock:^NSArray<BO*>* (NSArray<BO*>* rawOperations) {
                         
                         for (int i=0; i<=rawOperations.count-1; i++)
                         {
                             BO* op = rawOperations[i];
                             modifyOperation block = RXNO_BaseOperation.modificationBlocksForPostponedOperations[op.uniqueHash];
                             
                             if (block){
                                 op =  block(op);
                             }else {
                                 op.parameters[@"access_token"] = APIManager.token.access_token;
                             }
                         }
                         return rawOperations;
                     }];
    
    APIManager.isOpenAuthenticationProcess = NO;
    if (APIManager.authenticationCompletion) APIManager.authenticationCompletion(error);
}


/*--------------------------------------------------------------------------------------------------------------
 Используя 'Router', показывает 'AuthViewController' и запускает процесс аутентификации.
 --------------------------------------------------------------------------------------------------------------*/
+ (void) authenticationProcess:(nullable AuthenticationCompletion)completion
{
    // ⚠️ Помните, если токен по какой-либо причине не был получен, то синхронные операции способны бесконечно
    // удерживать поток с которого были вызван.
    // Для избежания 'deadlock' обрабатывайте случаи неудачного получения нового токена.
    // В таком случае вызывайте у синхронных операций методы '-unlockSemaphore'
    @synchronized ([NSNotificationCenter defaultCenter])
    {
        if (self.isOpenAuthenticationProcess){
            return;
        } else {
            self.isOpenAuthenticationProcess = YES;
        }
        [Router showOAuthControllerWithDelegate:(id<Auth2_0_Delegate>)[APIManager class] showType:PresentController_ShowType];
        APIManager.authenticationCompletion = completion;
    }
}



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


/*--------------------------------------------------------------------------------------------------------------
 Returns 'YES' if the token is written to the 'KeyChain'
 --------------------------------------------------------------------------------------------------------------*/
+ (BOOL) isThereTokenInKeychain
{
    if ([KFKeychain loadObjectForKey:vkAccessToken class:[Token class]]){
        return YES;
    }
    return NO;
}

/*--------------------------------------------------------------------------------------------------------------
   Restores from 'KeyChain'
 --------------------------------------------------------------------------------------------------------------*/
+ (nullable Token*) restoreTokenFromKeychain
{
    Token* token = [KFKeychain loadObjectForKey:vkAccessToken class:[Token class]];
    //token.access_token = @"12345";
    return token;
}

/*--------------------------------------------------------------------------------------------------------------
  Deletes from 'KeyChain'
 --------------------------------------------------------------------------------------------------------------*/
+ (void) removeTokenInKeychain {
    [KFKeychain deleteObjectForKey:vkAccessToken];
}


/*--------------------------------------------------------------------------------------------------------------
 Saves in 'KeyChain'
 --------------------------------------------------------------------------------------------------------------*/
+ (NSError*) saveTokenInKeychain:(Token*)token
{
    BOOL isSaved = [KFKeychain saveObject:token forKey:vkAccessToken];
    if (!isSaved){
        return [NSError errorWithDomain:@"Token не был сохранен в keyChain" code:0 userInfo:nil];
    }
    return nil;
}

/*--------------------------------------------------------------------------------------------------------------
 Updates the values for '@property token' and writes a new instance to the 'KeyChain'
 --------------------------------------------------------------------------------------------------------------*/
+ (void) updateToken:(NSString*)accessToken expiresAfter:(NSString*)expiresAfter userID:(NSString*)userID
{
    Token* token = [APIManager token];
    if (!token){
        token = [Token initWithAccessToken:accessToken expiresAfter:expiresAfter userID:userID];
    } else {
        token.access_token = accessToken;
        token.expiresAfter = expiresAfter;
        token.userID       = userID;
    }
    [APIManager saveTokenInKeychain:token];
}


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
 завершена с ошибкой.
 Метод вызывает переданный 'completion' блок если операция содержит 'error'.
 --------------------------------------------------------------------------------------------------------------*/
+ (NSError*) callCompletion:(nullable void(^)(NSError* _Nullable error))completion ifOccuredErrorInOperation:(BO*)op
{
    if (op.error){
        if (completion) completion(op.error);
        return op.error;
    }
    
    if (op.state  == RXNO_FailiedFinished){
        if (completion) completion(op.error);
    }
    return op.error;
}

/*--------------------------------------------------------------------------------------------------------------
  Метод создан для сокращения синтаксиса.
  Вызывается внутри 'completion' блоков методов класса APIManager.
 --------------------------------------------------------------------------------------------------------------*/
+ (NSError*) callCompletionWithTwoArg:(nullable void(^)(NSError* _Nullable error, id _Nullable arg1))completion ifOccuredErrorInOperation:(BO*)op
{
    if (op.error){
        if (completion) completion(op.error,nil);
        return op.error;
    }
    
    if (op.state  == RXNO_FailiedFinished){
        if (completion) completion(op.error,nil);
    }
    return op.error;
}

/*--------------------------------------------------------------------------------------------------------------
 Метод создан для сокращения синтаксиса.
 Вызывается внутри 'completion' блоков методов класса APIManager.
 Отличие от методов находящихся ниже, это наличие трех аргументов в блоке.
 --------------------------------------------------------------------------------------------------------------*/
+ (NSError*) callCompletionWithThreeArg:(nullable void(^)(NSError* _Nullable error, id _Nullable arg1, id _Nullable arg2))completion ifOccuredErrorInOperation:(BO*)op
{
    if (op.error){
        if (completion) completion(op.error,nil,nil);
        return op.error;
    }
    
    if (op.state  == RXNO_FailiedFinished){
        if (completion) completion(op.error,nil,nil);
    }
    return op.error;
}


#pragma mark - Setters & Getters

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
      _______. _______ .___________.___________. _______ .______          _______.
     /       ||   ____||           |           ||   ____||   _  \        /       |
    |   (----`|  |__   `---|  |----`---|  |----`|  |__   |  |_)  |      |   (----`
     \   \    |   __|      |  |        |  |     |   __|  |      /        \   \
 .----)   |   |  |____     |  |        |  |     |  |____ |  |\  \----.----)   |
 |_______/    |_______|    |__|        |__|     |_______|| _| `._____|_______/
 
   _______  _______ .___________.___________. _______ .______          _______.
  /  _____||   ____||           |           ||   ____||   _  \        /       |
 |  |  __  |  |__   `---|  |----`---|  |----`|  |__   |  |_)  |      |   (----`
 |  | |_ | |   __|      |  |        |  |     |   __|  |      /        \   \
 |  |__| | |  |____     |  |        |  |     |  |____ |  |\  \----.----)   |
  \______| |_______|    |__|        |__|     |_______|| _| `._____|_______/
*/
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


/*--------------------------------------------------------------------------------------------------------------
 @property (class, nonatomic, readwrite, strong) NSURLSession* defaultSession;
 --------------------------------------------------------------------------------------------------------------*/
+ (void)setDefaultSession:(NSURLSession *)defaultSession
{
    @synchronized ([NSNotificationCenter defaultCenter]){
        _defaultSession = defaultSession;
    }
}

+ (NSURLSession *) defaultSession
{
    @synchronized ([NSNotificationCenter defaultCenter])
    {
        if (!_defaultSession){
            NSURLSessionConfiguration* configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
            configuration.timeoutIntervalForRequest  = 5;
            configuration.timeoutIntervalForResource = 120;
            configuration.URLCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:nil];
            configuration.URLCredentialStorage = [NSURLCredentialStorage sharedCredentialStorage];
            configuration.requestCachePolicy   = NSURLRequestReloadIgnoringLocalCacheData;
            configuration.discretionary        = YES;
            
            if (@available(macOS 10.13.1, iOS 11, *)) {
                // Обязательно задаем значение 'NO', тогда операция завершиться с ошибкой если количество секунд
                // ожидания привысит значение проперти 'timeoutIntervalForRequest'.
                // В противном случае ожидание будет осуществляться до привышения значения из 'timeoutIntervalForResource'.
                configuration.waitsForConnectivity = NO;
            }
            _defaultSession = [NSURLSession sessionWithConfiguration:configuration
                                                            delegate:RXNO_BaseOperation.internal_delegate
                                                       delegateQueue:nil];
            _defaultSession.sessionDescription = @"APIManager.defaultSession";
        }
        return _defaultSession;
    }
}


/*--------------------------------------------------------------------------------------------------------------
 @property (class, nonatomic, copy)  AuthenticationCompletion authenticationCompletion;
 --------------------------------------------------------------------------------------------------------------*/
+ (void)setAuthenticationCompletion:(AuthenticationCompletion)authenticationCompletion
{
    @synchronized ([NSNotificationCenter defaultCenter]){
        _authenticationCompletion = authenticationCompletion;
    }
}

+ (AuthenticationCompletion)authenticationCompletion
{
    @synchronized ([NSNotificationCenter defaultCenter]){
        return _authenticationCompletion;
    }
}

/*--------------------------------------------------------------------------------------------------------------
 @property (class, nonatomic, assign) BOOL isOpenAuthenticationProcess;
 --------------------------------------------------------------------------------------------------------------*/
+ (void)setIsOpenAuthenticationProcess:(BOOL)isOpenAuthenticationProcess
{
    @synchronized ([NSNotificationCenter defaultCenter]){
        _isOpenAuthenticationProcess = isOpenAuthenticationProcess;
    }
}

+ (BOOL)isOpenAuthenticationProcess
{
    @synchronized ([NSNotificationCenter defaultCenter]){
        return _isOpenAuthenticationProcess;
    }
}

/*--------------------------------------------------------------------------------------------------------------
 @property (class, nonatomic, readonly, strong) NSOperationQueue* aSyncQueue;
 --------------------------------------------------------------------------------------------------------------*/
+ (void)setASyncQueue:(NSOperationQueue *)aSyncQueue
{
    @synchronized ([NSNotificationCenter defaultCenter]){
        _aSyncQueue = aSyncQueue;
    }
}

+ (NSOperationQueue *)aSyncQueue
{
    @synchronized ([NSNotificationCenter defaultCenter])
    {
        if (!_aSyncQueue){
             _aSyncQueue = [[NSOperationQueue alloc] init];
             _aSyncQueue.maxConcurrentOperationCount = 5;
        }
        return _aSyncQueue;
    }
}


/*--------------------------------------------------------------------------------------------------------------
 @property (class, nonatomic, readwrite, strong) NSOperationQueue* syncQueue;
 --------------------------------------------------------------------------------------------------------------*/
+ (void)setSyncQueue:(NSOperationQueue *)syncQueue
{
    @synchronized ([NSNotificationCenter defaultCenter]){
        _syncQueue = syncQueue;
    }
}

+ (NSOperationQueue *)syncQueue{
    @synchronized ([NSNotificationCenter defaultCenter])
    {
        if (!_syncQueue){
             _syncQueue = [[NSOperationQueue alloc] init];
             _syncQueue.maxConcurrentOperationCount = 1;
        }
        return _syncQueue;
    }
}


/*--------------------------------------------------------------------------------------------------------------
 @property (class, nonatomic, strong, nullable) Token* token;
 --------------------------------------------------------------------------------------------------------------*/
+ (void)setToken:(Token *)token
{
    @synchronized ([NSNotificationCenter defaultCenter]){
        _token = token;
    }
}

+ (Token* _Nullable)token
{
    @synchronized ([NSNotificationCenter defaultCenter])
    {
        if (!_token){
             _token = [APIManager restoreTokenFromKeychain];
        }
        return _token;
    }
}

/*--------------------------------------------------------------------------------------------------------------
 @property (class, nonatomic, strong) NSString* baseURL;
 --------------------------------------------------------------------------------------------------------------*/
+ (void)setBaseURL:(NSString *)baseURL
{
    @synchronized ([NSNotificationCenter defaultCenter]){
        _baseURL = baseURL;
    }
}

+ (NSString *)baseURL
{
    @synchronized ([NSNotificationCenter defaultCenter]){
        
        if (!_baseURL){
             _baseURL = @"https://api.vk.com/method/";
        }
        return _baseURL;
    }
}

@end
