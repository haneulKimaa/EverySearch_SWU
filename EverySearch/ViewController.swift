//
//  ViewController.swift
//  EverySearch
//
//  Created by 김하늘 on 2021/05/25.
//

import UIKit
import SwiftSoup
import CoreData

class ViewController: UIViewController, UITableViewDelegate {

    // MARK: - @IBOutlet Properties
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    let searchController = UISearchController()
    let bookmarkVC = BookmarkTableViewController()
    
    var isSearchBarEmpty: Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    let url = URL(string: "https://www.swu.ac.kr/www/camd.html")
    var filteredManArrayForSearchBar: [Man] = []
    var isFiltering: Bool {
        let searchBarScopeIsFiltering = searchController.searchBar.selectedScopeButtonIndex != 0
        return (!isSearchBarEmpty && searchController.isActive) || searchBarScopeIsFiltering
    }
    
    // 하나의 teamtitle내에 있는 연락처를 +로 이은 string의 배열
    // ex) 교목실장,02-970-5221+교목실/경건회,02-970-5222+전담교수채병관,02-970-5224 (하나의 인덱스값임)
    var allDataAttachedArray: Array = [""]
    
    // 각 teamtitle의 집합
    var titleArr: Array = [""]
    
    // Man들의 집합
    var group: [Man] = []
    
    // team[title][name과 number] : ttArr2를 +로 쪼개고 난 배열.( team[titleArr[index]][+단위로 쪼갠 것] )
    // ex) ["교목실장,02-970-5221", "교목실/경건회,02-970-5222", "전담교수채병관,02-970-5224"] (하나의 인덱스값임. team[0])
    var plusDetachedTitleAndNumArray: [[String]] = [[""]]
    var callNumber: String = ""
    var indexpathNum: Int = 0
    var giveGroup: Man = Man(teamTitle: "", name: "", number: "", category: "")
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    
    
    func crawl() {
        guard let myURL = url else {
            return
        }
        do {
            let html = try String(contentsOf: myURL, encoding: .utf8)
            let doc: Document = try SwiftSoup.parse(html)
            let headertitle = try doc.title()
            print(html)
            
            // doc내 위치 (data가 들어있는 위치로 접근)
            let element = try doc.select("#body > div > div > script")
            
           // html -> string코드
            var tt = try element[0].outerHtml()
            
            // Data 정리
            tt = tt.replacingOccurrences(of: "\r\n\t\t\t\t\t", with: "").replacingOccurrences(of: "\t", with: "").replacingOccurrences(of: "<br>", with: "").replacingOccurrences(of: "//", with: "").replacingOccurrences(of: """
                <script type="text/javascript">
                """, with: "").replacingOccurrences(of: "</script>", with: "").replacingOccurrences(of: "{}", with: "").replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "").replacingOccurrences(of: "pnl.", with: "").replacingOccurrences(of: "pnl", with: "").replacingOccurrences(of: "{", with: "").replacingOccurrences(of: "}", with: "").replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: ",name", with: "+name").replacingOccurrences(of: "name:", with: "").replacingOccurrences(of: "number:", with: "")
            
            // 배열 생성
            var ttArr = tt.components(separatedBy: ";")
            
        
            // Data 정리 2
            ttArr.removeAll {$0.contains("push()")}
            ttArr.removeAll {!$0.contains("구성원")}

            // 오름차순으로 sort
            ttArr.sort()
            
            for index in 0..<ttArr.count {
                allDataAttachedArray.append(contentsOf: ttArr[index].components(separatedBy: "="))
            }
            allDataAttachedArray.removeAll {$0.isEmpty}
            allDataAttachedArray.removeAll {$0 == "교무처.교무팀"}
            allDataAttachedArray.removeAll {$0 == "평생교육원.평생교육팀"}
            
            
            for index in 0..<allDataAttachedArray.count {
                if index % 2 == 1 {
                    let array = allDataAttachedArray[index].components(separatedBy: "+")
                    plusDetachedTitleAndNumArray.append(array)
                }
                else {
                    titleArr.append(allDataAttachedArray[index])
                }
            }
            plusDetachedTitleAndNumArray.removeFirst()
            titleArr.removeFirst()
            
            
            // print("------------------")
            
            for index in 0..<plusDetachedTitleAndNumArray.count {
                for i in 0..<plusDetachedTitleAndNumArray[index].count {
                    let array = plusDetachedTitleAndNumArray[index][i].components(separatedBy: ",")
                    let oneMan = Man(teamTitle: titleArr[index].replacingOccurrences(of: ".구성원", with: "").replacingOccurrences(of: ".", with: " - "), name: array[0], number: array[1], category: { () -> String in
                        if titleArr[index].contains("대학") || titleArr[index].contains("전공") {
                            return "대학"
                        }
                        else {
                            return "기관"
                        }
                           
                        
                    }())
                    group.append(oneMan)
                }
            }
            
