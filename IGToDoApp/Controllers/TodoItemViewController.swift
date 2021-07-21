//
//  ViewController.swift
//  IGToDoApp
//
//  Created by İsmail on 16.07.2021.
//

import UIKit
import RealmSwift
import SwipeCellKit

class TodoItemViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SwipeTableViewCellDelegate {

    let realm = try! Realm()
    
    let tableView : UITableView = {
       let table = UITableView()

        table.register(SwipeTableViewCell.self, forCellReuseIdentifier: "cell")

        return table
    }()
    
    let searchController = UISearchController()
    
    var items : Results<Item>?
    var selectedCategory : Category? {
        didSet {
            loadItems()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = selectedCategory?.name ?? "Unkown Category"
        tableView.rowHeight = 80.0
        
        tableView.delegate = self
        tableView.dataSource = self
        
        view.addSubview(tableView)
        
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAdd))
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Type Item here..."
        navigationItem.searchController = searchController
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items?.count ?? 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SwipeTableViewCell
        
        cell.delegate = self
        
        if let item = items?[indexPath.row] {
            cell.textLabel?.text = item.title
            cell.accessoryType = item.done ? .checkmark : .none
        }
        else {
            cell.textLabel?.text = "No Item added yet."
        }
                
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let item = items?[indexPath.row] {
            do {
                try realm.write({
                    item.done = !item.done
                })
            }
            catch {
                print("Error while setting done property of item")
            }
        }
        
        DispatchQueue.main.async {
            tableView.reloadData()
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
    //Add new ToDo Item
    @objc private func didTapAdd() {
        let alert = UIAlertController(title: "New Item", message: "Enter new To Do list item", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Enter item..."
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { [weak self]_ in
            // add text from textField
            if let textField = alert.textFields?.first {
                if let text = textField.text, !text.isEmpty {
                    // Enter new item
                    if let currentCategory = self?.selectedCategory {
                        do {
                            try self?.realm.write({
                                let newItem = Item()
                                newItem.title = text
                                newItem.creationDate = Date()
                                currentCategory.items.append(newItem)
                            })
                        } catch {
                            print("Error while saving item to db \(error)")
                        }
                    }
                    
//                    DispatchQueue.main.async {
//                        self?.tableView.reloadData()
//                    }
                    self?.tableView.reloadData()
                }
            }
        }))
        
        present(alert, animated: true)
    }
    
    // Load items from db
    private func loadItems() {
        items = selectedCategory?.items.sorted(byKeyPath: "creationDate", ascending: true)
        tableView.reloadData()
    }
    
    // MARK: - Swipe Cell Kit protocol
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        if orientation == .right {
            let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
                
                self.updateModel(at: indexPath)
            }
            
//            deleteAction.image = UIImage(named: "delete-icon")
            deleteAction.title = "Delete"
            
            return [deleteAction]

        }
        else if orientation == .left {
            let editAction = SwipeAction(style: .default, title: "Edit") { action, indexPath in
                self.editModel(at: indexPath)
            }
            
//            editAction.image = UIImage(named: "edit-icon4")
            editAction.title = "Edit"
            editAction.backgroundColor = .systemBlue

            return [editAction]
        }
        else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        if(orientation == .right) {
            options.expansionStyle = .destructiveAfterFill
            options.transitionStyle = .border
        }
        else {
            options.expansionStyle = .none
            options.transitionStyle = .border
        }
        
        return options
    }
    
     // MARK: - Delete Data from Swipe
    private func updateModel(at indexPath: IndexPath) {
        if let itemForDeletion = self.items?[indexPath.row] {
            do {
                try self.realm.write {
                    self.realm.delete(itemForDeletion)
                }
            } catch {
                print("Error while deleting an item \(error)")
            }
        }
    }
    
    private func editModel(at indexPath: IndexPath) {
     if let item = items?[indexPath.row] {
         
         let alert = UIAlertController(title: "Edit Item", message: "Enter new name to Item", preferredStyle: .alert)
         
         alert.addTextField { textField in
             textField.placeholder = item.title
         }
         alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
         alert.addAction(UIAlertAction(title: "Edit", style: .default, handler: { [weak self]_ in
             // add text from textField
             if let textField = alert.textFields?.first {
                 if let text = textField.text, !text.isEmpty {
                     // Edit category
                         do {
                             try self?.realm.write({
                                 item.title = text
                             })
                         }
                         catch {
                             print("Error while editing object \(item)")
                         }
                         self?.tableView.reloadData()
                     
                 }
             }
         }))
         
         present(alert, animated: true)
     }
     
    }

}

//MARK: - Search Methods

extension TodoItemViewController : UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        if let text = searchController.searchBar.text, !text.isEmpty {
            
            items = items?.filter("title CONTAINS[cd] %@", text)
                .sorted(byKeyPath: "creationDate", ascending: true)
            
            tableView.reloadData()
        }
        else {
            loadItems()
        }
        
        
    }

}

