// Copyright (c) Microsoft Corporation.
// All rights reserved.
//
// This code is licensed under the MIT License.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <XCTest/XCTest.h>
#import "MSIDURLSessionManager.h"
#import "MSIDHttpRequest.h"

@interface MSIDURLSessionManagerTestSession : NSURLSession

@property (nonatomic) BOOL invalidateAndCancelCalled;

@end

@implementation MSIDURLSessionManagerTestSession

- (NSURLSessionConfiguration *)configuration
{
    return [NSURLSessionConfiguration ephemeralSessionConfiguration];
}

- (void)invalidateAndCancel
{
    self.invalidateAndCancelCalled = YES;
}

@end

@interface MSIDURLSessionManagerTests : XCTestCase

@end

@implementation MSIDURLSessionManagerTests

- (void)tearDown
{
    MSIDURLSessionManager.sessionProvider = nil;
    [super tearDown];
}

#pragma mark - Tests

- (void)testDefaultManager_whenNoSessionProvider_shouldReturnSameInstance
{
    MSIDURLSessionManager *first = MSIDURLSessionManager.defaultManager;
    MSIDURLSessionManager *second = MSIDURLSessionManager.defaultManager;

    XCTAssertNotNil(first);
    XCTAssertEqual(first, second);
}

- (void)testDefaultManager_whenSessionProviderSet_shouldWrapProvidedSession
{
    __auto_type externalSession = [MSIDURLSessionManagerTestSession new];
    MSIDURLSessionManager.sessionProvider = ^NSURLSession *{ return externalSession; };

    MSIDURLSessionManager *manager = MSIDURLSessionManager.defaultManager;

    XCTAssertEqual(manager.session, externalSession);
    XCTAssertNotNil(manager.configuration);
}

- (void)testDefaultManager_whenSessionProviderSet_shouldReturnFreshWrapperEachCall
{
    __auto_type externalSession = [MSIDURLSessionManagerTestSession new];
    MSIDURLSessionManager.sessionProvider = ^NSURLSession *{ return externalSession; };

    MSIDURLSessionManager *first = MSIDURLSessionManager.defaultManager;
    MSIDURLSessionManager *second = MSIDURLSessionManager.defaultManager;

    XCTAssertNotEqual(first, second);
    XCTAssertEqual(first.session, second.session);
}

- (void)testDefaultManager_whenSessionProviderSet_shouldNotInvalidateProvidedSessionOnDealloc
{
    __auto_type externalSession = [MSIDURLSessionManagerTestSession new];
    MSIDURLSessionManager.sessionProvider = ^NSURLSession *{ return externalSession; };

    @autoreleasepool
    {
        MSIDURLSessionManager *manager = MSIDURLSessionManager.defaultManager;
        XCTAssertEqual(manager.session, externalSession);
        manager = nil;
    }

    XCTAssertFalse(externalSession.invalidateAndCancelCalled);
}

- (void)testDefaultManager_whenSessionProviderReturnsNil_shouldFallBackToDefaultSession
{
    MSIDURLSessionManager *defaultManager = MSIDURLSessionManager.defaultManager;
    MSIDURLSessionManager.sessionProvider = ^NSURLSession *{ return nil; };

    MSIDURLSessionManager *manager = MSIDURLSessionManager.defaultManager;

    XCTAssertEqual(manager, defaultManager);
}

- (void)testDefaultManager_whenSessionProviderCleared_shouldReturnDefaultSession
{
    MSIDURLSessionManager *defaultManager = MSIDURLSessionManager.defaultManager;
    __auto_type externalSession = [MSIDURLSessionManagerTestSession new];
    MSIDURLSessionManager.sessionProvider = ^NSURLSession *{ return externalSession; };
    XCTAssertEqual(MSIDURLSessionManager.defaultManager.session, externalSession);

    MSIDURLSessionManager.sessionProvider = nil;

    XCTAssertEqual(MSIDURLSessionManager.defaultManager, defaultManager);
}

- (void)testHttpRequestInit_whenSessionProviderSet_shouldUseProvidedSession
{
    __auto_type externalSession = [MSIDURLSessionManagerTestSession new];
    MSIDURLSessionManager.sessionProvider = ^NSURLSession *{ return externalSession; };

    MSIDHttpRequest *request = [MSIDHttpRequest new];

    XCTAssertEqual(request.sessionManager.session, externalSession);
}

- (void)testInitWithExternalSession_shouldExposeSessionAndConfiguration
{
    __auto_type externalSession = [MSIDURLSessionManagerTestSession new];

    MSIDURLSessionManager *manager = [[MSIDURLSessionManager alloc] initWithExternalSession:externalSession];

    XCTAssertEqual(manager.session, externalSession);
    XCTAssertEqual(manager.configuration, externalSession.configuration);
}

@end
