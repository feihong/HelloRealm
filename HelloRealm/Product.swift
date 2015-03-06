import Foundation
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

func populateProducts() {
    let realm = RLMRealm.defaultRealm()
    
    // Show some different ways of adding RLMObjects to the database.
    realm.beginWriteTransaction()
    realm.addObject(Product(name: "Katana", price: 80.50, rating: 2, startDate: "2013-02-28"))
    Product.createInRealm(realm, withObject: ["Sais", 44.87, 5, NSDate()])
    realm.commitWriteTransaction()
    
    realm.transactionWithBlock {
        realm.addObject(Product(name: "Nunchakus", price: 35.05, rating: 4, startDate: "2015-04-01"))
        
        Product.createInDefaultRealmWithObject(["name": "Bo", "price": 56.23, "rating": 3, "startDate": NSDate()])
    }
}
