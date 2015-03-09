import UIKit
import Realm


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
            // weak keyword).
            [weak self] notification, realm -> Void in
            self?.tableView.reloadData()
            return
        }
        
        // If there are no products, add some to make the demo less boring.
        if Product.allObjects().count == 0 {
            populateProducts()
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
        var priceTextField: UITextField!
        var ratingTextField: UITextField!
        
        alert.addTextFieldWithConfigurationHandler { textField in
            nameTextField = textField
            nameTextField.placeholder = "Product name"
        }
        alert.addTextFieldWithConfigurationHandler { textField in
            priceTextField = textField
            priceTextField.placeholder = "Price"
        }
        alert.addTextFieldWithConfigurationHandler { textField in
            ratingTextField = textField
            ratingTextField.placeholder = "Rating"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "OK", style: .Default) { _ in
            let name = nameTextField.text
            let price = (priceTextField.text as NSString).doubleValue
            let rating = (ratingTextField.text as NSString).integerValue
            
            // Make sure a product with the same name doesn't already exist.
            var results = Product.objectsWhere("name = %@", name)
            if results.count == 0 {
                RLMRealm.defaultRealm().transactionWithBlock {
                    Product.createInDefaultRealmWithObject([name, price, rating, NSDate()])
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

        let detail = String(format: "$%0.2f, %d stars, sold since ",
            product.price, product.rating) +
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
