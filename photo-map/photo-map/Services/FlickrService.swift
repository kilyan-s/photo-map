//
//  FlickrService.swift
//  photo-map
//
//  Created by Kilyan SOCKALINGUM on 07/01/2020.
//  Copyright © 2020 Kilyan SOCKALINGUM. All rights reserved.
//

import Foundation
import Alamofire
import AlamofireImage
import SwiftyJSON

class FlickrService {
    static let instance = FlickrService()
    
    public private(set) var imageUrls = [String]()
    public private(set) var imageArray = [UIImage]()
    
    func createFlickrPhotoUrl(withAnnotation annotation:DroppablePin, andNumberOfPhotos number: Int) -> String {
        return "https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(FLICKR_API_KEY)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=1&radius_units=km&per_page=\(number)&format=json&nojsoncallback=1"
    }
    
    func retrieveUrls(forAnnotation annotation: DroppablePin, completion: @escaping CompletionHandler) {
        let flickrUrl = createFlickrPhotoUrl(withAnnotation: annotation, andNumberOfPhotos: NUMBER_OF_PHOTOS_PER_PAGE)
        
        Alamofire.request(flickrUrl).responseJSON { (response) in
            if response.result.error == nil {
                guard let data = response.data else { return }
                
                if let jsonData = try? JSON(data: data) {
                    if let photosDict = jsonData["photos"]["photo"].array {
                        for photo in photosDict {
                            let postUrl = "https://live.staticflickr.com/\(photo["server"])/\(photo["id"])_\(photo["secret"])_c_d.jpg"
                            self.imageUrls.append(postUrl)
                       }
                    }
                }
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    func retrieveImages(sender: MapVC, completion: @escaping CompletionHandler) {
        //Loop through all images urls saved in retrieveUrls()
        for url in imageUrls {
            Alamofire.request(url).responseImage { (response) in
                guard let image = response.result.value else { return }
                self.imageArray.append(image)
                sender.progressLbl?.text = "\(self.imageArray.count)/\(NUMBER_OF_PHOTOS_PER_PAGE) images downloaded"
                
                if self.imageArray.count == self.imageUrls.count {
                    completion(true)
                }
            }
        }
    }
    
    func cancelAllSessions() {
        print("cancel session")
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadData) in
            sessionDataTask.forEach { (session) in
                session.cancel()
                print("cancel session")
            }
            
            downloadData.forEach { (downloadTask) in
                downloadTask.cancel()
                print("cancel download data")
            }
        }
    }
    
    func clearImagesArray() {
        self.imageUrls = []
        self.imageArray = []
    }
}
