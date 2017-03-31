//
//  LoadMoreCollectionViewController.swift
//  Joinday
//
//  Created by Gustavo B Tagliari on 31/03/17.
//  Copyright © 2017 AIORIA SOFTWARE HOUSE. All rights reserved.
//

import UIKit

class LoadMoreCollectionViewController: UICollectionViewController {

    // MARK: - IBOutlets
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
    
    var nroChamadas = 0 {
        didSet {
            #if DEBUG
                debugPrint("LoadMoreTableViewController.nroChamadas = \(nroChamadas)")
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
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        self.collectionView?.addSubview(rc)
        
        self.refreshControl = rc
    }

    // MARK: - UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.records.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // TODO: create an delegate method and call it here!
        fatalError("a subclasse precisa fazer override deste método")
    }
    
    // MARK: - UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
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
                    self.collectionView?.reloadData()
                    
                } else {
                    
                    var indexes = [Int]()
                    for record in newResults {
                        records.append(record)
                        indexes.append(records.count - 1)
                    }
                    self.records = records
                    #if DEBUG
                        debugPrint("LoadMoreTableViewController.loadMore.fetchData.insertRows: \(indexes)")
                    #endif
                    self.collectionView?.insertItems(at: indexes.map { IndexPath(row: $0, section: 0)})
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
                self.nroChamadas = 1
            } else {
                offset = self.offset
                self.nroChamadas += 1
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
        let footer = UINib(nibName: self.footerXibName, bundle: nil)
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
//        self.tableView?.tableFooterView = footer
    }
    
    func showFooterNoItems() {
        #if DEBUG
            debugPrint("LoadMoreTableViewController.showFooterNoItems()")
        #endif
        
        let footer = self.loadFooter()
        footer.state = .noMore
//        self.tableView?.tableFooterView = footer
    }
    
    func hideFooter() {
        #if DEBUG
            debugPrint("LoadMoreTableViewController.hideFooter()")
        #endif
        
//        self.tableView?.tableFooterView = nil
    }
}

extension LoadMoreCollectionViewController: LoadMoreDelegate {
    var limit: Int {
        return (3 * 5)
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
    
    var footerXibName : String {
        return "LoadFooterView"
    }
    
    
    func fetchDataFromWS(withOffset offset: Int, andLimit limit: Int, completionBlock completion: @escaping ([Any]?, Error?) -> Void) {
        // TODO: create an custom error
        completion(nil, nil)
    }

}
