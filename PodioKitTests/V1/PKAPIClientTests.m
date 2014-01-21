//
//  PKAPIClientTests.m
//  PodioKit
//
//  Created by Sebastian Rehnby on 12/5/12.
//  Copyright (c) 2012 Citrix Systems, Inc. All rights reserved.
//

#import "PKAPIClientTests.h"
#import "OHHTTPStubs.h"
#import "PKTAPIClient.h"
#import "PKRequestManager.h"
#import "PKOAuth2Token.h"

static NSString * const kAPIKey = @"test-api-key";
static NSString * const kAPISecret = @"test-api-secret";
static NSString * const kBasicAuthHeaderForAPIKeySecret = @"Basic dGVzdC1hcGkta2V5OnRlc3QtYXBpLXNlY3JldA==";

@interface PKAPIClientTests ()

@property (strong) PKAPIClient *apiClient;

@end

@implementation PKAPIClientTests

- (void)setUp {
  self.apiClient = [[PKAPIClient alloc] initWithAPIKey:kAPIKey apiSecret:kAPISecret];
  [PKRequestManager sharedManager].apiClient = self.apiClient;
}

- (void)tearDown {
  self.apiClient = nil;
  [OHHTTPStubs removeAllRequestHandlers];
}

- (void)testAuthenticate {
  [self stubResponseForPath:@"/oauth/token" withJSONObject:[self validTokenResponse] statusCode:200];
  
  [self waitForCompletionWithBlock:^{
    [self.apiClient authenticateWithEmail:@"me@pdio.com" password:@"Myp4$$w0rD" completion:^(NSError *error, PKRequestResult *result) {
      [self finish];
    }];
  }];
  
  XCTAssertNotNil(self.apiClient.oauthToken, @"Token should not be nil");
}

- (void)testRefreshWhenTokenInvalid {
  // Token will expire very soon
  NSDictionary *validDict = [self validTokenResponse];
  NSDictionary *soonExpiredDict = [self soonExpiredTokenResponse];
  self.apiClient.oauthToken = [PKOAuth2Token tokenFromDictionary:soonExpiredDict];
  
  [self stubResponseForPath:@"/oauth/token" withJSONObject:validDict statusCode:200];
  [self stubResponseForPath:@"/text" withJSONObject:@{@"text": @"some text"} statusCode:200];
  
  [self waitForCompletionWithBlock:^{
    [[PKRequest getRequestWithURI:@"/text"] startWithCompletionBlock:^(NSError *error, PKRequestResult *result) {
      XCTAssertNil(error, @"Error should be nil, got %@", [error localizedDescription]);
      [self finish];
    }];
  }];
  
  XCTAssertTrue([self.apiClient.oauthToken.accessToken isEqualToString:validDict[@"access_token"]], @"Wrong token, should be %@", validDict[@"access_token"]);
}

- (void)testDontRefreshWhenTokenValid {
  // Token will expire very soon
  NSDictionary *validDict = [self validTokenResponse];
  self.apiClient.oauthToken = [PKOAuth2Token tokenFromDictionary:validDict];
  
  [self stubResponseForPath:@"/text" withJSONObject:@{@"text": @"some text"} statusCode:200];

  [self waitForCompletionWithBlock:^{
    [[PKRequest getRequestWithURI:@"/text"] startWithCompletionBlock:^(NSError *error, PKRequestResult *result) {
      XCTAssertNil(error, @"Error should be nil, got %@", [error localizedDescription]);
      [self finish];
    }];
  }];
  
  XCTAssertTrue([self.apiClient.oauthToken.accessToken isEqualToString:validDict[@"access_token"]], @"Wrong token, should be %@", validDict[@"access_token"]);
}

- (void)testRefreshFailed {
  NSDictionary *soonExpiredDict = [self soonExpiredTokenResponse];
  self.apiClient.oauthToken = [PKOAuth2Token tokenFromDictionary:soonExpiredDict];
  
  [self stubResponseForPath:@"/oauth/token" withJSONObject:nil statusCode:400];
  
  [self waitForNotificiationWithName:PKAPIClientNeedsReauthentication object:self.apiClient inBlock:^{
    [[PKRequest getRequestWithURI:@"/text"] startWithCompletionBlock:^(NSError *error, PKRequestResult *result) {
      XCTAssertNotNil(error, @"Error should not be nil");
      [self finish];
    }];
  }];
  
  XCTAssertNil(self.apiClient.oauthToken, @"Token should have been reset when the refresh failed");
}

- (void)testRefreshFailedDueToNetwork {
  NSDictionary *soonExpiredDict = [self soonExpiredTokenResponse];
  self.apiClient.oauthToken = [PKOAuth2Token tokenFromDictionary:soonExpiredDict];
  
  [self stubResponseForPath:@"/oauth/token" withJSONObject:nil statusCode:0]; // No status code from server
  
  [self waitForCompletionWithBlock:^{
    [[PKRequest getRequestWithURI:@"/text"] startWithCompletionBlock:^(NSError *error, PKRequestResult *result) {
      XCTAssertNotNil(error, @"Error should not be nil");
      [self finish];
    }];
  }];
  
  XCTAssertNotNil(self.apiClient.oauthToken, @"Token should not be reset since this was not a server error");
}

