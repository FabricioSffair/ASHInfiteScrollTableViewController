//
//  LoadMoreTableViewController.swift
//  FolloU
//
//  Created by Gustavo B Tagliari on 22/02/17.
//  Copyright © 2017 Aioria. All rights reserved.
//

import UIKit

protocol LoadMoreDelegate {
    var records: [Any] { get set }
    
    var limit: Int { get }
    
    var noResultsTitle: String { get }
    
    var loadingMoreTitle: String { get }
    
    func fetchDataFromWS(withOffset offset: Int, andLimit limit: Int, completionBlock completion: @escaping ([Any]?, Error?) -> Void)
}


@IBDesignable
class LoadMoreTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView? {
        didSet {
            tableView?.delegate = self
            tableView?.dataSource = self
        }
    }
    
    @IBOutlet weak var refreshControl: UIRefreshControl?
    
    // MARK: - IBActions
    @IBAction func refresh(_ sender: UIRefreshControl?) {
        self.loadMore(true, with: sender)
    }
    
    // MARK: - vars
    @IBInspectable var primaryColor: UIColor?
    
    var heightAtIndexPath = [(Int, CGFloat)]()
    
    var loadingMore = false {
        didSet {
            #if DEBUG
                debugPrint("LoadMoreTableViewController.loadingMore = \(loadingMore)")
            #endif
            
            if loadingMore {
                if self.refreshControl?.isRefreshing == true {
                    hideFooter()
                } else {
                    showFooterLoadingMore()
                }
            } else {
                if self.records.count == 0 {
                    showFooterNoItems()
                } else {
                    hideFooter()
                }
            }
        }
    }
    
    var isViewAppearing = false {
        didSet {
            #if DEBUG
                debugPrint("LoadMoreTableViewController.isViewAppearing = \(isViewAppearing)")
            #endif
        }
    }
    
    var hasMore = true {
        didSet {
            #if DEBUG
                debugPrint("LoadMoreTableViewController.hasMore = \(hasMore)")
            #endif
        }
    }
    
    var repetidos = 0 {
        didSet {
            #if DEBUG
                debugPrint("LoadMoreTableViewController.repetidos = \(repetidos)")
            #endif
        }
    }
    
    // MARK: - View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createRefreshControl()
        
        self.loadMore(true, with: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.isViewAppearing = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.isViewAppearing = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let primaryColor = self.primaryColor {
            self.refreshControl?.tintColor = primaryColor
        }
    }
    
    // MARK: - Layout Methods
    func createRefreshControl() {
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        self.tableView.addSubview(self.refreshControl!)
    }
    
    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.records.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // TODO: create an delegate method and call it here!
        fatalError("a subclasse precisa fazer override deste método")
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        updateCachedSizeForHeight(row: indexPath.row, with: cell.frame.size.height)
        
        guard self.isViewAppearing && !self.loadingMore && self.hasMore else {
            return
        }
        
        let index = indexPath.row
        
        
        if index >= indexToLoadMore && indexToLoadMore > 0 {
            #if DEBUG
                debugPrint("LoadMoreTableViewController.willDisplayCell: indexToLoadMore=\(indexToLoadMore) index=\(index)")
            #endif
            self.loadMore()
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if let height = cachedHeightForRow(row: indexPath.row) {
            return height
        } else {
            return UITableViewAutomaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    // MARK: - WS Methods
    func loadMore(_ clear: Bool = false, with refreshControl: UIRefreshControl? = nil) {
        self.loadMore(clear, with: refreshControl) {
            newResults, error in
            if let newResults = newResults {
                var records = self.records
                if clear {
                    self.heightAtIndexPath.removeAll()
                    records.removeAll()
                    records.append(contentsOf: newResults)
                    self.records = records
                    self.tableView?.reloadData()
                } else {
                    self.tableView?.beginUpdates()
                    var indexes = [Int]()
                    for record in newResults {
                        records.append(record)
                        indexes.append(records.count - 1)
                    }
                    self.records = records
                    #if DEBUG
                        debugPrint("LoadMoreTableViewController.loadMore.fetchData.insertRows: \(indexes)")
                    #endif
                    self.tableView?.insertRows(at: indexes.map { IndexPath(row: $0, section: 0)}, with: .automatic)
                    self.tableView?.endUpdates()
                }
                
                self.hasMore = newResults.count != 0
                let diff = (self.limit - newResults.count)
                
                if diff > 0 {
                    self.repetidos += diff
                }
                
            } else {
                self.hasMore = true
                #if DEBUG
                    debugPrint("LoadMoreTableViewController.loadMore.fetchData.error: \(error)")
                #endif
            }
            
            self.loadingMore = false
            
            if refreshControl?.isRefreshing == true {
                refreshControl?.endRefreshing()
            }
        }
    }
    
    func loadMore(_ clear: Bool = false, with refreshControl: UIRefreshControl? = nil, completionBlock completion: @escaping ([Any]?, Error?) -> Void) {
        if self.loadingMore == false {
            self.loadingMore = true
            
            var offset = 0
            
            if clear {
                repetidos = 0
            } else {
                offset = self.offset
            }
            
            offset += repetidos
            
            #if DEBUG
                debugPrint("LoadMoreTableViewController.fetchDataFromWS(withOffset: \(offset), andLimit: \(limit))")
            #endif
            
            self.fetchDataFromWS(withOffset: offset, andLimit: limit) {
                newResults, error in
                completion(newResults, error)
            }
        } else {
            if refreshControl?.isRefreshing == true {
                refreshControl?.endRefreshing()
            }
        }
    }
    
    // MARK: - Footer methods
    func loadFooter() -> LoadFooterView {
        let footer = UINib(nibName: "LoadFooterView", bundle: nil)
            .instantiate(withOwner: self, options: nil)[0] as! LoadFooterView
        
        footer.noMoreResultsTitle = self.noResultsTitle
        footer.loadingResultsTitle = self.loadingMoreTitle
        
        return footer
    }
    
    func showFooterLoadingMore() {
        #if DEBUG
            debugPrint("LoadMoreTableViewController.showFooterLoadingMore()")
        #endif
        
        let footer = self.loadFooter()
        footer.state = .loading
        self.tableView?.tableFooterView = footer
    }
    
    func showFooterNoItems() {
        #if DEBUG
            debugPrint("LoadMoreTableViewController.showFooterNoItems()")
        #endif
        
        let footer = self.loadFooter()
        footer.state = .noMore
        self.tableView?.tableFooterView = footer
    }
    
    func hideFooter() {
        #if DEBUG
            debugPrint("LoadMoreTableViewController.hideFooter()")
        #endif
        
        self.tableView?.tableFooterView = nil
    }
    
    // MARK: - cache
    func cachedHeightForRow(row: Int) -> CGFloat? {
        for (key, height) in self.heightAtIndexPath {
            if key == row {
                return height
            }
        }
        return nil
    }
    
    func updateCachedSizeForHeight(row: Int, with height: CGFloat? = nil) {
        let index = heightAtIndexPath.index {
            (k, h) in
            return k == row
        }
        
        if let index = index {
            self.heightAtIndexPath.remove(at: index)
        }
        
        if let height = height {
            let cache = (row, height)
            self.heightAtIndexPath.append(cache)
        }
    }
}

extension LoadMoreTableViewController: LoadMoreDelegate {
    var limit: Int {
        return 8
    }
    
    var records: [Any] {
        get {
            return [Any]()
        }
        set {
            
        }
    }
    
    var offset: Int {
        return self.records.count
    }
    
    var indexToLoadMore: Int {
        return self.records.count - Int(round(Double(self.limit) / 2.0))
    }
    
    var noResultsTitle: String {
        return "Não há itens"
    }
    
    var loadingMoreTitle: String {
        return "Carregando..."
    }
    
    func fetchDataFromWS(withOffset offset: Int, andLimit limit: Int, completionBlock completion: @escaping ([Any]?, Error?) -> Void) {
        // TODO: create an custom error
        completion(nil, nil)
    }
    
}
