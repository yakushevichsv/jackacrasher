//
//  HelpViewController.swift
//  JackACrasher
//
//  Created by Siarhei Yakushevich on 8/23/15.
//  Copyright (c) 2015 Siarhei Yakushevich. All rights reserved.
//

import UIKit

class HelpViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var textView:UITextView!
    @IBOutlet weak var scrollView:UIScrollView!
    @IBOutlet weak var pageControl:UIPageControl! {
        didSet {
            pageControl.addTarget(self, action: "handlePagePressed:", forControlEvents: UIControlEvents.TouchUpInside)
            
            pageControl.numberOfPages = pageImages.count
            pageControl.currentPage = 0
        }
    }
    
    var pageViews: [UIImageView?] = []
    var pageImages: [UIImage] = [] {
        didSet {
            pageControl?.numberOfPages = pageImages.count
            pageControl?.currentPage = 0
        }
    }
    
    var pageDescriptions: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let count = pageImages.count
        let w = CGRectGetWidth(self.view.bounds)
        
        self.scrollView.contentSize = CGSizeMake(w * CGFloat(count), CGRectGetHeight(self.view.bounds))
        
        for _ in 1...count {
            self.pageViews.append(nil)
        }
        
        loadVisiblePages()
        
        setCurrentPage(0)
        
    }
    
    func handlePagePressed(item:AnyObject) {
        
        let index = pageControl.currentPage
        let w = CGRectGetWidth(self.view.bounds)
        
        self.scrollView.contentOffset = CGPointMake(w * CGFloat(index), 0.0)
        
        loadVisiblePages()
    }
    
    private func setCurrentPage(page:Int) {
        pageControl.currentPage = page
        
        self.textView?.text = pageDescriptions[page]
        
    }
    
    func loadVisiblePages() {
        
        // First, determine which page is currently visible
        let pageWidth = CGRectGetWidth(self.view.bounds)
        let page = Int(floor((scrollView.contentOffset.x * 2.0 + pageWidth) / (pageWidth * 2.0)))
        
        // Update the page control
        setCurrentPage(page)
        
        // Work out which pages you want to load
        let firstPage = page - 1
        let lastPage = page + 1
        
        
        // Purge anything before the first page
        for var index = 0; index < firstPage; ++index {
            purgePage(index)
        }
        
        // Load pages in our range
        for var index = firstPage; index <= lastPage; ++index {
            loadPage(index)
        }
        
        // Purge anything after the last page
        for var index = lastPage+1; index < pageControl.numberOfPages; ++index {
            purgePage(index)
        }
    }
    
    
    func purgePage(page: Int) {
        
        if page < 0 || page >= pageControl.numberOfPages {
            // If it's outside the range of what you have to display, then do nothing
            return
        }
        
        // Remove a page from the scroll view and reset the container array
        if let pageView = pageViews[page] {
            pageView.removeFromSuperview()
            pageViews[page] = nil
        }
        
    }
    
    func loadPage(page: Int) {
        
        if page < 0 || page >= pageControl.numberOfPages  {
            // If it's outside the range of what you have to display, then do nothing
            return
        }
        
        // 1
        if let pageView = pageViews[page] {
            // Do nothing. The view is already loaded.
        } else {
            // 2
            var frame = self.scrollView.bounds
            frame.origin.x = frame.size.width * CGFloat(page)
            frame.origin.y = 0.0
            
            // 3
            let newPageView = UIImageView(image: pageImages[page])
            newPageView.contentMode = .ScaleAspectFit
            newPageView.frame = frame
            scrollView.addSubview(newPageView)
            
            // 4
            pageViews[page] = newPageView
        }
    }

    //MARK: Scroll View Delegate
    func scrollViewDidScroll(scrollView: UIScrollView) {
        // Load the pages that are now on screen
        loadVisiblePages()
    }
}
