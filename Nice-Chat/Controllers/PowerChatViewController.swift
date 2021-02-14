//
//  PowerChatViewController.swift
//  Power-Chat
//
//  Created by Michael Spagna on 1/15/21.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

struct Chatroom {
    let id: String
    let name: String
    let message: String
    let maxPower: Float
    let minPower: Float
}

class PowerChatViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var chatrooms = [Chatroom]()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(ChatroomTableViewCell.self,
                       forCellReuseIdentifier: ChatroomTableViewCell.identifier)
        return table
    }()
    
    private let noConversationsLabel: UILabel = {
       let label = UILabel()
        label.text = "No Chatrooms!"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIDevice.current.isBatteryMonitoringEnabled = true
        view.addSubview(tableView)
        setupTableView()
        fetchChatrooms()
        loadAllConversations()
    }
    
    private func loadAllConversations(){
        DatabaseManager.shared.getAllConversations(completion: { [weak self] result in
            switch result {
            case .success(let chatrooms):
                guard !chatrooms.isEmpty else{
                    return
                }
                self?.chatrooms = chatrooms
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            case .failure(let error):
                print("Failed to get chatrooms: \(error)")
            }
        })
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateAuth()
    }
    
    private func validateAuth(){
        if FirebaseAuth.Auth.auth().currentUser == nil{
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
        
    }
    
    private func setupTableView(){
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func fetchChatrooms(){
        tableView.isHidden = false
    }
}

extension PowerChatViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatrooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = chatrooms[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatroomTableViewCell.identifier, for: indexPath) as! ChatroomTableViewCell
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = chatrooms[indexPath.row]
        let vc = ChatroomViewController(with: model.id, maxPower: model.maxPower, minPower: model.minPower)
        var batteryLevel: Float{ UIDevice.current.batteryLevel }
        let maxPower = model.maxPower
        let minPower = model.minPower
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
//        if batteryLevel <= maxPower && batteryLevel >= minPower{
//            navigationController?.pushViewController(vc, animated: true)
//        }else{
//            let alert = UIAlertController(title: "Invalid Battery Value", message: "You must be in the power zone to enterthis chat", preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "Sorry", style: .cancel, handler: nil))
//
//            self.present(alert, animated: true)
//        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}
