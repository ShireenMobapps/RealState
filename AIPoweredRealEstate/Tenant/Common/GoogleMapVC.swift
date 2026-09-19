//
//  GoogleMapVC.swift
//  AIPoweredRealEstate
//

import UIKit
import CoreLocation
import GoogleMaps

class GoogleMapVC: UIViewController {

    @IBOutlet weak var mainView: UIView!

    var map = GMSMapView()
    var lat: Double = 0.0
    var long: Double = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        LocationManager.shared.updatedLocation = { [weak self] location in
            guard let self else { return }
            self.lat = location.coordinate.latitude
            self.long = location.coordinate.longitude
            self.setMap(location: location)
            drawRoute(
                source: CLLocationCoordinate2D(
                    latitude: 12.971599,
                    longitude: 77.594566
                ),
                destination: CLLocationCoordinate2D(
                    latitude: 12.971389,
                    longitude: 77.750130
                )
            )
        }
        LocationManager.shared.checkAuthorizationSts()
        
    }

    func setMap(location: CLLocation) {
       
        guard mainView != nil else { return }

        let camera = GMSCameraPosition(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            zoom: 15
        )
        
        let option = GMSMapViewOptions()
        
        option.camera = camera

        map.removeFromSuperview()
        map = GMSMapView(options: option)
        map.frame = mainView.bounds
        map.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mainView.addSubview(map)

        setMarker(location: location)
        
    }

    func setMarker(location: CLLocation) {
        let marker = GMSMarker()
        marker.position = location.coordinate
        marker.title = "Current Location"
        LocationManager.shared.getFullAddress(location: location) { fullAddress in
            marker.snippet = fullAddress
        }
        marker.icon = UIImage(systemName: "location.fill")
        marker.map = map
    }
    
    func drawRoute(source:CLLocationCoordinate2D,destination:CLLocationCoordinate2D){
        
        let api = "https://maps.googleapis.com/maps/api/directions/json?origin=\(source.latitude),\(source.longitude)&destination=\(destination.latitude),\(destination.longitude)&key=\(Constant.googleMapsAPIKey)"
        
        guard let url = URL(string: api) else { return  }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error{
                print("error is : \(error.localizedDescription)")
                return
            }
           
            guard let data = data else{return}
          
            do{
                let json = try JSONSerialization.jsonObject(with: data) as! [String:Any]
                
                let sts = json["status"] as! String
                
                guard sts == "OK" else{
                    print("error message is: \(json["error_message"] as! String)")
                    return
                }
                
                guard
                    let routes = json["routes"] as? [[String: Any]],
                    let firstRoute = routes.first,
                    let overviewPolyline = firstRoute["overview_polyline"] as? [String: Any],
                    let encodedPolyline = overviewPolyline["points"] as? String
                else {
                    print("Polyline not found")
                    return
                }
               
                DispatchQueue.main.async {
                    guard let path = GMSPath(fromEncodedPath: encodedPolyline) else{return}
                    
                    let polyline = GMSPolyline(path: path)
                    polyline.strokeWidth = 5
                    polyline.strokeColor = .blue
                    polyline.map = self.map
                    
                    let bounds = GMSCoordinateBounds(path: path)
                    let camera = self.map.camera(for: bounds, insets: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50))
                    
                    if let camera = camera{
                        self.map.animate(to: camera)
                    }
                    
                }
            }
            catch{
                return
            }
            
        }
        
    }
    
    
    
    
}


