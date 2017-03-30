//
//  LoadFooterView.swift
//  FolloU
//
//  Created by Gustavo B Tagliari on 22/02/17.
//  Copyright © 2017 Aioria. All rights reserved.
//

import UIKit

enum LoadFooterViewState {
    case noMore
    case loading
    case undefined
}

class LoadFooterView: UITableViewHeaderFooterView {

    @IBOutlet weak var actIndicator: UIActivityIndicatorView!
    @IBOutlet weak var indicatorLabel: UILabel!
    @IBOutlet weak var icon: UIImageView!
    
    var noMoreResultsTitle: String = "Não há itens"
    var loadingResultsTitle: String = "Carregando..."
    
    var state: LoadFooterViewState = .undefined {
        didSet {
            switch state {
            case .noMore:
                self.actIndicator?.stopAnimating()
                self.actIndicator?.isHidden = true
                self.indicatorLabel?.text = noMoreResultsTitle
                break
            case .loading:
                self.actIndicator?.isHidden = false
                self.actIndicator?.startAnimating()
                self.indicatorLabel?.text = loadingResultsTitle
                break
            case .undefined:
                self.actIndicator?.stopAnimating()
                self.actIndicator?.isHidden = true
                self.indicatorLabel?.text = nil
                break
            }
        }
    }
}
