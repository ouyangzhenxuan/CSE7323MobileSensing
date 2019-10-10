//
//  TodayTableViewCell.swift
//  MotionLab3
//
//  Created by Zhenxuan Ouyang on 10/10/19.
//  Copyright © 2019 梅沈潇. All rights reserved.
//

import UIKit

class TodayTableViewCell: UITableViewCell {

    @IBOutlet weak var todayStep: UILabel!
    @IBOutlet weak var todayImage: UIImageView!
    @IBOutlet weak var motionState: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
