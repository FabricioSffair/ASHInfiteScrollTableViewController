//
//  ViewController.swift
//  Example
//
//  Created by Gustavo B Tagliari on 09/03/17.
//  Copyright © 2017 AIORIA SOFTWARE HOUSE. All rights reserved.
//

import UIKit

class ViewController: LoadMoreTableViewController {

    // MARK: - Models
    var models = [String]() {
        didSet {
            debugPrint("newModels: \(models)")
        }
    }

    // MARK: - UITableViewDataSource
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = models[indexPath.row]
        return cell
    }
}

// MARK: - LoadMoreDelegate
extension ViewController {
    override var records: [Any] {
        get {
            return self.models
        }
        set {
            if let models = newValue as? [String] {
                self.models = models
            }
        }
    }
    
    override func fetchDataFromWS(withOffset offset: Int, andLimit limit: Int, completionBlock completion: @escaping ([Any]?, Error?) -> Void) {
        
        var strings = [String]()
        
        for i in offset ..< (offset+limit) {
            strings.append("Line \(i)")
        }
        
        completion(strings, nil)
    }
}
