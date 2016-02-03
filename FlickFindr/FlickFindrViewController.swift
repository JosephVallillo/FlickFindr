//
//  FlickFindrViewController.swift
//  FlickFindr
//
//  Created by Joseph Vallillo on 1/28/16.
//  Copyright © 2016 Joseph Vallillo. All rights reserved.
//

import UIKit

class FlickFindrViewController: UIViewController, UITextFieldDelegate {
    
    //MARK: - Outlets
    @IBOutlet weak var imageContainerView: UIView!
    @IBOutlet weak var flickImageView: UIImageView!
    @IBOutlet weak var flickImageTextLabel: UILabel!
    
    @IBOutlet weak var searchAndInfoContainerView: UIView!
    
    @IBOutlet weak var searchContainerView: UIView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchPhotosByTextButton: UIButton!
    
    @IBOutlet weak var latitudeTextField: UITextField!
    @IBOutlet weak var longitudeTextField: UITextField!
    @IBOutlet weak var searchPhotosByLocationButton: UIButton!
    
    @IBOutlet weak var infoContainerView: UIView!
    @IBOutlet weak var infoTextLabel: UILabel!
    
    
    //MARK: - Properties
    let BASE_URL = "https://api.flickr.com/services/rest/"
    let METHOD_NAME = "flickr.photos.search"
    let API_KEY = "2db569c23aac5e508aa08bf35ddd02c6"
    let SAFE_SEARCH = "1"
    let EXTRAS = "url_m"
    let DATA_FORMAT = "json"
    let NO_JSON_CALLBACK = "1"
    
    let BOUNDING_BOX_HALF_WIDTH = 1.5
    let BOUNDING_BOX_HALF_HEIGHT = 1.5
    let LAT_MIN = -90.0
    let LAT_MAX = 90.0
    let LONG_MIN = -180.0
    let LONG_MAX = 180.0
    
    //MARK: - Actions
    
    @IBAction func searchPhotosByTextButtonTouchUp(sender: UIButton) {
        
        self.dismissAllVisibleKeyboards()
        
        if let searchText = self.searchTextField.text {
            if searchText != "" {
                self.infoTextLabel.text = "Searching..."
                getSearchedImageFromFlickr(searchText)
            } else {
                self.infoTextLabel.text = "Please enter search text before searching!"
            }
        }
    }
    
    @IBAction func searchPhotosByLocationButtonTouchUp(sender: UIButton) {
        
        self.dismissAllVisibleKeyboards()
        
        if let latText = self.latitudeTextField.text {
            if let longText = self.longitudeTextField.text  {
                if latText != "" && longText != "" {
                    if validLatitude(latText) && validLongitude(longText) {
                        self.infoTextLabel.text = "Searching..."
                        getImageFromFlickrByLocation()
                    } else {
                        if !validLatitude(latText) && !validLongitude(longText) {
                            self.infoTextLabel.text = "Lat/Lon Invalid.\nLat should be [-90, 90].\nLon should be [-180, 180]."
                        } else if !validLatitude(latText) {
                            self.infoTextLabel.text = "Lat Invalid.\nLat should be [-90, 90]."
                        } else {
                            self.infoTextLabel.text = "Lon Invalid.\nLon should be [-180, 180]."
                        }
                    }
                } else {
                    if self.latitudeTextField.text!.isEmpty && self.longitudeTextField.text!.isEmpty {
                        self.infoTextLabel.text = "Lat/Lon Empty."
                    } else if self.latitudeTextField.text!.isEmpty {
                        self.infoTextLabel.text = "Lat Empty."
                    } else {
                        self.infoTextLabel.text = "Lon Empty."
                    }
                }
            }
        }
    }
    
    func validLatitude(lat: String) -> Bool {
        if let latDouble : Double = lat.doubleValue() {
            if latDouble < LAT_MIN || latDouble > LAT_MAX {
                return false
            }
        } else {
            return false
        }
        return true
    }
    
    func validLongitude(long: String) -> Bool {
        if let longDouble : Double = long.doubleValue() {
            if longDouble < LONG_MIN || longDouble > LONG_MAX {
                return false
            }
        } else {
            return false
        }
        return true
    }
    
    //MARK: - Keyboard
    func keyboardWillShow(notification: NSNotification) {
        if searchTextField.isFirstResponder()||latitudeTextField.isFirstResponder()||longitudeTextField.isFirstResponder() {
            if self.view.frame.origin.y == 0 {
                self.infoTextLabel.hidden = true
                self.view.frame.origin.y -= getKeyboardHeight(notification)
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        self.infoTextLabel.hidden = false
        self.view.frame.origin.y = 0
    }
    
    func getKeyboardHeight(notifcation: NSNotification) -> CGFloat {
        let userInfo = notifcation.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.CGRectValue().height
    }
    
    func subscribeToKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "keyboardWillShow:",
            name: UIKeyboardWillShowNotification,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "keyboardWillHide:",
            name: UIKeyboardWillHideNotification,
            object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    //MARK: - Text Field Delegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
    
    //MARK: - View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        searchTextField.delegate = self
        latitudeTextField.delegate = self
        longitudeTextField.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.subscribeToKeyboardNotifications()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.unsubscribeFromKeyboardNotifications()
    }
    
    //MARK: - Flickr API
    func getSearchedImageFromFlickr(searchText: String) {
        //API method arguments
        let methodArguments = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "tags": searchText,
            "safe_search": SAFE_SEARCH,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK
        ]
        
        getFlickrImageFromSearchText(methodArguments)
    }
    
