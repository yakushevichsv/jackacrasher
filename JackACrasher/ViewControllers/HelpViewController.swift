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
    @IBOutlet weak var pageControl:UIPageControl!
    
    private var screenWidth:CGFloat = 0
    
    var pageViews: [UIImageView?] = []
    var pageImages: [UIImage] = []
    var pageDescriptions: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.scrollView.showsHorizontalScrollIndicator = true
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.scrollsToTop = false
        self.scrollView.directionalLockEnabled = true
        self.scrollView.bounces = false
        // Do any additional setup after loading the view.
        let count = pageImages.count
        let pagesScrollViewSize = self.view.bounds.size
        self.screenWidth = pagesScrollViewSize.width
        
        self.scrollView.contentSize = CGSizeMake(self.screenWidth * CGFloat(count), pagesScrollViewSize.height)
        
        for _ in 1...count {
            self.pageViews.append(nil)
        }
        
        self.scrollView.backgroundColor = UIColor.blackColor()
        
        
        pageControl.currentPage = 0
        pageControl.numberOfPages = pageImages.count
        
        setCurrentPage(pageControl.currentPage)
        //loadPage(pageControl.currentPage)
        
        correctFontOfChildViews(self.view)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController!.navigationBarHidden = false
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController!.navigationBarHidden = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        loadVisiblePages()
        if pageControl.currentPage == 0 {
            self.scrollView.contentOffset = CGPointZero
        }
    }
    
    @IBAction func handlePagePressed(item:UIPageControl) {
        
        let index = item.currentPage
        
        loadVisiblePages()
        
        var bounds = self.scrollView.bounds
        bounds.origin.x = CGRectGetWidth(bounds) * CGFloat(index)
        bounds.origin.y = 0
        self.scrollView.scrollRectToVisible(bounds,animated:true)
    }
    
    private func setCurrentPage(page:Int) {
        pageControl.currentPage = page
        
        let text = pageDescriptions[page]
        self.textView?.text = text
        print("Current text in Help \(text)")
        
    }
    
    func loadVisiblePages() {
        
        // First, determine which page is currently visible
        let pageWidth = self.screenWidth
        let page = Int(floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1)
        
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
        if pageViews[page] == nil {
            /*var frame = CGRectZero
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
            
            print("Original image size \(size)\nNew image size \(newSize)\nScroll View frame \(self.scrollView.frame)")
            
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
            
            print("Frame \(frame), \nX margin \(xMargin)\n Y margin \(yMargin)")
            
            newPageView.frame = frame
            scrollView.addSubview(newPageView)
            
            // 4
            pageViews[page] = newPageView*/
            
            var frame = self.scrollView.bounds
            frame.origin.x = frame.size.width * CGFloat(page)
            frame.origin.y = 0.0
            
            // 3
            let newPageView = UIImageView(image: pageImages[page])
            newPageView.contentMode = .ScaleAspectFit
            newPageView.frame = frame
            
            
            scrollView.addSubview(newPageView)
            print("frame \(newPageView.frame)")
            // 4
            pageViews[page] = newPageView

        }
    }

    //MARK: Scroll View Delegate
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        // Load the pages that are now on screen
        self.scrollView.contentOffset = CGPointMake(self.scrollView.contentOffset.x,0.0)
        loadVisiblePages()
    }
}
