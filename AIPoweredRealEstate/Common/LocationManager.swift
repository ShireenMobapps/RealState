//
//  LocationManager.swift
//  AIPoweredRealEstate
//
//  Created by Shireen on 18/08/26.
//

import Foundation
import CoreLocation

class LocationManager:NSObject, CLLocationManagerDelegate{
    
    static let shared = LocationManager()
   
    let locationManager = CLLocationManager()
    
    var updatedLocation:((CLLocation)->Void)?
    
    private override init(){
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func checkAuthorizationSts(){
       
        let sts = locationManager.authorizationStatus
       
        switch sts{
            
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        
        case .restricted,.denied:
            print("Location permission denied/restricted")
        
        case .authorizedAlways,.authorizedWhenInUse:
            locationManager.startUpdatingLocation()
       
        @unknown default: break
            
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkAuthorizationSts()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
       
        if let location = locations.first{
            updatedLocation?(location)
        }
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        print(error.localizedDescription)
    }
    
    func getFullAddress(location:CLLocation,completion:@escaping (String)->()){
        
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { placemarker, error in
           
            guard error == nil ,let placeMarker = placemarker?.first,let place = placemarker?.first else{
                completion("")
                return
            }
            
            let name = place.name
            let city = place.locality
            let state = place.administrativeArea
            let country = place.country
            let postalcode = place.postalCode
            let address = [name,city,state,country,postalcode].compactMap({$0}).joined(separator: ",")
            
            completion(address)
        }
    }
    
    
}
