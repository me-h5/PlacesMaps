//
//  VenueDetailsViewController.swift
//  Places to Eat & Drink on Campus
//
//

import UIKit
import MapKit

class VenueDetailsViewController: UIViewController {
//MARK: - Outlets
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var buildingNameLabel: UILabel!
    @IBOutlet weak var locationMapView: MKMapView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var amenitiesLabel: UILabel!
    @IBOutlet weak var openingHoursLabel: UILabel!
//MARK: - Variables
    var venue : Venue!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
}
//MARK: - Class methods
extension VenueDetailsViewController{
    func setupView() {
        self.title = "Place Details"
        nameLabel.text = venue.name
        buildingNameLabel.text = venue.building
        descriptionLabel.text = venue.description
        let (openingTimesString, amenitiesString) = convertToMultilineString(openingTimes: venue.openingTimes, amenities: venue.amenities)
        amenitiesLabel.text = amenitiesString
        openingHoursLabel.text = openingTimesString
        setMapView()
    }
    func setMapView() {
        let annotation = MKPointAnnotation()
        annotation.title = venue.name
        if let latitude = Double(venue.lat), let longitude = Double(venue.lon) {
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            annotation.coordinate = coordinate
            let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
            locationMapView.setRegion(region, animated: true)
            print("Venue Location: \(coordinate)")
        }
        locationMapView.addAnnotation(annotation)
    }
    func convertToMultilineString(openingTimes: [String], amenities: [String]) -> (String, String) {
        let openingTimesString = openingTimes.joined(separator: "\n")
        let amenitiesString = amenities.joined(separator: "\n")
        return (openingTimesString, amenitiesString)
    }
}
