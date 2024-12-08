//
//  VenueModel.swift
//  Places to Eat & Drink on Campus
//
//

import Foundation
struct VenueResponse: Codable {
    let food_venues: [Venue]
}
struct Venue: Codable {
    let name: String
    let building: String
    let lat: String
    let lon: String
    let description: String
    let openingTimes: [String]
    let amenities: [String]
    let photos: [String]
    let url: String
    let lastModified: String
    var isLiked: Bool = false // Default to false

    enum CodingKeys: String, CodingKey {
        case name
        case building
        case lat
        case lon
        case description
        case openingTimes = "opening_times"
        case amenities
        case photos
        case url = "URL"
        case lastModified = "last_modified"
    }
}

extension Venue {
    /// Update the `isLiked` property based on a Core Data entity
    mutating func updateIsLiked(using coreDataVenues: [VenueEntity]) {
        if let matchingEntity = coreDataVenues.first(where: { $0.name == self.name }) {
            self.isLiked = matchingEntity.isLiked
        }
    }
}

extension Venue {
    init(from entity: VenueEntity) {
        self.name = entity.name ?? ""
        self.building = entity.building ?? ""
        self.lat = entity.lat ?? ""
        self.lon = entity.lon ?? ""
        self.description = entity.desp ?? ""
        
        // Decode Data to [String] with fallback to an empty array
        self.openingTimes = (try? JSONDecoder().decode([String].self, from: (entity.openingTimes ?? "").data(using: .utf8) ?? Data())) ?? []
        self.amenities = (try? JSONDecoder().decode([String].self, from: (entity.amenities ?? "").data(using: .utf8) ?? Data())) ?? []
        self.photos = (try? JSONDecoder().decode([String].self, from: (entity.photos ?? "").data(using: .utf8) ?? Data())) ?? []
        
        self.url = entity.url ?? ""
        self.lastModified = entity.lastModified ?? ""
        self.isLiked = entity.isLiked // Fetch isLiked from Core Data
    }
}

extension VenueEntity {
    func update(from venue: Venue) {
        self.name = venue.name
        self.building = venue.building
        self.lat = venue.lat
        self.lon = venue.lon
        self.desp = venue.description
        
        // Encode [String] to Data with explicit type
        if let encodedData = try? JSONEncoder().encode(venue.openingTimes),
           let jsonString = String(data: encodedData, encoding: .utf8) {
            self.openingTimes = jsonString
        } else {
            print("Failed to encode and convert opening times to string.")
        }
        if let encodedData = try? JSONEncoder().encode(venue.amenities),
           let jsonString = String(data: encodedData, encoding: .utf8) {
            self.amenities = jsonString
        } else {
            print("Failed to encode and convert amenities to string.")
        }
        if let encodedData = try? JSONEncoder().encode(venue.photos),
           let jsonString = String(data: encodedData, encoding: .utf8) {
            self.photos = jsonString
        } else {
            print("Failed to encode and convert photos to string.")
        }
        
        self.url = venue.url
        self.lastModified = venue.lastModified
        self.isLiked = venue.isLiked // Update isLiked to Core Data
    }
}
