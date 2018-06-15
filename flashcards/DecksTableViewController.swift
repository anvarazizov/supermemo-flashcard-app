//
//  ViewController.swift
//  flashcards
//
//  Created by Simone De Luca on 12/03/2017.
//  Copyright © 2017 Simone De Luca. All rights reserved.
//

import UIKit
import CoreData

class DecksTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: Outlets
    @IBOutlet weak var decksTable: UITableView!
    @IBOutlet weak var myCell: UITableViewCell!
    
    var decks : [Deck] = []
    
    // MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        decksTable.dataSource = self
        decksTable.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Fetch data from CoreData Deck entity
        fetchDecks()
        decksTable.reloadData()
    }

    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Segue to the DeckViewController
        if segue.identifier == "toDeck" {
            if  let cell = sender as? UITableViewCell, let indexPath = decksTable.indexPath(for: cell),
                let deckViewController = segue.destination as? DeckViewController {
                let deck = decks[indexPath.row]
                deckViewController.deck = deck
            }
        }
        if segue.identifier == "toAppUsage" {
            guard let appUsageViewController = segue.destination as? AppUsageViewController else { return }
            appUsageViewController.decks = decks
        }
    }
    
    // TableView methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return decks.count
    }
 
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "deckCell") as? DecksTableViewCell else {
            return UITableViewCell()
        }
        
        let deck = decks[indexPath.row]
        
        cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
        cell.title.text = deck.name
        cell.badge.text = getBadgeNumberString(deck: deck)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = decksTable.cellForRow(at: indexPath)
        // Perform segue to the DeckViewController
        self.performSegue(withIdentifier: "toDeck", sender: cell)
    }
    
    // Gets the number of reviews to do for a deck
    func getBadgeNumberString(deck: Deck) -> String {
        guard let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) else {
            return "0"
        }
        
        let tomorrowTimestamp = Calendar.current.startOfDay(for: tomorrowDate).timeIntervalSince1970
        let datePredicate = NSPredicate(format: "nextShown < %f", tomorrowTimestamp)
        let filteredDeck = deck.cards?.filtered(using: datePredicate) as NSSet?
        guard let cardsSet = filteredDeck as? Set<Card> else {
            return "0"
        }
        
        let count = cardsSet.count
        
        return "\(count)"
    }
    
    // Handle delete on swipe
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let alertController = UIAlertController(title: "Warning", message: "Are you sure you want to delete the deck? All cards and progress will be lost", preferredStyle: .alert)
            
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { (action) in
                
                if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                    let context = appDelegate.persistentContainer.viewContext
                    let deck = self.decks[indexPath.row]
                    
                    context.delete(deck)
                    appDelegate.saveContext()
                
                    self.fetchDecks()
                    self.decksTable.reloadData()
                }
            })
            
            alertController.addAction(deleteAction)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
                self.decksTable.setEditing(false, animated: true)
            })
            
            alertController.addAction(cancelAction)
            
            present(alertController, animated: true, completion: nil)
            
        }
        
    }
    
    // Fetch decks from Core data entity Deck
    func fetchDecks() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        let context = appDelegate.persistentContainer.viewContext
        
        do {
            decks = try context.fetch(Deck.fetchRequest())
        }
        catch {
            let alert = UIAlertController(title: "Error", message: "There was an error fetching your data, try restarting the application.", preferredStyle: UIAlertControllerStyle.alert)
            let dismissAction = UIAlertAction(title: "Got it!", style: .default, handler: { (UIAlertAction) -> Void in
            })
            alert.addAction(dismissAction)
            
            self.present(alert, animated: true, completion: nil)
        }
    }


}

