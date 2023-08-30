//
//  BookmarkTableViewCell.swift
//  EverySearch
//
//  Created by 김하늘 on 2021/06/01.
//

import UIKit

final class BookmarkTableViewCell: UITableViewCell {

    @IBOutlet weak var teamTitleLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var numberLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
}
