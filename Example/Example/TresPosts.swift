//
//  TresPosts.swift
//  Example
//
//  Created by Gustavo B Tagliari on 31/03/17.
//  Copyright © 2017 AIORIA SOFTWARE HOUSE. All rights reserved.
//

import Foundation

class TresPosts: NSObject {
    var postDireita: Post?
    var postCentro: Post?
    var postEsquerda: Post?
}

class Post: NSObject {
    
}

extension Array where Element: Post {
    func groupTo(using posts: [TresPosts]? = nil) -> [TresPosts] {
        
        var photos = posts ?? [TresPosts]()
        
        var lastPhoto: TresPosts? = photos.last
        
        if lastPhoto?.postDireita != nil {
            lastPhoto = nil
        }
        
        for post in self {
            if lastPhoto == nil {
                lastPhoto = TresPosts()
                lastPhoto!.postEsquerda = post
            } else {
                if lastPhoto!.postCentro == nil {
                    lastPhoto!.postCentro = post
                } else {
                    lastPhoto!.postDireita = post
                    
                    if !photos.contains(lastPhoto!) {
                        photos.append(lastPhoto!)
                    }
                    
                    lastPhoto = nil
                }
            }
        }
        
        if lastPhoto != nil && !photos.contains(lastPhoto!) {
            photos.append(lastPhoto!)
        }
        
        return photos
    }
}

extension Array where Element: TresPosts {
    func ungroup() -> [Post] {
        var posts = [Post]()
        for post in self {
            if let p = post.postEsquerda {
                posts.append(p)
            }
            
            if let p = post.postCentro {
                posts.append(p)
            }
            
            if let p = post.postDireita {
                posts.append(p)
            }
        }
        return posts
    }
}
