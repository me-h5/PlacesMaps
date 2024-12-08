//
//  ViewController.swift
//  Places to Eat & Drink on Campus
//
//

import UIKit
import MapKit
import CoreData

class ViewController: UIViewController {
//MARK: - Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableViewBackgroundView: UIView!
    @IBOutlet weak var placesTableView: UITableView!
//MARK: - Actions
    @IBAction func didTapOutsidePlacesView(_ sender: Any) {
        self.tableViewBackgroundView.isHidden = true
        sortPlaces()
    }
    @IBAction func didTapShowNearByPlaces(_ sender: Any) {
        self.tableViewBackgroundView.isHidden = false
        sortPlaces()
    }
    //MARK: - Variable
    var venues: [Venue] = []
    var managedContext: NSManagedObjectContext!
    var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        managedContext = appDelegate.persistentContainer.viewContext
        setupLocationManager()
        setupMap()
        setupTableView()
        fetchVenueData()
    }

}
//MARK: - Class Methods
extension ViewController {
    func setViews() {
        self.navigationItem.backButtonTitle = ""
    }
    func setupMap() {
        mapView.delegate = self
        let initialLocation = CLLocationCoordinate2D(latitude: 53.4066, longitude: -2.9667) // Ashton Building
        let region = MKCoordinateRegion(center: initialLocation, latitudinalMeters: 500, longitudinalMeters: 500)
        mapView.showsUserLocation = true
        mapView.setRegion(region, animated: true)
    }
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    func centerMapOnUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: location, latitudinalMeters: 500, longitudinalMeters: 500)
            mapView.setRegion(region, animated: true)
        }
    }
    func addAnnotations() {
        for venue in venues {
            let annotation = VenueAnnotation() // Custom subclass
            annotation.title = venue.name
            annotation.venue = venue
            if let latitude = Double(venue.lat), let longitude = Double(venue.lon) {
                annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }
            mapView.addAnnotation(annotation)
        }
    }
    func sortPlaces() {
        guard let currentLocation = locationManager.location else { return }
        venues.sort { (venue1, venue2) -> Bool in
            guard
                let lat1 = Double(venue1.lat), let lon1 = Double(venue1.lon),
                let lat2 = Double(venue2.lat), let lon2 = Double(venue2.lon)
            else {
                return false // If either of the venue coordinates are invalid, they won't affect the sorting order.
            }
            
            let location1 = CLLocation(latitude: lat1, longitude: lon1)
            let location2 = CLLocation(latitude: lat2, longitude: lon2)
            
            // Compare distances
            return currentLocation.distance(from: location1) < currentLocation.distance(from: location2)
        }
    }
    func setupTableView() {
        placesTableView.delegate = self
        placesTableView.dataSource = self
        placesTableView.register(UINib(nibName: "VenueTableViewCell", bundle: nil), forCellReuseIdentifier: "VenueTableViewCell")
    }
    func fetchVenueData() {
        let urlString = "https://cgi.csc.liv.ac.uk/~phil/Teaching/COMP228/eating_venues/data.json"
        guard let url = URL(string: urlString) else {
            fetchFromCoreData()
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Error fetching data: \(error)")
                self.fetchFromCoreData()
                return
            }

            guard let data = data else { return }
            do {
                let decodedData = try JSONDecoder().decode(VenueResponse.self, from: data)
                DispatchQueue.main.async {
                    let venuesFromCoreData = self.fetchCoreDataVenues()
                    // Replace the decoded data into self.venues
                    self.venues = decodedData.food_venues.map { apiVenue in
                        var updatedVenue = apiVenue
                        if let matchingEntity = venuesFromCoreData.first(where: { $0.name == apiVenue.name }) {
                            updatedVenue.isLiked = matchingEntity.isLiked
                        }
                        return updatedVenue
                    }
                    self.saveToCoreData()
                    self.sortPlaces()
                    self.placesTableView.reloadData()
                    self.addAnnotations()
                }
            } catch {
                print("Error decoding JSON: \(error)")
            }
        }.resume()
    }

    func saveToCoreData() {
        for venue in venues {
            let fetchRequest: NSFetchRequest<VenueEntity> = VenueEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "name == %@", venue.name)

            if let results = try? managedContext.fetch(fetchRequest), let entity = results.first {
                entity.update(from: venue)
            } else {
                let entity = VenueEntity(context: managedContext)
                entity.update(from: venue)
            }
        }
        try? managedContext.save()
    }
    func fetchFromCoreData() {
        let fetchRequest: NSFetchRequest<VenueEntity> = VenueEntity.fetchRequest()
        if let results = try? managedContext.fetch(fetchRequest) {
            self.venues = results.map { Venue(from: $0) }
        }
    }
    func fetchCoreDataVenues() -> [VenueEntity] {
        let fetchRequest: NSFetchRequest<VenueEntity> = VenueEntity.fetchRequest()
        do {
            return try managedContext.fetch(fetchRequest)
        } catch {
            print("Error fetching Core Data: \(error)")
            return []
        }
    }
    @objc func didTapLike(sender : UIButton){
        let index = sender.tag
        venues[index].isLiked.toggle()
        saveToCoreData()
        placesTableView.reloadData()
    }
}
//MARK: - TableView Delegate and Datasource Methods
extension ViewController : UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return venues.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let venueCell = tableView.dequeueReusableCell(withIdentifier: "VenueTableViewCell", for: indexPath) as? VenueTableViewCell else { return UITableViewCell() }
        venueCell.locationNameLabel.text = venues[indexPath.row].name
        venueCell.likeButton.tag = indexPath.row
        venueCell.likeButton.setImage(venues[indexPath.row].isLiked ? UIImage(systemName: "heart.fill") : UIImage(systemName: "heart"), for: .normal)
        venueCell.likeButton.addTarget(self, action: #selector(didTapLike(sender:)), for: .touchUpInside)
        return venueCell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "VenueDetailsViewController") as? VenueDetailsViewController else { return }
        vc.venue = venues[indexPath.row]
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
//MARK: - MapKit Delegate Methods
extension ViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let venueAnnotation = view.annotation as? VenueAnnotation,
              let venue = venueAnnotation.venue else { return }
        
        // Navigate to VenueDetailsViewController
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "VenueDetailsViewController") as? VenueDetailsViewController else { return }
        vc.venue = venue
        navigationController?.pushViewController(vc, animated: true)
    }
}
//MARK: - Location Manager Delegate Methods
extension ViewController : CLLocationManagerDelegate {
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let userLocation = locations.first {
            let region = MKCoordinateRegion(center: userLocation.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        }else if status == .authorizedAlways{
            locationManager.startUpdatingLocation()
        } else {
            print("Location access denied.")
        }
    }
}
