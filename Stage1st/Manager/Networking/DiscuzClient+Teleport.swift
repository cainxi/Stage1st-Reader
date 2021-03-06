//
//  DiscuzClient+Teleport.swift
//  Stage1st
//
//  Created by Zheng Li on 5/24/16.
//  Copyright © 2016 Renaissance. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import Crashlytics
import KissXML

private func generateURLString(_ baseURLString: String, parameters: Parameters) -> String {
    let urlRequest = URLRequest(url: URL(string: baseURLString)!)
    let encodedURLRequest = try? URLEncoding.queryString.encode(urlRequest, with: parameters)
    return encodedURLRequest?.url?.absoluteString ?? "" // FIXME: this should not be nil.
}

public struct MultipartFormEncoding: ParameterEncoding {
    public static var `default`: MultipartFormEncoding { return MultipartFormEncoding() }

    public init() {}

    public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var urlRequest = try urlRequest.asURLRequest()

        guard let parameters = parameters else { return urlRequest }

        let formData = MultipartFormData()

        for (key, value) in parameters {
            if let valueData = "\(value)".data(using: .utf8, allowLossyConversion: false) {
                formData.append(valueData, withName: key)
            } else {
                assert(false)
            }
        }

        if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            urlRequest.setValue(formData.contentType, forHTTPHeaderField: "Content-Type")
        }

        urlRequest.httpBody = try formData.encode()

        return urlRequest
    }
}

// MARK: - Login
public extension DiscuzClient {
    /**
     A check request should be sent to a discuz! server to make sure whether a seccode is necessary for login.

     - parameter noSechashBlock:  Executed if seccode is disabled on this server.
     - parameter hasSeccodeBlock: Executed if seccode is enabled on this server.
     - parameter failureBlock:    Executed if this request failed.

     - returns: Request object.
     */
    @discardableResult
    public func checkLoginType(
        noSechashBlock: @escaping () -> Void,
        hasSeccodeBlock: @escaping (_ sechash: String) -> Void,
        failureBlock: @escaping (_ error: Error) -> Void
    ) -> Request {
        logOut()
        let parameters: Parameters = [
            "module": "secure",
            "version": 1,
            "mobile": "no",
            "type": "login",
        ]
        return Alamofire.request(baseURL + "/api/mobile/index.php", parameters: parameters).responseSwiftyJSON { response in
            debugPrint(response.request as Any)
            switch response.result {
            case let .success(json):
                if let sechash = json["Variables"]["sechash"].string {
                    hasSeccodeBlock(sechash)
                } else {
                    noSechashBlock()
                }
            case let .failure(error):
                failureBlock(error)
            }
        }
    }

    public enum AuthMode {
        case basic
        case secure(hash: String, code: String)
    }

    /**
     Request to login when seccode is not necessary.

     - parameter username:             Username of account.
     - parameter password:             Password of account.
     - parameter secureQuestionNumber: Secure question number of account. This should be set to 0 if no question is setted.
     - parameter secureQuestionAnswer: Answer of secure question of account.
     - parameter authMode:             Auth mode for log in.
     - parameter successBlock:         Executed if login request finished without network error.
     - parameter failureBlock:         Executed if login request not finished due to network error.

     - returns: Request object.
     */
    @discardableResult
    public func logIn(
        username: String,
        password: String,
        secureQuestionNumber: Int,
        secureQuestionAnswer: String,
        authMode: AuthMode,
        completion: @escaping (Result<String?>) -> Void
    ) -> Request {
        var URLParameters: Parameters = [
            "module": "login",
            "version": 1,
            "loginsubmit": "yes",
            "loginfield": "auto",
            "cookietime": 2_592_000,
            "mobile": "no",
        ]

        if case let .secure(hash, code) = authMode {
            URLParameters["sechash"] = hash
            URLParameters["seccodeverify"] = code
        }
        let URLString = generateURLString(baseURL + "/api/mobile/", parameters: URLParameters)

        let bodyParameters: Parameters = [
            "username": username,
            "password": password,
            "questionid": secureQuestionNumber,
            "answer": secureQuestionAnswer,
        ]

        var debugHeader: String? = nil
        var debugRequestMethod: String? = nil
        var debugURLString: String? = nil
        var debugMIMEType: String? = nil
        var debugBodyString: String? = nil

        return Alamofire.request(URLString, method: .post, parameters: bodyParameters, encoding: MultipartFormEncoding.default).responseString(completionHandler: { (response) in
            debugRequestMethod = response.request?.httpMethod
            debugHeader = response.response?.description
            debugURLString = response.response?.url?.absoluteString
            debugMIMEType = response.response?.mimeType
            debugBodyString = response.value
        }).responseSwiftyJSON { response in
            debugPrint(response.request as Any)
            switch response.result {
            case let .success(json):
                if let messageValue = json["Message"]["messageval"].string, messageValue.contains("login_succeed") {
                    AppEnvironment.current.settings.currentUsername.value = username
                    NotificationCenter.default.post(name: .DZLoginStatusDidChangeNotification, object: nil)
                    completion(.success(json["Message"]["messagestr"].string))
                } else {
                    completion(.failure(DZError.loginFailed(messageValue: json["Message"]["messageval"].stringValue, messageString: json["Message"]["messagestr"].stringValue)))
                }
            case let .failure(error):
                if case AFError.responseSerializationFailed = error {
                    let userInfo = [
                        "method": debugRequestMethod ?? "",
                        "header": debugHeader ?? "",
                        "url": debugURLString ?? "",
                        "MIME": debugMIMEType ?? "",
                        "body": debugBodyString ?? ""
                    ]
                    let recoredError = NSError(domain: "LoginSerializationFailed", code: 0, userInfo: userInfo)
                    Crashlytics.sharedInstance().recordError(recoredError)
                }
                completion(.failure(error))
            }
        }
    }

