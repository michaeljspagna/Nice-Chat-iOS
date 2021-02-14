//
//  ChatroomTableViewCell.swift
//  Nice-Chat
//
//  Created by Michael Spagna on 2/6/21.
//

import UIKit

class ChatroomTableViewCell: UITableViewCell {
    
    static let identifier = "ChatroomTableViewCell"
    
    
    
    private let chatroomNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .semibold)
        return label
    }()
    
    private let chatroomBatterReqLabel: UILabel = {
       let label = UILabel()
        label.font = .systemFont(ofSize: 19, weight: .regular)
        return label
    }()

    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(chatroomNameLabel)
        contentView.addSubview(chatroomBatterReqLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        chatroomNameLabel.frame = CGRect(x: 10,
                                         y: 10,
                                         width: contentView.width,
                                         height: (contentView.height - 20) / 2)
        
        chatroomBatterReqLabel.frame = CGRect(x: 10,
                                              y: chatroomNameLabel.bottom + 2,
                                              width: contentView.width,
                                              height: (contentView.height - 20) / 2)
        
    }
    
    public func configure(with model: Chatroom){
        self.chatroomNameLabel.text = model.name
        self.chatroomBatterReqLabel.text = model.message
    }
}
