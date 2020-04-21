//
//  ChatViewController.swift
//  Flash Chat iOS13
//
//  Created by Angela Yu on 21/10/2019.
//  Copyright © 2019 Angela Yu. All rights reserved.
//

import UIKit
import Firebase

class ChatViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    
    let db = Firestore.firestore()
    
    var messages: [Message] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        navigationItem.hidesBackButton = true
   
        tableView.dataSource = self
        
        // TableView registrieren
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        
        loadMessages()
    }
    
    func loadMessages() {
        
        // querySnapshot enthält Message Objekt, sofern Abruf erfolgreich.
        db.collection(K.FStore.collectionName).order(by: K.FStore.dateField).addSnapshotListener { (querySnapshot, error) in
            
            // Immer wenn ein Neues Item zur Collection hinzugefügt wird, Feld leeren und nur die "frischen" Nachrichten hinzufügen
            self.messages = []
            
            if let e = error {
                print("There was an issue retrieving data from Firestore. \(e)")
            } else {
                
                if let snapshotDocuments = querySnapshot?.documents {
                    for doc in snapshotDocuments {
                        // Speichern als Daten, um auf die Eigenschaften zugreifen zu können. doc.data() = Dictionary
                        let data = doc.data()
                        // K.FStore.senderField --> "sender"
                        // Sender ist vom Typ Any, daher Optinal Downcast zu einem String
                        if let messageSender = data[K.FStore.senderField] as? String, let messageBody = data[K.FStore.bodyField] as? String {
                            
                            let message = Message(sender: messageSender, body: messageBody)
                            
                            // Array mit neuer Nachricht ergänzen
                            self.messages.append(message)
                   
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                               
                                // Ans Ende der Nachrichten Scrollen
                                let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                                self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func sendPressed(_ sender: UIButton) {

        if let messageBody = messageTextfield.text, let messageSender = Auth.auth().currentUser?.email {
            
            db.collection(K.FStore.collectionName).addDocument(data: [
                K.FStore.senderField: messageSender,
                K.FStore.bodyField: messageBody,
                //Zeitstempel der gesendeten Nachricht hinzufügen
                K.FStore.dateField: Date().timeIntervalSince1970
            ]) { (error) in
                if let e = error {
                    print("There was an issue saving Data to Firestore, \(e)")
                } else {
                    print("Successfully saved data")
                    // Wenn speichern Erfolgreich, lösche Eingabe aus Textfeld
                    self.messageTextfield.text = ""
                }
            }
        }
    }
    
    @IBAction func logoutPressed(_ sender: UIBarButtonItem) {
        do {
            try Auth.auth().signOut()
            navigationController?.popToRootViewController(animated: true)
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
}
//MARK: - UITableViewDataSource

extension ChatViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let message = messages[indexPath.row]
        
        // Beachte Constants Datei, für Definition von K
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath) as! MessageCell
        cell.label.text = message.body
        
        // Dies ist eine Nachricht vom aktuellen Nutzer
        if message.sender == Auth.auth().currentUser?.email {
            cell.leftImageView.isHidden = true
            cell.rightImageView.isHidden = false
            cell.messageBubble.backgroundColor = UIColor.init(named: K.BrandColors.lightPurple)
            cell.label.textColor = UIColor.init(named: K.BrandColors.purple)
        } else { // Dies ist eine Nachricht von einem anderen Sender
            cell.leftImageView.isHidden = false
            cell.rightImageView.isHidden = true
            cell.messageBubble.backgroundColor = UIColor.init(named: K.BrandColors.purple)
            cell.label.textColor = UIColor.init(named: K.BrandColors.lightPurple)
        }
        return cell
    }
}