    @discardableResult
    func getSeccodeImage(sechash: String, completion: @escaping (Result<UIImage>) -> Void) -> Request {
        let parameters: Parameters = [
            "module": "seccode",
            "version": 1,
            "mobile": "no",
            "sechash": sechash
        ]
        return Alamofire.request(baseURL + "/api/mobile/index.php", parameters: parameters).responseImage { response in
            switch response.result {
            case let .success(image):
                completion(.success(image))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func logOut(_ completionHandler: () -> Void = {}) {
        let cookieStorage = AppEnvironment.current.cookieStorage
        if let cookies = cookieStorage.cookies {
            for cookie in cookies {
                cookieStorage.deleteCookie(cookie)
            }
        }

        AppEnvironment.current.settings.removeValue(for: .currentUsername) // TODO: move this to finish block.
        NotificationCenter.default.post(name: .DZLoginStatusDidChangeNotification, object: nil)
        completionHandler()
    }

    func isInLogin() -> Bool { // TODO: check cookies rather than a global state.
        return AppEnvironment.current.settings.currentUsername.value != nil
    }
}

// MARK: - Topic List
public extension DiscuzClient {
    @discardableResult
    public func topics(
        in fieldID: UInt,
        page: UInt,
        completion: @escaping (Result<(Field, [S1Topic], String?, String?)>) -> Void
    ) -> Alamofire.Request {
        let parameters: Parameters = [
            "module": "forumdisplay",
            "version": 1,
            "tpp": 50,
            "submodule": "checkpost",
            "mobile": "no",
            "fid": fieldID,
            "page": page,
            "orderby": "dblastpost",
        ]

        return Alamofire.request(baseURL + "/api/mobile/index.php", parameters: parameters).responseSwiftyJSON { response in
            switch response.result {
            case let .success(json):
                if let serverErrorMessage = json["error"].string, serverErrorMessage != "" {
                    completion(.failure(DZError.serverError(message: serverErrorMessage)))
                    return
                }

                if let serverErrorMessage = json["Message"]["messagestr"].string, serverErrorMessage != "" {
                    completion(.failure(DZError.serverError(message: serverErrorMessage)))
                    return
                }

                guard let topicList = json["Variables"]["forum_threadlist"].array else {
                    completion(.failure(DZError.noThreadListReturned(jsonString: json.rawString() ?? "")))
                    return
                }

                guard let field = Field(json: json["Variables"]) else {
                    completion(.failure(DZError.noFieldInfoReturned(jsonString: json.rawString() ?? "")))
                    return
                }

                let topics = topicList
                    .map { S1Topic(json: $0, fieldID: field.ID) }
                    .compactMap { $0 }

                let username = json["Variables"]["member_username"].string
                let formhash = json["Variables"]["formhash"].string

                completion(.success((field, topics, username, formhash)))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Content
public extension DiscuzClient {
    @discardableResult
    public func floors(
        in topicID: UInt,
        page: UInt,
        completion: @escaping (Result<(S1Topic?, [Floor], String?)>) -> Void
    ) -> Alamofire.Request {
        let parameters: Parameters = [
            "module": "viewthread",
            "version": 1,
            "ppp": 30,
            "submodule": "checkpost",
            "mobile": "no",
            "tid": topicID,
            "page": page,
        ]

        return Alamofire.request(baseURL + "/api/mobile/index.php", parameters: parameters).responseJSON { response in
            switch response.result {
            case let .success(json):

                guard let jsonDictionary = json as? [String: Any] else {
                    completion(.failure("Invalid response."))
                    return
                }

                if
                    let message = jsonDictionary["Message"] as? [String: Any],
                    let messageString = message["messagestr"] as? String
                {
                    completion(.failure(DZError.serverError(message: messageString)))
                    return
                }

                let variables = jsonDictionary["Variables"] as? [String: Any]
                let username = variables.flatMap { $0["member_username"] as? String }

                let topicFromPageResponse = S1Parser.topicInfo(fromAPI: jsonDictionary)
                let floorsFromPageResponse = S1Parser.contents(fromAPI: jsonDictionary)

                guard floorsFromPageResponse.count > 0 else {
                    completion(.failure("Empty floors."))
                    return
                }

                completion(.success((topicFromPageResponse, floorsFromPageResponse, username)))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Profile
public extension DiscuzClient {
    @discardableResult
    public func profile(
        userID: Int,
        completion: @escaping (Result<User>) -> Void
    ) -> Request {
        let parameters: Parameters = [
            "module": "profile",
            "version": 1,
            "uid": userID,
            "mobile": "no",
        ]

        return Alamofire.request(baseURL + "/api/mobile/index.php", parameters: parameters).responseSwiftyJSON { response in
            switch response.result {
            case let .success(json):
                guard let user = User(json: json) else {
                    completion(.failure(DZError.userInfoParseFailed(jsonString: json.rawString() ?? "")))
                    return
                }
                completion(.success(user))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Report
public extension DiscuzClient {
    @discardableResult
    func report(
        topicID: String,
        floorID: String,
        forumID: String,
        reason: String,
        formhash: String,
        completion: @escaping (Error?) -> Void
    ) -> Request {
        let URLParameters: Parameters = [
            "mod": "report",
            "inajax": 1,
        ]

        let URLString = generateURLString(baseURL + "/misc.php", parameters: URLParameters)

        let bodyParameters: Parameters = [
            "report_select": "其他",
            "message": reason,
            "referer": baseURL + "/forum.php?mod=viewthread&tid=\(topicID)",
            "reportsubmit": "true",
            "rtype": "post",
            "rid": floorID,
            "fid": forumID,
            "url": "",
            "inajax": 1,
            "handlekey": "miscreport1",
            "formhash": formhash,
        ]

        return Alamofire.request(URLString, method: .post, parameters: bodyParameters).responseString { response in
            completion(response.result.error)
        }
    }
}

// MARK: - Search

public extension DiscuzClient {
    @discardableResult
    func search(
        for keyword: String,
        formhash: String,
        completion: @escaping (Result<([S1Topic], String?)>) -> Void
    ) -> Request {
        let params: Parameters = [
            "mod": "forum",
            "formhash": formhash,
            "srchtype": "title",
            "srhfid": "",
            "srhlocality": "forum::index",
            "srchtxt": keyword,
            "searchsubmit": "true"
        ]

        return Alamofire.request(baseURL + "/search.php?searchsubmit=yes", method: .post, parameters: params).responseData { (response) in
            switch response.result {
            case .success(let data):
                guard let document = try? DDXMLDocument(data: data, options: 0) else {
                    completion(.failure(DZError.searchResultParseFailed))
                    return
                }

                let elements = (try? document.elements(for: "//div[@id='threadlist']/ul/li[@class='pbw']")) ?? []
                S1LogDebug("Search result topic count: \(elements.count)")
                let topics = elements.compactMap { S1Topic(element: $0) }

                var searchID: String? = nil
                let theNextPageLinks = (try? document.nodes(forXPath: "//div[@class='pg']/a[@class='nxt']/@href")) ?? []
                if
                    let rawNextPageURL = theNextPageLinks.first?.stringValue,
                    let nextPageURL = rawNextPageURL.gtm_stringByUnescapingFromHTML(),
                    let queryItems = URLComponents(string: nextPageURL)?.queryItems,
                    let theSearchID = queryItems.first(where: { $0.name == "searchid" })?.value
                {
                    searchID = theSearchID
                }

                completion(.success((topics, searchID)))

            case .failure(let error):
                completion(.failure(DZError.serverError(message: error.localizedDescription)))
            }
        }
    }

    @discardableResult
    func search(
        with searchID: String,
        page: Int,
        completion: @escaping (Result<([S1Topic], String?)>) -> Void
    ) -> Request {
        let params: Parameters = [
            "mod": "forum",
            "searchid": searchID,
            "orderby": "lastpost",
            "ascdesc": "desc",
            "page": page,
            "searchsubmit": "yes"
        ]

        return Alamofire.request(baseURL + "/search.php", parameters: params).responseData { (response) in
            switch response.result {
            case .success(let data):
                guard let document = try? DDXMLDocument(data: data, options: 0) else {
                    completion(.failure(DZError.searchResultParseFailed))
                    return
                }

                let elements = (try? document.elements(for: "//div[@id='threadlist']/ul/li[@class='pbw']")) ?? []
                S1LogDebug("Search result page \(page) topic count: \(elements.count)")
                let topics = elements.compactMap { S1Topic(element: $0) }

                var searchID: String? = nil
                let theNextPageLinks = (try? document.nodes(forXPath: "//div[@class='pg']/a[@class='nxt']/@href")) ?? []
                if
                    let rawNextPageURL = theNextPageLinks.first?.firstText,
                    let nextPageURL = rawNextPageURL.gtm_stringByUnescapingFromHTML(),
                    let queryItems = URLComponents(string: nextPageURL)?.queryItems,
                    let theSearchID = queryItems.first(where: { $0.name == "searchid" })?.value
                {
                    searchID = theSearchID
                }

                completion(.success((topics, searchID)))

            case .failure(let error):
                completion(.failure(DZError.serverError(message: error.localizedDescription)))
            }
        }
    }
}
