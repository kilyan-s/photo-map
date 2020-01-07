//
//  ViewController.swift
//  photo-map
//
//  Created by Kilyan SOCKALINGUM on 06/01/2020.
//  Copyright © 2020 Kilyan SOCKALINGUM. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Alamofire
import AlamofireImage
import SwiftyJSON

class MapVC: UIViewController, UIGestureRecognizerDelegate {
    //Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var pullUpView: UIView!
    @IBOutlet weak var pullUpViewHeightConstraint: NSLayoutConstraint!
    
    //Variables
    var locationManager = CLLocationManager()
    let authStatus = CLLocationManager.authorizationStatus()
    let regionRadius: Double = 1000
    var spinner: UIActivityIndicatorView?
    var progressLbl: UILabel?
    let screenSize = UIScreen.main.bounds
    
    var flowLayout = UICollectionViewFlowLayout()
    var collectionView: UICollectionView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        
        configureLocationServices()
        addDoubleTap()
        addSwipe()
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: "photoCell")
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        pullUpView.addSubview(collectionView!)
    }
    
    func addDoubleTap() {
        //Create a double tap gesture
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin(sender:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        
        //Add the tap gesture to the map view
        mapView.addGestureRecognizer(doubleTap)
    }
    
    func addSwipe() {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(animateViewDown))
        swipe.direction = .down
        
        pullUpView.addGestureRecognizer(swipe)
    }
    
    func animateViewUp() {
        pullUpViewHeightConstraint.constant = 300
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func animateViewDown() {
        FlickrService.instance.cancelAllSessions()
        pullUpViewHeightConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func addSpinner() {
        spinner = UIActivityIndicatorView()
        spinner?.center = CGPoint(x: (screenSize.width/2)-((spinner?.frame.width)!/2), y: 150)
        spinner?.style = .large
        spinner?.color = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)
        spinner?.startAnimating()
        collectionView?.addSubview(spinner!)
    }
    
    func removeSpinner() {
        if spinner != nil {
            spinner?.removeFromSuperview()
        }
    }
    
    func addProgressLabel() {
        progressLbl = UILabel()
        progressLbl?.frame = CGRect(x: (screenSize.width/2)-(300/2), y: 175, width: 300, height: 40)
        progressLbl?.font = UIFont(name: "Avenir-Next", size: 18)
        progressLbl?.textColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        progressLbl?.textAlignment = .center
        collectionView?.addSubview(progressLbl!)
    }
    
    func removeProgressLabel() {
        if progressLbl != nil {
            progressLbl?.removeFromSuperview()
        }
    }

    //Actions
    @IBAction func centerMapBtnPressed(_ sender: Any) {
        if authStatus == .authorizedAlways || authStatus == .authorizedWhenInUse {
            centerMapOnUserLocation()
        }
    }
}

extension MapVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        //Prevent code from changer user location blue dot to a regular pin
        if annotation is MKUserLocation { return nil }
        
        let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin")
        pinAnnotation.pinTintColor = #colorLiteral(red: 0.9771530032, green: 0.7062081099, blue: 0.1748393774, alpha: 1)
        pinAnnotation.animatesDrop = true
        return pinAnnotation
    }
    
    func centerMapOnUserLocation() {
        //Get user coordinate
        guard let userCoordinate = locationManager.location?.coordinate else { return }
        //Create a region center on user location and span of var regionDelta
        let coordinateRegion = MKCoordinateRegion.init(center: userCoordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        //Center map on region
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    @objc func dropPin(sender: UITapGestureRecognizer) {
        //Remove all pins before adding the new one
        removeAllPins()
        //Remove all spinners and progress label before adding the new one
        removeSpinner()
        removeProgressLabel()
        //Cancel all sessions in case images are currently downloading
        FlickrService.instance.cancelAllSessions()
        //Clear images array before new request
        FlickrService.instance.clearImagesArray()
        //Reload tableview to remove previous images
        self.collectionView?.reloadData()
        
        
        //get touch point (x,y) from gesture recognizer
        let touchPoint = sender.location(in: mapView)
        //Convert point to coordinate (lat,lng)
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        //Create a new pin and add it to mapview
        let annotation = DroppablePin(coordinate: touchCoordinate, identifier: "droppablePin")
        mapView.addAnnotation(annotation)
        
        //Create a new coordinate region to center map on the pin
        let coordinateRegion = MKCoordinateRegion.init(center: touchCoordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
        
        animateViewUp()
        addSpinner()
        addProgressLabel()
        
        //Retrieves images urls trhough flickr API
        FlickrService.instance.retrieveUrls(forAnnotation: annotation) { (success) in
            //Got all urls now retrieve each image
            if success {
                //Retrieve images
                FlickrService.instance.retrieveImages(sender: self) { (success) in
                    if success {
                        //Got all images
                        self.removeSpinner()
                        self.removeProgressLabel()
                        //Reload collection view
                        self.collectionView?.reloadData()
                    }
                }
           }
        }
    }
    
    func removeAllPins() {
        mapView.removeAnnotations(mapView.annotations)
    }
}

extension MapVC: CLLocationManagerDelegate {
    func configureLocationServices(){
        if authStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        } else {
            return
        }
    }
    
    //Authorization changes
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        centerMapOnUserLocation()
    }
}

extension MapVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return FlickrService.instance.imageArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? PhotoCell else { return UICollectionViewCell() }
        let imageView = UIImageView(image: FlickrService.instance.imageArray[indexPath.row])
        cell.addSubview(imageView)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "PopVC") as? PopVC else { return }
        popVC.initData(forImage: FlickrService.instance.imageArray[indexPath.row])
        present(popVC, animated: true, completion: nil)
    }
}
