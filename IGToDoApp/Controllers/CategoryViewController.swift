//
//  CategoryViewController.swift
//  IGToDoApp
//
//  Created by İsmail on 17.07.2021.
//

import UIKit
import RealmSwift
import SwipeCellKit

class CategoryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SwipeTableViewCellDelegate {

    let realm = try! Realm()
    
    let tableView : UITableView = {
       let table = UITableView()
        
        table.register(SwipeTableViewCell.self, forCellReuseIdentifier: "cell")
        
        return table
    }()
    
    let searchController = UISearchController()
    
    var categories : Results<Category>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Categories"
        tableView.rowHeight = 80.0
        
        tableView.delegate = self
        tableView.dataSource = self
        
        view.addSubview(tableView)
        
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAdd))
        
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Type Category here..."
        navigationItem.searchController = searchController

        loadCategories()
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    // MARK: - TableView Datasource methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories?.count ?? 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SwipeTableViewCell
        
        cell.delegate = self
        
        cell.textLabel?.text = categories?[indexPath.row].name ?? "No Categories Added Yet!"
                
        return cell
    }
    
    
    // MARK: - TableView Delegate methods

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Create new ToDoItem VC and push it
        let vc = TodoItemViewController()
        if let category = categories?[indexPath.row] {
            vc.selectedCategory = category
        }
        else {
            vc.selectedCategory = nil
            print("No category can be set as SelectedCategory")
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        vc.modalPresentationStyle = .fullScreen
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - Data Manipulation Methods
    
    func save(category: Category) {
        
        // save to db
        do{
            try realm.write({
                realm.add(category)
            })
        } catch {
            print("Error while saving category to db \(error)")
        }
        
        
        tableView.reloadData()
    }
    
    func loadCategories() {
        
        // categories = fetch from db
        categories = realm.objects(Category.self)
        
        tableView.reloadData()
    }
    
    @objc private func didTapAdd() {
        let alert = UIAlertController(title: "New Category", message: "Enter new To Category", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Enter Category..."
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { [weak self]_ in
            // add text from textField
            if let textField = alert.textFields?.first {
                if let text = textField.text, !text.isEmpty {
                    // Enter new category
                    let newCategory = Category()
                    newCategory.name = text
                    newCategory.creationDate = Date()
                    
                    self?.save(category: newCategory)
                    
                }
            }
        }))
        
        present(alert, animated: true)
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

        // customize the action appearance

//        let configuration = UIImage.SymbolConfiguration(scale: .large)

//        //editAction.image = UIImage(systemName: "square.and.pencil", withConfiguration: configuration)
        //editAction.image = UIImage(systemName: "compose", withConfiguration: configuration)


//        return [deleteAction, editAction]
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
    
    if let categoryForDeletion = self.categories?[indexPath.row] {
        do {
            try self.realm.write {
                self.realm.delete(categoryForDeletion)
            }
        } catch {
            print("Error while deleting a category \(error)")
        }
    }
    
}
   
   private func editModel(at indexPath: IndexPath) {
    if let category = categories?[indexPath.row] {
        
        let alert = UIAlertController(title: "Edit Category", message: "Enter new name to Category", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = category.name
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Edit", style: .default, handler: { [weak self]_ in
            // add text from textField
            if let textField = alert.textFields?.first {
                if let text = textField.text, !text.isEmpty {
                    // Edit category
                        do {
                            try self?.realm.write({
                                category.name = text
                            })
                        }
                        catch {
                            print("Error while editing object \(category)")
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

extension CategoryViewController : UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        if let text = searchController.searchBar.text, !text.isEmpty {
            
            categories = categories?.filter("name CONTAINS[cd] %@", text)
                .sorted(byKeyPath: "creationDate", ascending: true)
            
            tableView.reloadData()
        }
        else {
            loadCategories()
        }
    }
    
}
