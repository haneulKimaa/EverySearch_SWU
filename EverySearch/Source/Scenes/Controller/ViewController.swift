//
//  ViewController.swift
//  EverySearch
//
//  Created by 김하늘 on 2021/05/25.
//

import UIKit
import SwiftSoup
import CoreData

class ViewController: UIViewController {
    
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
    var indexpathNum: Int = 0
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSearchController()
        setupNavigationUI()
        crawl()
        setupTableView()
    }
    
    private func setupSearchController() {
        navigationItem.searchController = searchController
        searchController.searchResultsUpdater = self
        
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "기관명이나 성함, 또는 번호를 입력하세요"
        searchController.searchBar.scopeButtonTitles = ["전체", "기관", "대학"]
        searchController.searchBar.delegate = self
        searchController.searchBar.showsScopeBar = true
    }
    
    private func setupNavigationUI() {
        self.navigationItem.hidesSearchBarWhenScrolling = false
        self.navigationItem.title = "SWU 전화번호부"
        self.navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    private func setupTableView() {
        // 동적 셀 크기 조정
//        tableView.estimatedRowHeight = 88
//        tableView.rowHeight = UITableView.automaticDimension
//        tableView.reloadData()'
    }
    
    // MARK: - Function
    
    private func crawl() {
        guard let myURL = url else { return }
        
        do {
            let html = try String(contentsOf: myURL, encoding: .utf8)
            let doc: Document = try SwiftSoup.parse(html)
            let headertitle = try doc.title()
            print(html)
            
            // doc내 위치 (data가 들어있는 위치로 접근)
            let element = try doc.select("#body > div > div > script")
            
            // html -> string코드
            var stringHTML = try element[0].outerHtml()
            
            // Data 정리
            stringHTML = stringHTML.replacingOccurrences(of: "\r\n\t\t\t\t\t", with: "")
                .replacingOccurrences(of: "\t", with: "")
                .replacingOccurrences(of: "<br>", with: "")
                .replacingOccurrences(of: "//", with: "")
                .replacingOccurrences(of: """
                <script type="text/javascript">
                """, with: "")
                .replacingOccurrences(of: "</script>", with: "")
                .replacingOccurrences(of: "{}", with: "")
                .replacingOccurrences(of: "[", with: "")
                .replacingOccurrences(of: "]", with: "")
                .replacingOccurrences(of: "pnl.", with: "")
                .replacingOccurrences(of: "pnl", with: "")
                .replacingOccurrences(of: "{", with: "")
                .replacingOccurrences(of: "}", with: "")
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "\"", with: "")
                .replacingOccurrences(of: ",name", with: "+name")
                .replacingOccurrences(of: "name:", with: "")
                .replacingOccurrences(of: "number:", with: "")
            
            // 배열 생성
            var ttArr = stringHTML.components(separatedBy: ";")
            
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
            
            for index in 0..<plusDetachedTitleAndNumArray.count {
                for i in 0..<plusDetachedTitleAndNumArray[index].count {
                    let array = plusDetachedTitleAndNumArray[index][i].components(separatedBy: ",")
                    let teamTitle = titleArr[index].replacingOccurrences(of: ".구성원", with: "")
                        .replacingOccurrences(of: ".", with: " - ")
                        .replacingOccurrences(of: "\n", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    let oneMan = Man(teamTitle: teamTitle,
                                     name: array[0].trimmingCharacters(in: .whitespacesAndNewlines),
                                     number: array[1].trimmingCharacters(in: .whitespacesAndNewlines),
                                     category: titleArr[index].contains("대학") || titleArr[index].contains("전공") ? "대학" : "기관")
                    group.append(oneMan)
                }
            }
        } catch Exception.Error(type: _, Message: let message) {
            print("message = \(message)")
        } catch {
            print("error")
        }
    }
    
    private func filterContentForSearchText(_ searchText: String, scope: String = "전체") {
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
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isFiltering ? filteredManArrayForSearchBar.count : group.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? CustomTableViewCell else {
            return UITableViewCell()
        }
        
        let currentModel: Man = isFiltering ? self.filteredManArrayForSearchBar[indexPath.row] : self.group[indexPath.row]
        cell.teamTitleLabel.text = "\(currentModel.teamTitle)"
        cell.nameLabel.text = "\(currentModel.name)"
        cell.numberLabel.text = "\(currentModel.number)"
        
        // 셀이 클릭되는 것을 방지
        cell.selectionStyle = .none
        return cell
    }
    
    // swipe action(left) : 원하는 cell 즐겨찾기
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .normal, title: "즐겨찾기", handler: { [weak self] action, view, completionHandler in
            self?.setupStarAlert(for: indexPath)
        })
        action.image = UIImage(systemName: "star.fill")
        action.backgroundColor = UIColor.systemYellow
        return UISwipeActionsConfiguration(actions: [action])
    }
    
    private func setupStarAlert(for indexPath: IndexPath) {
        let alertController = UIAlertController(title: nil, message: "이 항목을 즐겨찾기에 추가하시겠습니까?", preferredStyle: .actionSheet)
        let cancelButton = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        let deleteButton = UIAlertAction(title: "추가", style: .default, handler: { [weak self] _ in
            self?.addToCoreData(indexPath: indexPath)
            self?.bookmarkVC.tableView.reloadData()
            self?.view.showToast("추가되었습니다.")
        })
        alertController.addAction(deleteButton)
        alertController.addAction(cancelButton)
        self.navigationController?.present(alertController, animated: true, completion: nil)
    }
    
    private func addToCoreData(indexPath: IndexPath) {
        let context = self.appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Bookmark", in: context)
        
        if let entity = entity {
            let person = NSManagedObject(entity: entity, insertInto: context)
            if !self.isFiltering {
                person.setValue(self.group[indexPath.row].teamTitle, forKey: "teamTitle")
                person.setValue(self.group[indexPath.row].name, forKey: "name")
                person.setValue(self.group[indexPath.row].category, forKey: "category")
                person.setValue(self.group[indexPath.row].number, forKey: "number")
            }
            else {
                person.setValue(self.filteredManArrayForSearchBar[indexPath.row].teamTitle, forKey: "teamTitle")
                person.setValue(self.filteredManArrayForSearchBar[indexPath.row].name, forKey: "name")
                person.setValue(self.filteredManArrayForSearchBar[indexPath.row].category, forKey: "category")
                person.setValue(self.filteredManArrayForSearchBar[indexPath.row].number, forKey: "number")
            }
            
            do {
                try context.save()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let action = UIContextualAction(style: .destructive, title: "통화", handler: {(action, view, completionHandler) in
            // searchController.active == true여야 filleredList가 생성됨.
            // active 전엔 group(filteredList의 filter 이전 배열)
            
            let callNumber = self.isFiltering ? self.filteredManArrayForSearchBar[indexPath.row].number : self.group[indexPath.row].number
            
            guard let numberURL = URL(string: "tel://" + "\(callNumber)") else {
                self.view.showToast("없는 번호입니다.")
                return
            }
            UIApplication.shared.canOpenURL(numberURL)
            UIApplication.shared.open(numberURL)
            completionHandler(true)
        })
        action.image = UIImage(systemName: "phone.arrow.up.right.fill")
        action.backgroundColor = UIColor.systemBlue
        
        return UISwipeActionsConfiguration(actions: [action])
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        searchController.searchBar.resignFirstResponder()
    }
}

extension ViewController: UISearchBarDelegate, UISearchResultsUpdating {
    
    func searchBar(_ searchBar: UISearchBar,
                   selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
        
        filterContentForSearchText(searchBar.text!, scope: scope)
    }
}
