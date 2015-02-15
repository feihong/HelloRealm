import UIKit
import Realm


class Product: RLMObject {
    dynamic var name = ""
    dynamic var price = 0.0
    dynamic var rating = -1
    dynamic var startDate = NSDate(timeIntervalSince1970: 0)
    
    // Boilerplate necessary to implement custom initializer.
    // See https://github.com/realm/realm-cocoa/issues/1101
    override init() {
        super.init()
    }
    override init(object: AnyObject!) {
        super.init(object:object)
    };
    override init(object: AnyObject!, schema: RLMSchema!) {
        super.init(object: object, schema: schema)
    }
    override init(objectSchema: RLMObjectSchema) {
        super.init(objectSchema: objectSchema)
    }
    // end boilerplate
    
    convenience init(name: String, price: Double, rating: Int, startDate: String) {
        self.init()
        self.name = name
        self.price = price
        self.rating = rating
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        self.startDate = dateFormatter.dateFromString(startDate)!
    }
}


// Customized table view cell class that has the Subtitle style.
class Cell: UITableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String!) {
        super.init(style: .Subtitle, reuseIdentifier: reuseIdentifier)
    }
    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
}


class TableViewController: UITableViewController {

    var products = Product.allObjects()

    // This needs to be a property because the notification is deleted if the 
    // token variable goes out of scope.
    var notificationToken: RLMNotificationToken!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // Print the location of the default realm database file.
        println("Path to default realm database file: " + RLMRealm.defaultRealm().path)
        
        notificationToken = RLMRealm.defaultRealm().addNotificationBlock {
            // Avoid retain cycle (self owns notificationToken, which owns this 
            // closure, which would otherwise own self if we didn't use the 
            // unowned keyword).
            [unowned self] notification, realm in
            self.tableView.reloadData()
        }
        
        // If there are no products, add some to make the demo less boring.
        let realm = RLMRealm.defaultRealm()
        if Product.allObjects().count == 0 {
            // Show some different ways of adding RLMObjects to the database.
            realm.beginWriteTransaction()
            realm.addObject(Product(name: "Katana", price: 80.50, rating: 2, startDate: "2013-02-28"))
            Product.createInRealm(realm, withObject: ["Sais", 44.87, 5, NSDate()])
            realm.commitWriteTransaction()
            
            realm.transactionWithBlock {
                realm.addObject(Product(name: "Nunchakus", price: 35.05, rating: 4, startDate: "2013-05-15"))
                
                Product.createInDefaultRealmWithObject(["name": "Bo", "price": 56.23, "rating": 3, "startDate": NSDate()])
            }
        }
    }
    
    func setupUI() {
        tableView.registerClass(Cell.self, forCellReuseIdentifier: "cell")
        
        self.title = "Products"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .Add, target: self, action: "addProduct")
    }
    
    func addProduct() {
        let alert = UIAlertController(title: "Add a product", message: "",
            preferredStyle: .Alert)
        var nameTextField: UITextField!
        
        alert.addTextFieldWithConfigurationHandler { textField in
            nameTextField = textField
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "OK", style: .Default) { _ in
            let name = nameTextField.text
            
            // Make sure a product with the same name doesn't already exist.
            var results = Product.objectsWhere("name = %@", name)
            if results.count == 0 {
                RLMRealm.defaultRealm().transactionWithBlock {
                    Product.createInDefaultRealmWithObject([name, 0.0, 3, NSDate()])
                    return
                }
            } else {
                let title = "There's already a product named \(name) in the database"
                let alert = UIAlertController(title: title, message: "",
                    preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        })
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    override func tableView(tableView: UITableView?, numberOfRowsInSection section: Int) -> Int {
        return Int(products.count)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as Cell
        let product = products[UInt(indexPath.row)] as Product
        
        cell.textLabel?.text = product.name
        
        var detail = "$\(product.price), \(product.rating) stars, sold since " +
            NSString(string: "\(product.startDate)").substringToIndex(10)
        cell.detailTextLabel?.text = detail
        
        return cell
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            var realm = RLMRealm.defaultRealm()
            realm.beginWriteTransaction()
            realm.deleteObject(self.products[UInt(indexPath.row)] as RLMObject)
            realm.commitWriteTransaction()
        }
    }
}
