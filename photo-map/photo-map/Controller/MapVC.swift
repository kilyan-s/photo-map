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


class MapVC: UIViewController {
    //Outlets
    @IBOutlet weak var mapView: MKMapView!
    
    //Variables
    var locationManager = CLLocationManager()
    let authStatus = CLLocationManager.authorizationStatus()
    let regionRadius: Double = 1000
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        
        configureLocationServices()
    }

    //Actions
    @IBAction func centerMapBtnPressed(_ sender: Any) {
        if authStatus == .authorizedAlways || authStatus == .authorizedWhenInUse {
            centerMapOnUserLocation()
        }
    }
    
}

extension MapVC: MKMapViewDelegate {
    func centerMapOnUserLocation() {
        //Get user coordinate
        guard let userCoordinate = locationManager.location?.coordinate else { return }
        //Create a region center on user location and span of var regionDelta
        let coordinateRegion = MKCoordinateRegion.init(center: userCoordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        //Center map on region
        mapView.setRegion(coordinateRegion, animated: true)
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