- (void)testUnauthorized {
  self.apiClient.oauthToken = [PKOAuth2Token tokenFromDictionary:[self validTokenResponse]];
  
  [self stubResponseForPath:@"/text" withJSONObject:@{@"text": @"some text"} statusCode:401];
  
  [self waitForNotificiationWithName:PKAPIClientNeedsReauthentication object:self.apiClient inBlock:^{
    [[PKRequest getRequestWithURI:@"/text"] startWithCompletionBlock:^(NSError *error, PKRequestResult *result) {
      XCTAssertNotNil(error, @"Error should not be nil");
      [self finish];
    }];
  }];
  
  XCTAssertNil(self.apiClient.oauthToken, @"Token should have been reset because we got a 401");
}

- (void)testNotAuthenticated {
  [self stubResponseForPath:@"/text" withJSONObject:@{@"text": @"some text"} statusCode:401];
  
  [self waitForCompletionWithBlock:^{
    [[PKRequest getRequestWithURI:@"/text"] startWithCompletionBlock:^(NSError *error, PKRequestResult *result) {
      XCTAssertNotNil(error, @"Error should not be nil");
      [self finish];
    }];
  }];
  
  XCTAssertNil(self.apiClient.oauthToken, @"Token should have been reset because we are not authenticated");
}

- (void)testRequestHeadersPresent {
  self.apiClient.oauthToken = [PKOAuth2Token tokenFromDictionary:[self validTokenResponse]];
  
  NSURLRequest *request = [self.apiClient requestWithMethod:PKRequestMethodGET path:@"/some/path" parameters:nil body:nil];
  PKHTTPRequestOperation *operation = [self.apiClient operationWithRequest:request completion:nil];
  
  XCTAssertNotNil([operation.request.allHTTPHeaderFields valueForKey:@"X-Podio-Request-Id"], @"Missing header 'X-Podio-Request-Id'");
  XCTAssertNotNil([operation.request.allHTTPHeaderFields valueForKey:@"Authorization"], @"Missing header 'Authorization'");
  XCTAssertNotNil([operation.request.allHTTPHeaderFields valueForKey:@"Accept-Language"], @"Missing header 'Accept-Language'");
}

- (void)testAuthorizationHeaderForEmailAndPasswordAuthenticationRequest {
  NSURLRequest *request = [self.apiClient requestForAuthenticationWithEmail:@"email@email.com" password:@"p4ssw0rD"];
  NSString *authHeader = [request.allHTTPHeaderFields valueForKey:@"Authorization"];
  XCTAssertTrue([authHeader isEqualToString:kBasicAuthHeaderForAPIKeySecret], @"Authorization header should be Basic auth with base64 encoded API key/secret, was %@", authHeader);
}

- (void)testAuthorizationHeaderForSSOAuthenticationRequest {
  NSURLRequest *request = [self.apiClient requestForAuthenticationWithSSOBody:@{@"provider" : @"facebook"}];
  NSString *authHeader = [request.allHTTPHeaderFields valueForKey:@"Authorization"];
  XCTAssertTrue([authHeader isEqualToString:kBasicAuthHeaderForAPIKeySecret], @"Authorization header should be Basic auth with base64 encoded API key/secret, was %@", authHeader);
}

- (void)testAuthorizationHeaderForRefreshRequest {
  NSDictionary *soonExpiredDict = [self soonExpiredTokenResponse];
  self.apiClient.oauthToken = [PKOAuth2Token tokenFromDictionary:soonExpiredDict];
  NSURLRequest *request = [self.apiClient requestForRefreshWithRefreshToken:self.apiClient.oauthToken.refreshToken];
  
  NSString *authHeader = [request.allHTTPHeaderFields valueForKey:@"Authorization"];
  XCTAssertTrue([authHeader isEqualToString:kBasicAuthHeaderForAPIKeySecret], @"Authorization header should be Basic auth with base64 encoded API key/secret, was %@", authHeader);
}

#pragma mark - Helpers

- (void)stubResponseForPath:(NSString *)path withJSONObject:(id)object statusCode:(NSUInteger)statusCode {
  [OHHTTPStubs addRequestHandler:^OHHTTPStubsResponse *(NSURLRequest *request, BOOL onlyCheck) {
    if ([request.URL.path isEqualToString:path]) {
      id data = object ? [NSJSONSerialization dataWithJSONObject:object options:0 error:nil] : nil;
      return [OHHTTPStubsResponse responseWithData:data
                                        statusCode:statusCode
                                      responseTime:0
                                           headers:nil];
    }
    
    return nil;
  }];
}

#pragma mark - Fixtures

- (id)validTokenResponse {
  return @{
    @"access_token": @"6eebb61891d7d716b8dc3c45020f54aa",
    @"expires_in": @(28799), // Regular expiration
    @"ref": @{
      @"id": @(12345),
      @"type": @"user"
    },
    @"refresh_token": @"dd7aa62f25d8d8b480293a8985215aa3",
    @"token_type": @"bearer"
  };
}

- (id)soonExpiredTokenResponse {
  return @{
    @"access_token": @"6eebb618917646d8d8dc3c45020f54bb",
    @"expires_in": @(60), // Expires in a minute
    @"ref": @{
      @"id": @(12345),
      @"type": @"user"
    },
    @"refresh_token": @"dd7aa62fd8d84db480293a89sdf8ds8f",
    @"token_type": @"bearer"
  };
}

@end