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
            
            pageControl.numberOfPages = pageImages.count
            pageControl.currentPage = 0
        }
    }
    private var screenWidth:CGFloat = 0
    
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
        self.screenWidth = CGRectGetWidth(self.view.bounds)
        
        self.scrollView.contentSize = CGSizeMake(self.screenWidth * CGFloat(count), CGRectGetHeight(self.scrollView.frame))
        
        for _ in 1...count {
            self.pageViews.append(nil)
        }
        
        self.scrollView.backgroundColor = UIColor.redColor()
        
        loadVisiblePages()
        
    }
    
    @IBAction func handlePagePressed(item:UIPageControl) {
        
        let index = item.currentPage
        
        self.scrollView.contentOffset = CGPointMake(self.screenWidth * CGFloat(index), 0.0)
        
        loadVisiblePages()
    }
    
    private func setCurrentPage(page:Int) {
        pageControl.currentPage = page
        
        self.textView?.text = pageDescriptions[page]
        
    }
    
    func loadVisiblePages() {
        
        // First, determine which page is currently visible
        let pageWidth = self.screenWidth
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
            var frame = CGRectZero
            frame.size = self.scrollView.frame.size
            frame.origin.x = self.screenWidth * CGFloat(page)
            frame.origin.y = 0.0
            
            let newPageView = UIImageView(image: pageImages[page])
            
            let size = newPageView.image!.size
            var scale:CGFloat
            let scrollSize = self.scrollView.frame.size
            
            
            if (self.traitCollection.userInterfaceIdiom == .Phone)
            {
                // 3
                let ratio = size.height/size.width
                
                let scrollRatio = scrollSize.height/scrollSize.width
                
                let xScale = scrollSize.width/size.width
                let yScale = scrollSize.height/size.height
                
                scale = min(xScale,yScale)
                
                newPageView.contentMode = .ScaleAspectFit
            }
            else {
                newPageView.contentMode = .Center
                scale = 1.0
            }
            
            let newSize = CGSizeMake(size.width * scale, size.height * scale)
            
            println("Original image size \(size)\nNew image size \(newSize)\nScroll View frame \(self.scrollView.frame)")
            
            var xMargin = 0.5 * (scrollSize.width - newSize.width)
            var yMargin = 0.5 * (scrollSize.height - newSize.height)
            
            if xMargin < 0 {
                xMargin  = 0
            }
            
            if yMargin < 0 {
                yMargin  = 0
            }
            
            frame.origin.x += xMargin
            frame.origin.y += yMargin
            
            println("Frame \(frame), \nX margin \(xMargin)\n Y margin \(yMargin)")
            
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