    func getImageFromFlickrByLocation() {
        //API method arguments
        let methodArguements = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "bbox": createBoundingBoxString(),
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK
        ]
        
        getFlickrImageFromSearchText(methodArguements)
    }

    func getFlickrImageFromSearchText(methodArguments: [String : AnyObject]) {
        let session = NSURLSession.sharedSession()
        let requestURL = NSURL(string: BASE_URL + escapedParameters(methodArguments))!
        let request = NSURLRequest(URL: requestURL)
        
        
        //initialize task for getting data
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            //Check for a successful response
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                return
            }
            
            
            //Check for a 2xx HTTP response
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    print("Your request returned an invalid response: \(response.statusCode)")
                } else if let response = response {
                    print("You request returned an invalid response: \(response)")
                } else {
                    print("Your request returned an invalid response: \(response)")
                }
                
                return
            }
            
            //Check if any data returned
            guard let data = data else {
                print("No data was returned by the request")
                return
            }
            
            //Parse the data
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                parsedResult = nil
                print("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            //Check flickr for error
            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                print("Flickr API returned an error")
                return
            }
            
            //Check if photos and photo ket are in result
            guard let photosDictionary = parsedResult["photos"] as? NSDictionary,
                photoArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                    print("Cannot find keys 'photos' and 'photo' in \(parsedResult)")
                    return
            }
            
            //Check if pages is in the photosDictionary
            guard let totalPages = photosDictionary["pages"] as? Int else {
                print("Cannot find ket 'pages in \(photosDictionary)")
                return
            }
            
            let pageLimit = min(totalPages, 40)
            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            self.getImageFromFlickrBySearchWithPage(methodArguments, pageNumber: randomPage)
        }
        
        //start task
        task.resume()
    }
    
    func getImageFromFlickrBySearchWithPage(methodArguments: [String : AnyObject], pageNumber: Int) {
        //add the page to the method's arguments
        var withPageDictionary = methodArguments
        withPageDictionary["page"] = pageNumber
        
        let session = NSURLSession.sharedSession()
        let requestURL = NSURL(string: BASE_URL + escapedParameters(methodArguments))!
        let request = NSURLRequest(URL: requestURL)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            //Check for a successful response
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                return
            }
            
            
            //Check for a 2xx HTTP response
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    print("Your request returned an invalid response: \(response.statusCode)")
                } else if let response = response {
                    print("You request returned an invalid response: \(response)")
                } else {
                    print("Your request returned an invalid response: \(response)")
                }
                
                return
            }
            
            //Check if any data returned
            guard let data = data else {
                print("No data was returned by the request")
                return
            }
            
            //Parse the data
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                parsedResult = nil
                print("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            //Check flickr for error
            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                print("Flickr API returned an error")
                return
            }
            
            guard let photosDictionary = parsedResult["photos"] as? NSDictionary,
                photoArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                    print("Cannot find keys 'photos' and 'photo' in \(parsedResult)")
                    return
            }
            
            guard let totalPhotosVal = (photosDictionary["total"] as? NSString)?.integerValue else {
                print("Cannot find key 'total' in \(photosDictionary)")
                return
            }
            
            if totalPhotosVal > 0 {
                
                guard let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                    print("Cannot find key 'photo in \(photosDictionary)")
                    return
                }
                
                //generate random number and select the corresponding photo
                let randomPhotoIndex = Int(arc4random_uniform(UInt32(photoArray.count)))
                let photoDictionary = photoArray[randomPhotoIndex] as [String: AnyObject]
                let photoTitle = photoDictionary["title"] as? String
                
                //get image url
                guard let imageURLString = photoDictionary["url_m"] as? String else{
                    print("Cannot find key 'url_m' in \(photoDictionary)")
                    return
                }
                
                let imageURL = NSURL(string: imageURLString)
                if let imageData = NSData(contentsOfURL: imageURL!) {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.flickImageView.image = UIImage(data: imageData) ?? nil
                        self.infoTextLabel.text = photoTitle ?? "Could not retrieve an image!"
                        if self.flickImageView.image == nil {
                            self.flickImageTextLabel.hidden = false
                        }
                        self.flickImageTextLabel.hidden = true
                    })
                }
            }
        }
        task.resume()
    }
    

    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }

    func createBoundingBoxString() -> String {
        let latitude = (self.latitudeTextField.text! as NSString).doubleValue
        let longitutde = (self.longitudeTextField.text! as NSString).doubleValue
        
        //ensure box is bounded by minimum and maximum
        let minLong = max(longitutde - BOUNDING_BOX_HALF_WIDTH, LONG_MIN)
        let maxLong = min(longitutde + BOUNDING_BOX_HALF_WIDTH, LONG_MAX)
        let minLat = max(latitude - BOUNDING_BOX_HALF_HEIGHT, LAT_MIN)
        let maxLat = min(latitude + BOUNDING_BOX_HALF_HEIGHT, LAT_MIN)
        
        return "\(minLong), \(minLat), \(maxLong), \(maxLat)"
    }
}

extension FlickFindrViewController {
    func dismissAllVisibleKeyboards() {
        if searchTextField.isFirstResponder() || latitudeTextField.isFirstResponder() || longitudeTextField.isFirstResponder() {
            self.view.endEditing(true)
        }
    }
}

extension String {
    func doubleValue() -> Double {
        return (NSNumberFormatter().numberFromString(self)?.doubleValue)!
    }
}
