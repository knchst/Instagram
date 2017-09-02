//
//  InstagramModels.swift
//  Instagram
//
//  Created by Scott Gauthreaux on 12/01/16.
//  Copyright © 2016 Scott Gauthreaux. All rights reserved.
//

// TODO: Try to minimize the occurrences of AnyObject
// TODO: Document methods

import Foundation

/// The protocol defining what all Instagram models are supposed to be initialized
public protocol InstagramModel {
    var id : String { get }
    init(id: String)
    init?(data: AnyObject)
}


/// Defines the possible media types (currently image and video)
public enum InstagramMediaType : String {
    case Image = "image"
    case Video = "video"
}


/// Represents an Instagram user
public struct InstagramUser: InstagramModel {
    public var id : String
    var bio = ""
    var fullName = ""
    var profilePicture = ""
    var username = ""
    var website : String?
    
    public init(id: String) {
        self.id = id
    }

    public
    init?(data: AnyObject) {
        guard let id  =   data["id"] as? String,
            let fullName        =   data["full_name"] as? String,
            let profilePicture  =   data["profile_picture"] as? String,
            let username        =   data["username"] as? String
            else { return nil }
        
        self.id = id
        
        if let bio             =   data["bio"] as? String {
            self.bio = bio
        }

        
        self.fullName = fullName
        self.profilePicture = profilePicture
        self.username = username
        self.website = data["website"] as? String
    }
}

/// Represents a relationship between two Instagram Users
public struct InstagramRelationship: InstagramModel {
    public var id : String
    var outgoingStatus = ""
    var incomingStatus = ""
    
    public init(id: String) {
        self.id = id
    }
    
    public init?(data: AnyObject) {
        guard let id  =   data["id"] as? String,
            let outgoingStatus = data["outgoing_status"] as? String,
            let incomingStatus = data["incoming_status"] as? String
            else { return nil}
        
        self.id = id
        self.outgoingStatus = outgoingStatus
        self.incomingStatus = incomingStatus
    }
}

/// Represents an instagram media object that can either be an image or a video
public struct InstagramMedia: InstagramModel {
    public var id : String
    var comments : [InstagramComment] = []
    var caption : InstagramCaption?
    var link = ""
    var standardResolutionURL = ""
    var location : InstagramLocation?
    var tags : [InstagramTag] = []
    var type : InstagramMediaType
    var user : InstagramUser?
    
    public init(id: String) {
        self.id = id
        self.type = .Image
    }
    
    init(id: String, type: InstagramMediaType) {
        self.id = id
        self.type = type
    }
    
    public init?(data: AnyObject) {
        guard let id = data["id"] as? String,
        let typeString = data["type"] as? String,
        let type = InstagramMediaType(rawValue: typeString),
            let link = data["link"] as? String else {
                return nil
        }

        self.id = id
        self.type = type
        self.link = link
        
        if let images = data["images"] as? [String: Any],
            let standardResolution = images["standard_resolution"] as? [String: String],
            let url = standardResolution["url"] {
            self.standardResolutionURL = url
        }
    }
    
    /// Gets the image data for the current InstagramImage object
    public func getImageData(_ closure: @escaping (Data?) -> Void) {
        print("Getting image \(self)")
        DispatchQueue.global(qos: DispatchQoS.QoSClass.utility).async {
            // print(URL(string: self.standardResolutionURL))
            if let url = URL(string: self.standardResolutionURL), let data = try? Data(contentsOf: url) {
                DispatchQueue.main.async {
                    print("Got image")
                    closure(data)
                }
            } else {
                DispatchQueue.main.async {
                    print("Failed to get image")
                    closure(nil)
                }
            }
        }
        
    }
}

/// Represents a caption on an InstagramMedia object
public struct InstagramCaption: InstagramModel {
    public var id: String
    var from : InstagramUser?
    var text = ""
    
    public init(id: String) {
        self.id = id
    }
  
    public init?(data: AnyObject) {
        guard let id  =   data["id"] as? String
            else { return nil}
        
        self.id = id
    }
}

/// Represents a comment made by a user on a given media object
public struct InstagramComment: InstagramModel {
    public var id: String
    var from : InstagramUser?
    var createdTime = ""
    var text = ""
    
    public init(id: String) {
        self.id = id
    }
    
    public init?(data: AnyObject) {
        guard let id  =   data["id"] as? String
            else { return nil}
        
        self.id = id
    }
}

/// Represents a like on a media object
public struct InstagramLike: InstagramModel {
    public var id: String
    
    public init(id: String) {
        self.id = id
    }
    
    public init?(data: AnyObject) {
        guard let id  =   data["id"] as? String
            else { return nil}
        
        self.id = id
    }
}

/// A tag on a media object, can be used to search for other media with the same tag
public struct InstagramTag: InstagramModel {
    public var id: String
    public var name: String = ""
    
    public init(id: String) {
        self.id = id
    }
    
    public init?(data: AnyObject) {
        guard let id  =   data["id"] as? String
            else { return nil}
        
        self.id = id
    }
}

/// A simple struct representing a location in the Instagram graph
public struct InstagramLocation: InstagramModel {
    public var id: String
    
    public init(id: String) {
        self.id = id
    }
    
    public init?(data: AnyObject) {
        guard let id  =   data["id"] as? String
            else { return nil}
        
        self.id = id
    }
}