            for index in 0..<group.count {
                print(group[index])
            }
            
        } catch Exception.Error(type: let type, Message: let message) {
            print("message = \(message)")
        } catch {
            print("error")
        }
        
        
    }
    func filterContentForSearchText(_ searchText: String, scope: String = "전체") {
        filteredManArrayForSearchBar = group.filter { (man: Man) -> Bool in
            let doesCategoryMatch = (scope == "전체") || (man.category == scope)
            if !isSearchBarEmpty {
                return doesCategoryMatch && (man.teamTitle.contains(searchText) || man.name.contains(searchText) || man.number.contains(searchText))
            }
            else {
                return doesCategoryMatch
            }
        }
        tableView.reloadData()
        }
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        searchController.searchBar.resignFirstResponder()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.searchController = searchController
        searchController.searchResultsUpdater = self
        
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "기관명이나 성함, 또는 번호를 입력하세요"
        self.navigationItem.hidesSearchBarWhenScrolling = false
        searchController.searchBar.scopeButtonTitles = [ "전체", "기관", "대학" ]
        searchController.searchBar.delegate = self
        searchController.searchBar.showsScopeBar = true
        self.navigationItem.title = "SWU 전화번호부"
        self.navigationController?.navigationBar.prefersLargeTitles = true

        // 동적 셀 크기 조정
        tableView.estimatedRowHeight = 88
        tableView.rowHeight = UITableView.automaticDimension
        crawl()
        tableView.reloadData()
        
        // Do any additional setup after loading the view.
    }
}

extension ViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
        
        filterContentForSearchText(searchBar.text!, scope: scope)
    }
}
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering {
            return filteredManArrayForSearchBar.count
        }
        return group.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomTableViewCell
        
        if isFiltering {
            giveGroup = self.filteredManArrayForSearchBar[indexPath.row]
        }
        else {
            giveGroup = self.group[indexPath.row]
        }
        cell.teamTitleLabel.text = "\(giveGroup.teamTitle)"
        cell.nameLabel.text = "\(giveGroup.name)"
        cell.numberLabel.text = "\(giveGroup.number)"
        
        // 셀이 클릭되는 것을 방지
        cell.selectionStyle = .none
        return cell
    }
    // swipe action(left) : 원하는 cell 즐겨찾기
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .normal, title: "즐겨찾기", handler: {(action, view, completionHandler) in
            
            let alertController = UIAlertController(title: nil, message: "이 항목을 즐겨찾기에 추가하시겠습니까?", preferredStyle: .actionSheet)
            let alertController2 = UIAlertController(title: nil, message: "추가되었습니다.", preferredStyle: .alert)
            let cancelButton = UIAlertAction(title: "취소", style: .cancel, handler: nil)
            let checkButton = UIAlertAction(title: "확인", style: .default, handler: nil)

            alertController2.addAction(checkButton)
            let deleteButton = UIAlertAction(title: "추가", style: .default, handler: {_ in
                let context = self.appDelegate.persistentContainer.viewContext
                let entity = NSEntityDescription.entity(forEntityName: "Bookmark", in: context)
                
                if let entity = entity {
                    let person = NSManagedObject(entity: entity, insertInto: context)
                    if !self.isFiltering {
                        person.setValue(self.group[indexPath.row].teamTitle, forKey: "teamTitle")
                        person.setValue(self.group[indexPath.row].name, forKey: "name")
                        person.setValue(self.group[indexPath.row].category, forKey: "category")
                        person.setValue(self.group[indexPath.row].number, forKey: "number")
                        print(self.group[indexPath.row])
                    }
                    else {
                        person.setValue(self.filteredManArrayForSearchBar[indexPath.row].teamTitle, forKey: "teamTitle")
                        person.setValue(self.filteredManArrayForSearchBar[indexPath.row].name, forKey: "name")
                        person.setValue(self.filteredManArrayForSearchBar[indexPath.row].category, forKey: "category")
                        person.setValue(self.filteredManArrayForSearchBar[indexPath.row].number, forKey: "number")
                        print(self.filteredManArrayForSearchBar[indexPath.row])
                    }
                    
                    do {
                        try context.save()
                    } catch {
                        print(error.localizedDescription)
                    }
                }
                self.bookmarkVC.tableView.reloadData()
                completionHandler(true)
                self.navigationController!.present(alertController2, animated: true, completion: nil)
            })
            
            alertController.addAction(deleteButton)
            alertController.addAction(cancelButton)
            self.navigationController!.present(alertController, animated: true, completion: nil)
            
        })
        action.image = UIImage(systemName: "star.fill")
        action.backgroundColor = UIColor.systemYellow
        return UISwipeActionsConfiguration(actions: [action])
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
   
        //if
        let action = UIContextualAction(style: .destructive, title: "통화", handler: {(action, view, completionHandler) in
            // searchController.active == true여야 filleredList가 생성됨.
            // active 전엔 group(filteredList의 filter 이전 배열)
            if self.isFiltering {
                self.callNumber = self.filteredManArrayForSearchBar[indexPath.row].number
            }
            else {
                self.callNumber = self.group[indexPath.row].number
            }
            
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
}
extension ViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
