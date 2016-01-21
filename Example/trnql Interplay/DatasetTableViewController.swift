//
//  DatasetTableViewController.swift
//  trnql Interplay
//
//  Created by Jonathan Sahoo on 8/17/15.
//  Copyright (c) 2015 trnql. All rights reserved.
//

import UIKit

class DatasetTableViewController: UITableViewController {

    var dataset = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return dataset.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) 

        if indexPath.row == dataset.count - 1 {
            cell.textLabel?.textColor = UIColor.blueColor()
        }
        else {
            cell.textLabel?.textColor = UIColor.blackColor()
        }
        
        cell.textLabel?.text = dataset[indexPath.row] ?? ""

        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.row == dataset.count - 1 {
            UIApplication.sharedApplication().openURL(NSURL(string:"http://www.trnql.com/guides/")!)
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
    }

}
