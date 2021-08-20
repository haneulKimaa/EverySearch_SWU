//
//  BookmarkTableViewController.swift
//  EverySearch
//
//  Created by 김하늘 on 2021/06/01.
//

import UIKit
import CoreData

class BookmarkTableViewController: UITableViewController {


    var callNumber: String = ""
    var bookMarkGroup: [Man] = []
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var context: NSManagedObjectContext = NSManagedObjectContext()
    var bookMark: [Bookmark] = []
    

    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        OperationQueue.main.addOperation {
            self.fetchBookMark()
            self.tableView.reloadData()
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        context = appDelegate.persistentContainer.viewContext
        
        navigationItem.rightBarButtonItem = editButtonItem
        navigationItem.rightBarButtonItem?.tintColor = .systemBlue
       
        print("bookMark.count : \(bookMark.count)")
        
        
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
    }
    func fetchBookMark() {
        // 계속 bookMarkGroup 앞에
        bookMarkGroup = []
        do {
            bookMark = try context.fetch(Bookmark.fetchRequest()) as! [Bookmark]
            // bookMarkGroup = bookMark
            if bookMark.count > 0 {
                for i in 0...bookMark.count-1 {
                    if let teamTitle = bookMark[i].teamTitle, let name = bookMark[i].name, let number = bookMark[i].number, let category = bookMark[i].category {
                        let man = Man(teamTitle: teamTitle, name: name, number: number, category: category)
                        bookMarkGroup.append(man)
                        print(bookMarkGroup[i])
                    }
                }
            }
            else {
                
            }
            tableView.reloadData()
           // print(bookMarkGroup)
            
        } catch {
            print(error.localizedDescription)
        }
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return bookMarkGroup.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! BookmarkTableViewCell
        
        OperationQueue.main.addOperation {
            cell.teamTitleLabel.text = self.bookMarkGroup[indexPath.row].teamTitle
            cell.nameLabel.text = self.bookMarkGroup[indexPath.row].name
            cell.numberLabel.text = self.bookMarkGroup[indexPath.row].number
        }
        cell.selectionStyle = .none
        return cell
    }
    

    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            let alertController = UIAlertController(title: nil, message: "이 항목을 삭제하시겠습니까?", preferredStyle: .actionSheet)
            let deleteButton = UIAlertAction(title: "삭제", style: .destructive, handler: {_ in
                self.bookMarkGroup.remove(at: indexPath.row)
                let deleteObject = self.bookMark[indexPath.row]
                self.context.delete(deleteObject)
                do {
                    try self.context.save()
                } catch {
                    print(error.localizedDescription)
                }
                print(self.bookMarkGroup.count)
                
                tableView.deleteRows(at: [indexPath], with: .automatic)
                OperationQueue.main.addOperation {
                    self.fetchBookMark()
                    self.tableView.reloadData()
                }
            })
            
            let cancelButton = UIAlertAction(title: "취소", style: .cancel, handler: nil)
            alertController.addAction(deleteButton)
            alertController.addAction(cancelButton)
            
            self.navigationController!.present(alertController, animated: true, completion: nil)
        }
    }



    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .normal, title: "통화", handler: {(action, view, completionHandler) in
            print("전화")
            // searchController.active == true여야 filleredList가 생성됨.
            // active 전엔 group(filteredList의 filter 이전 배열)
            
            self.callNumber = self.bookMarkGroup[indexPath.row].number
           
            let numberURL = NSURL(string: "tel://" + "\(self.callNumber)")
            UIApplication.shared.canOpenURL(numberURL as! URL)
            UIApplication.shared.open(numberURL as! URL, options: [:], completionHandler: nil)
            completionHandler(true)
        })
        action.image = UIImage(systemName: "phone.arrow.up.right.fill")
        action.backgroundColor = UIColor.systemBlue
        print(callNumber)
        
        return UISwipeActionsConfiguration(actions: [action])
    }
    
    
    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

