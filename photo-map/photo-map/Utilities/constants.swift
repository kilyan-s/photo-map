//
//  constants.swift
//  photo-map
//
//  Created by Kilyan SOCKALINGUM on 06/01/2020.
//  Copyright © 2020 Kilyan SOCKALINGUM. All rights reserved.
//

import Foundation

typealias CompletionHandler = (_ success: Bool) -> ()

//FLICKER
let FLICKR_API_KEY = "129268bbbeafed9e05d7bea643bccde6"
func flickrUrl(forApiKey key: String, withAnnotation annotation:DroppablePin, andNumberOfPhotos number: Int) -> String {
    return "https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(key)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=1&radius_units=km&per_page=\(number)&format=json&nojsoncallback=1"
}
