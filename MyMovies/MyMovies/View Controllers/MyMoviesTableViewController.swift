//
//  MyMoviesTableViewController.swift
//  MyMovies
//
//  Created by Spencer Curtis on 8/17/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit
import CoreData

class MyMoviesTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
   
    
    // MARK: - Properties
    
    var myMoviesController = MyMoviesController()
    
    lazy var fetchedResultsController: NSFetchedResultsController<Movie> = {
        
        let frc = CoreDataStack.shared.makeNewFetchedResultsController()
        frc.delegate = self
        try? frc.performFetch()
        return frc
        
        
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MyMovieCell", for: indexPath) as? MyMoviesTableViewCell else {fatalError("Unable to dequeue cell as EntryTableViewCell")}
        
        
        let movie = fetchedResultsController.object(at: indexPath)
   
        cell.myMoviesController = myMoviesController
      
        cell.movies = movie

        if cell.movies?.hasWatched == true {
            cell.basBeenWatchedButton.setTitle("Watched", for: .normal)
        } else {
            cell.basBeenWatchedButton.setTitle("Unwatched", for: .normal)
        }
       
        
        // Configure the cell...
        
        return cell
    }
    
   
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        // implement swipe to delete
        if editingStyle == .delete {
            let movie = fetchedResultsController.object(at: indexPath)
            
            // delete the task from the server
            myMoviesController.deleteMovieFromServer(movie: movie) { (error) in
                
                // make sure we were actually able to delete on the server
                // were not going
                if let error = error {
                    NSLog("error deleting entry from server: \(error)")
                    // if it failed, we are also not going to delete it locally
                    return
                }
                
                // assume the remove from server failed, we
                // create a new background context
                // we want to make it run on a background context
                guard let moc = movie.managedObjectContext else { return }
                
                // do the delete on the background context
                moc.perform {
                    moc.delete(movie)
                }
                
                // then we save the context (using our new save function on CDS.shared
                do {
                    try CoreDataStack.shared.save(context: moc)
                } catch {
                    // the save to local storage failed
                    NSLog("Error saving managed object context: \(error)")
                }
            }
            
            
        }
        
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        var sectionName: String = ""
        if fetchedResultsController.sections?[section].name == "0"{
            sectionName = "Unwatched"
        } else {
            sectionName = "Watched"
        }

        return sectionName
       
    }
    
    
    // MARK: - NSFetchedResultsControllerDelegate Methods
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .automatic)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .automatic)
        default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else { return }
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        case .update:
            guard let indexPath = indexPath else { return }
            tableView.reloadRows(at: [indexPath], with: .automatic)
        case .move:
            guard let oldIndexPath = indexPath,
                let newIndexPath = newIndexPath else { return }
            tableView.deleteRows(at: [oldIndexPath], with: .automatic)
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        case .delete:
            guard let indexPath = indexPath else { return }
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    
   
}
