//
//  VenueTableViewCell.swift
//  Places to Eat & Drink on Campus
//
//

import UIKit

class VenueTableViewCell: UITableViewCell {

    @IBOutlet weak var locationNameLabel: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
