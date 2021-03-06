//
//  QuoteFloorCell.swift
//  Stage1st
//
//  Created by Zheng Li on 1/20/16.
//  Copyright © 2016 Renaissance. All rights reserved.
//

import SnapKit
import AlamofireImage
import CocoaLumberjack

final class QuoteFloorCell: UITableViewCell {
    let avatarView = UIImageView(image: nil)
    let authorLabel = UILabel(frame: .zero)
    let dateTimeLabel = UILabel(frame: .zero)
    let floorLabel = UILabel(frame: .zero)
    let moreActionButton = UIButton(type: .system)
    let contentLabel = UILabel(frame: .zero)
    var webViewHeightConstraint: Constraint?

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = AppEnvironment.current.colorManager.colorForKey("content.webview.background")

        avatarView.layer.borderColor = AppEnvironment.current.colorManager.colorForKey("hud.border").cgColor
        avatarView.layer.borderWidth = 1.0 / UIScreen.main.scale
        avatarView.layer.cornerRadius = 16.0
        avatarView.clipsToBounds = true
        contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.leading.equalTo(self.contentView.snp.leading).offset(5.0)
            make.top.equalTo(self.contentView.snp.top).offset(5.0)
            make.width.height.equalTo(32.0)
        }

        contentView.addSubview(authorLabel)
        authorLabel.snp.makeConstraints { (make) -> Void in
            make.leading.equalTo(self.avatarView.snp.trailing).offset(5.0)
            make.centerY.equalTo(self.avatarView.snp.centerY)
        }

        contentView.addSubview(dateTimeLabel)
        dateTimeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(self.avatarView.snp.centerY)
            make.leading.equalTo(authorLabel.snp.trailing).offset(10.0)
        }

        moreActionButton.setTitle("更多", for: .normal)
        contentView.addSubview(moreActionButton)
        moreActionButton.snp.makeConstraints { make in
            make.centerY.equalTo(self.avatarView.snp.centerY)
            make.trailing.equalTo(self.contentView.snp.trailing).offset(-10.0)
        }

        contentView.addSubview(floorLabel)
        floorLabel.snp.makeConstraints { make in
            make.centerY.equalTo(self.avatarView.snp.centerY)
            make.trailing.equalTo(self.moreActionButton.snp.leading).offset(-10.0)
        }

        //        contentLabel.layoutFrameHeightIsConstrainedByBounds = false
        contentView.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { (make) -> Void in
            make.leading.trailing.equalTo(contentView)
            make.top.equalTo(self.avatarView.snp.bottom).offset(10.0)
            make.bottom.equalTo(self.contentView.snp.bottom).offset(-5.0)
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
