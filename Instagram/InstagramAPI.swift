//
//  InstagramAPI.swift
//  Photo Tiles
//
//  Created by Scott Gauthreaux on 10/01/16.
//  Copyright © 2016 Scott Gauthreaux. All rights reserved.
//

import Foundation

public enum HTTPMethod : String {
    case Get = "GET"
    case Post = "POST"
    case Put = "PUT"
    case Delete = "DELETE"
}




open class InstagramAPI {
    let baseAPIURL = "https://api.instagram.com/v1"
    var clientId : String?
    var clientSecret : String?
    open var accessToken : String?
    
    // TODO: add login and auth functions
    // TODO: do we need to move some of the relative API methods to objects? For example getUserRecentMedia, what about a user.getRecentMedia() function?
    // TODO: add caching
    
    // MARK: - Convenience methods
    
    /// Initializes the API instance
    public init(clientId: String, clientSecret: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
    }

    
    /// Performs a given API request and retrieves data from the Instagram REST API
    /// This method shouldn't be accessed outside of the scope of this library as it is a low level method
    func performAPIRequest(_ urlString: String, withParameters parameters: [String:AnyObject]? = nil, usingMethod method: HTTPMethod = .Get, completion: @escaping (AnyObject?) -> Void) {
        var urlString = urlString
        guard let accessTokenString = accessToken else {
            print("Attempted to call \"performAPIRequest\" before authentication")
            completion(nil)
            return
        }
        
        urlString += "?access_token=" + accessTokenString
        
        if parameters != nil {
            for (parameterKey, parameterValue) in parameters! {
                urlString += "&\(parameterKey)=\(parameterValue)"
            }
        }
        
        guard let url = URL(string: baseAPIURL + urlString) else {
            print("Invalid url string supplied\"\(urlString)\" when calling performAPIRequest")
            completion(nil)
            return
        }
        

        
        print(url)
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil && data != nil else { // check for fundamental networking error
                print("error=\(String(describing: error))")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(String(describing: response))")
                if data != nil {
                    print("data = \(String(data: data!, encoding: String.Encoding.utf8)!)")
                }
            }
            
            do {
                let responseObject = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String:AnyObject]
                
                if responseObject!["meta"]!["code"] as! Int == 200 {
                    completion(responseObject!["data"]!)
                }

            } catch {
                print("An error occurred while trying to convert the json data to an object")
            }
        }
        task.resume()
        
        return
    }
    
    /// This is a convenience method used to convert an arbitrary response into an array of *InstagramModel* objects
    func objectsArray<T: InstagramModel>(_ withType: T.Type, fromData data: AnyObject?) -> [T]? {
        guard let datas = data as? [AnyObject] else {
            return nil
        }
        
        var newObjects = [T]()
        
        for objectData in datas {
            if let newObject = T(data: objectData) {
                newObjects.append(newObject)
            }
        }
        
        return newObjects
    }
    
    
    // MARK: - User Endpoint
    
    
   
    /// Get information about the current user
    open func getUser(_ completion: @escaping (InstagramUser?) -> Void) {
        _getUser(nil, completion: completion)
    }
    
    /// Get information about a user with the given id
    open func getUser(_ userId: String, completion: @escaping (InstagramUser?) -> Void) {
        _getUser(userId, completion: completion)
    }
    
    /// The method that actually gets information about users from the Instagram API
    func _getUser(_ userId: String?, completion: @escaping (InstagramUser?) -> Void) {
        let userIdParameter = userId != nil ? "\(userId!)" : "self"
        performAPIRequest("/users/"+userIdParameter) { responseData in
            guard let responseData = responseData, let instagramUser = InstagramUser(data: responseData) else {
                completion(nil)
                return
            }
            
            completion(instagramUser)
        }
    }
    
    /// Gets the current user's recent media
    open func getUserRecentMedia(count: Int? = nil, minId: String? = nil, maxId: String? = nil, completion: @escaping ([InstagramMedia]?) -> Void) {
        _getUserRecentMedia(nil, count: count, minId: minId, maxId: maxId, completion: completion)
    }
    
    
    /// Gets the specified user's recent media
    open func getUserRecentMedia(userId: String, count: Int? = nil, minId: String? = nil, maxId: String? = nil, completion: @escaping ([InstagramMedia]?) -> Void) {
        _getUserRecentMedia(userId, count: count, minId: minId, maxId: maxId, completion: completion)
    }

    /// The method that actually gets a user's recent media
    func _getUserRecentMedia(_ userId: String?, count: Int? = nil, minId: String? = nil, maxId: String? = nil, completion: @escaping ([InstagramMedia]?) -> Void) {
        let userIdParameter = userId != nil ? "\(userId!)" : "self"
        var parameters = [String:AnyObject]()
        if count != nil {
            parameters["count"] = count! as AnyObject
        }
        
        if minId != nil {
            parameters["min_id"] = minId! as AnyObject
        }
        
        if maxId != nil {
            parameters["max_id"] = maxId! as AnyObject
        }
        
        performAPIRequest("/users/\(userIdParameter)/media/recent", withParameters: parameters) {[weak self] in completion(self?.objectsArray(InstagramMedia.self, fromData: $0))}
    }
    
    /// Gets the current user's recently liked media
    open func getUserLikedMedia(count: Int? = nil, maxLikeId: String? = nil, completion: @escaping ([InstagramMedia]?) -> Void) {
        var parameters = [String:AnyObject]()
        
        if count != nil {
            parameters["count"] = count! as AnyObject
        }
        
        if maxLikeId != nil {
            parameters["max_like_id"] = maxLikeId! as AnyObject
        }
        
        performAPIRequest("/users/self/media/liked", withParameters: parameters) {[weak self] in completion(self?.objectsArray(InstagramMedia.self, fromData: $0))}
    }
    
    /// Searches users with usernames containing the given keyword
    open func searchForUsers(query: String, count: Int? = nil, completion: @escaping ([InstagramUser]?) -> Void) {
        var parameters = [String:AnyObject]()
        
        parameters["q"] = query as AnyObject
        
        if count != nil {
            parameters["count"] = count! as AnyObject
        }
        
        
        performAPIRequest("/users/search", withParameters: parameters) {[weak self] in completion(self?.objectsArray(InstagramUser.self, fromData: $0))}
        
    }
    
    /// Searches for one user with a given username
    /// Will only return a user if the username matches exactly the provided username
    open func searchForUser(_ userName: String, completion: @escaping (InstagramUser?) -> ()) {
        searchForUsers(query: userName) { users in
            guard let users = users else {
                completion(nil)
                return
            }
            for user in users {
                if user.username == userName {
                    completion(user)
                    return
                }
            }
            completion(nil)
        }
    }
    
    
    // MARK: - Relationships Endpoint
    
    /// Gets the users followed by the current user
    open func getUserFollows(completion: @escaping ([InstagramUser]?) -> Void) {
        performAPIRequest("/users/self/follows") {[weak self] in completion(self?.objectsArray(InstagramUser.self, fromData: $0))}
    }
    
    /// Gets the followers of the current user
    open func getUserFollowedBy(completion: @escaping ([InstagramUser]?) -> Void) {
        performAPIRequest("/users/self/followed-by") {[weak self] in completion(self?.objectsArray(InstagramUser.self, fromData: $0))}
    }
    
    /// Gets the follow requests for the current user
    /// Note: This will be empty if the current user has a public profile because requests instantly become followers
    open func getUserRequestedBy(completion: @escaping ([InstagramUser]?) -> Void) {
        performAPIRequest("/users/self/requested-by") {[weak self] in completion(self?.objectsArray(InstagramUser.self, fromData: $0))}
    }
    
    /// Gets information about the current user's relationship to the specified user
    open func getUserRelationship(to userId:String, completion:@escaping (InstagramRelationship?) -> Void) {
        performAPIRequest("/users/\(userId)/relationship") { responseData in
            guard let responseData = responseData, let relationship = InstagramRelationship(data: responseData) else {
                completion(nil)
                return
            }
            
            completion(relationship)
        }
    
    }
    
    /// Updates the current user's relationship to the specified user
    open func setUserRelationship(to userId:String, relation: String, completion:@escaping (InstagramRelationship?) -> Void) {
        performAPIRequest("/users/\(userId)/relationship", withParameters: ["action":relation as AnyObject], usingMethod: .Post) { responseData in
            guard let responseData = responseData, let relationship = InstagramRelationship(data: responseData) else {
                completion(nil)
                return
            }
            
            completion(relationship)
        }
    }
    
    // MARK: Relationships Objects Endpoint
    
    /// The same as getUserRelationship(to:completion:) but an instance of InstagrammUser can be passed as the first argument
    open func getUserRelationship(to user:InstagramUser, completion:@escaping (InstagramRelationship?) -> Void) {
        getUserRelationship(to: user.id, completion: completion)
    }
    
    /// The same as setUserRelationship(to:relation:completion:) but instances of InstagramUser and InstagramRelationship can be passed instead of strings
    open func setUserRelationship(to user:InstagramUser, relation: InstagramRelationship, completion:@escaping (InstagramRelationship?) -> Void) {
        setUserRelationship(to: user.id, relation: relation.outgoingStatus, completion: completion)
    }
    
    
    // MARK: - Media Endpoint
    
    /// Gets the media with the specified ID
    open func getMedia(id: String, completion: @escaping (InstagramMedia?) -> Void) {
        performAPIRequest("/media/"+id) { responseData in
            guard let responseData = responseData, let media = InstagramMedia(data: responseData) else {
                completion(nil)
                return
            }
            completion(media)
        }
    }
    
    /// Gets the media with the specified shortcode
    open func getMedia(shortcode: String, completion: @escaping (InstagramMedia?) -> Void) {
        performAPIRequest("/media/shortcode/\(shortcode)") { responseData in
            guard let responseData = responseData, let media = InstagramMedia(data: responseData) else {
                completion(nil)
                return
            }
            completion(media)
        }
    }
    
    /// Searches for media in a specific location 
    /// The default distance is 1000 (1 km) and the max is 5 km
    open func searchMedia(lat: Double, lng: Double, distance: Int? = nil, completion: @escaping ([InstagramMedia]?) -> Void) {
        var parameters = [String:AnyObject]()
        parameters["lat"] = lat as AnyObject
        parameters["lng"] = lng as AnyObject
        if distance != nil {
            parameters["distance"] = distance! as AnyObject
        }
        
        performAPIRequest("/media/search", withParameters: parameters, usingMethod: .Get) {[weak self] in completion(self?.objectsArray(InstagramMedia.self, fromData: $0))}
    }
    
    
    // MARK: - Comments Endpoint
    
    /// Gets the comments on a specified media
    open func getMediaComments(mediaId id: String, completion: @escaping ([InstagramComment]?) -> Void) {
        performAPIRequest("/media/\(id)/comments") {[weak self] in completion(self?.objectsArray(InstagramComment.self, fromData: $0))}
    }
    
    /// Adds a comment to the specified media
    open func addMediaComment(mediaId id: String, comment: String, completion: @escaping (Bool) -> Void) {
        performAPIRequest("/media/\(id)/comments", withParameters: ["text":comment as AnyObject], usingMethod: .Post) { responseData in
            completion(responseData != nil)
        }
    }
    
    /// Removes the user's specified comment from the media
    open func removeMediaComment(mediaId id: String, commentId: String, completion: @escaping (Bool) -> Void) {
        performAPIRequest("/media/\(id)/comments/\(commentId)", usingMethod: .Delete) { responseData in
            completion(responseData != nil)
        }
    }
    
    // MARK: Comments Objects Endpoint
    
    /// The same as getMediaComments(mediaId:completion:) but can pass an instance of InstagramMedia instead of its id
    open func getMediaComments(_ media: InstagramMedia, completion: @escaping ([InstagramComment]?) -> Void) {
        getMediaComments(mediaId: media.id, completion: completion)
    }
    
    /// The same as addMediaComment(mediaId:comment:completion:) but can pass instances of InstagramMedia and InstagramComment instead of strings
    open func addMediaComment(_ media: InstagramMedia, comment: InstagramComment, completion: @escaping (Bool) -> Void) {
        addMediaComment(mediaId: media.id, comment: comment.text, completion: completion)
    }
    
    /// The same as removeMediaComment(mediaId:commentId:completion:) but can pass instances of InstagramMedia and InstagramComment instead of strings
    open func removeMediaComment(_ media: InstagramMedia, comment: InstagramComment, completion: @escaping (Bool) -> Void) {
        removeMediaComment(mediaId: media.id, commentId: comment.id, completion: completion)
    }
    
    
    // MARK: - Likes Endpoint
    
    /// Gets all the likes on the specified media
    open func getMediaLikes(mediaId id: String, completion: @escaping ([InstagramLike]?) -> Void) {
        performAPIRequest("/media/\(id)/likes") {[weak self] in completion(self?.objectsArray(InstagramLike.self, fromData: $0))}
    }
    
    /// Sets a like for the current user on the specified media
    open func setMediaLike(mediaId id: String, completion: @escaping (Bool) -> Void) {
        performAPIRequest("/media/\(id)/comments", usingMethod: .Post) { responseData in
            completion(responseData != nil)
        }
    }
    
    /// Removes the current user's like on the specified media
    open func removeMediaLike(mediaId id: String, completion: @escaping (Bool) -> Void) {
        performAPIRequest("/media/\(id)/comments", usingMethod: .Delete) { responseData in
            completion(responseData != nil)
        }
    }
    
    
    // MARK: - Tags Endpoint
    
    /// Gets information about a certain tag
    open func getTag(_ name: String, completion: @escaping (InstagramTag?) -> Void) {
        performAPIRequest("/tags/\(name)") { responseData in
            guard let responseData = responseData, let tag = InstagramTag(data: responseData) else {
                completion(nil)
                return
            }
            
            completion(tag)
        }
    }
    
    
    /// Gets recent media with the specified tag
    open func getTagRecentMedia(_ name: String, count: Int? = nil, minTagId: String? = nil, maxTagId: String? = nil, completion: @escaping ([InstagramMedia]?) -> Void) {
        var parameters = [String:AnyObject]()
        if count != nil {
            parameters["count"] = count! as AnyObject
        }
        
        if minTagId != nil {
            parameters["min_tag_id"] = minTagId! as AnyObject
        }
        
        if maxTagId != nil {
            parameters["max_tag_id"] = maxTagId! as AnyObject
        }

        performAPIRequest("/tags/\(name)/media/recent", withParameters: parameters) {[weak self] in completion(self?.objectsArray(InstagramMedia.self, fromData: $0))}
    }
    
    /// Searches for tags containing the specified string
    open func searchTags(_ query: String, completion: @escaping ([InstagramTag]?) -> Void) {
        performAPIRequest("/tags/search", withParameters: ["q":query as AnyObject]) {[weak self] in completion(self?.objectsArray(InstagramTag.self, fromData: $0))}
    }
    
    // MARK: Tags Objects Endpoint
    
    /// The same as getTagRecentMedia(name:count:minTagId:maxTagId:completion:) but can pass an instance of InstagramTag instead of the name of the tag
    open func getTagRecentMedia(_ tag: InstagramTag, count: Int? = nil, minTagId: String? = nil, maxTagId: String? = nil, completion: @escaping ([InstagramMedia]?) -> Void) {
        getTagRecentMedia(tag.name, count: count, minTagId: minTagId, maxTagId: maxTagId, completion: completion)
    }

    
    // MARK: - Locations Endpoint
    
    /// Gets the location with the specified id
    open func getLocation(_ locationId: String, completion: @escaping (InstagramLocation?) -> Void) {
        performAPIRequest("/locations/\(locationId)") { responseData in
            guard let responseData = responseData, let location = InstagramLocation(data: responseData) else {
                completion(nil)
                return
            }
            
            completion(location)
        }
    }
    
    /// Gets the recent media for the specified location
    open func getLocationRecentMedia(_ locationId: String, minId: String? = nil, maxId: String? = nil, completion: @escaping ([InstagramMedia]?) -> Void) {
        var parameters = [String:AnyObject]()
        if minId != nil {
            parameters["min_id"] = minId! as AnyObject
        }
        
        if maxId != nil {
            parameters["max_id"] = maxId! as AnyObject
        }
        
        performAPIRequest("/locations/\(locationId)/media/recent", withParameters: parameters) {[weak self] in completion(self?.objectsArray(InstagramMedia.self, fromData: $0))}

    }
    
    /// Searches locations by coordinates
    /// The default distance is 1000 (1km) and the max distance is 5km
    open func searchLocationsByCoordinates(lat: Double, lng: Double, distance: Int? = nil, completion: @escaping ([InstagramLocation]?) -> Void) {
        var parameters = [String:AnyObject]()
        parameters["lat"] = lat as AnyObject
        parameters["lng"] = lng as AnyObject
        
        if distance != nil {
            parameters["distance"] = distance as AnyObject
        }
        
        performAPIRequest("/locations/search", withParameters: parameters) {[weak self] in completion(self?.objectsArray(InstagramLocation.self, fromData: $0))}
    }
    
    /// Searches locations by Facebook Places ID
    open func searchLocationsByFacebookPlacesId(_ id: String, completion: @escaping ([InstagramLocation]?) -> Void) {
        performAPIRequest("/locations/search", withParameters: ["facebook_places_id":id as AnyObject]) {[weak self] in completion(self?.objectsArray(InstagramLocation.self, fromData: $0))}
    }
    
    /// Searches locations by Foursquare ID
    open func searchLocationsByFoursquareId(_ id: String, completion: @escaping ([InstagramLocation]?) -> Void) {
        performAPIRequest("/locations/search", withParameters: ["foursquare_id":id as AnyObject]) {[weak self] in completion(self?.objectsArray(InstagramLocation.self, fromData: $0))}
    }
    
    /// Searches locations by Foursquare V2 ID
    open func searchLocationsByFoursquareV2Id(_ id: String, completion: @escaping ([InstagramLocation]?) -> Void) {
        performAPIRequest("/locations/search", withParameters: ["foursquare_v2_id":id as AnyObject]) {[weak self] in completion(self?.objectsArray(InstagramLocation.self, fromData: $0))}
    }

}


