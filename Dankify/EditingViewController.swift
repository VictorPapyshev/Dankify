//
//  EditingViewController.swift
//  Dankify
//
//  Created by Victor Papyshev on 9/9/18.
//  Copyright © 2018 Victor Papyshev. All rights reserved.
//

import UIKit
import CoreImage
import CoreGraphics

extension UIImage {
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, true, self.scale)
        let context = UIGraphicsGetCurrentContext()!
        
        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}

class EditingViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var fryMenuView: UIImageView!
    @IBOutlet weak var posterizeSlider: UISlider!
    @IBOutlet weak var sharpenSlider: UISlider!
    @IBOutlet weak var sharpenButton: UIButton!
    @IBOutlet weak var blueFryButton: UIButton!
    @IBOutlet weak var redFryButton: UIButton!
    @IBOutlet weak var posterizeButton: UIButton!
    
    let imagePicker = UIImagePickerController()
    let context = CIContext()
    var currentCIImage: CIImage? = nil
    var currentUIImage: UIImage? = nil
    var currentCGImage: CGImage? = nil
    let redFryCIImage = CIImage(image: #imageLiteral(resourceName: "redFryGradient"))
    let blueFryCIImage = CIImage(image: #imageLiteral(resourceName: "blueFryGradient"))
    var sharpenIntensity : Double = 5
    var posterizeIntensity : Double = 6
    var originalImageURL : URL? = nil
    var originalImageURLString : String = ""
    var imagePreparedForSaving : Bool = false
    var createdImages = [String]()
    var fryMenuHidden : Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func openPhotoLibrary() {
        
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            print("no photo library, idiot")
            return
        }
        
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        
        self.present(imagePicker, animated: true)
        
    }
    
    @IBAction func fryMenuButton(_ sender: UIButton) {
        if fryMenuHidden == true {
            fryMenuView.isHidden = false
            sharpenButton.isHidden = false
            posterizeButton.isHidden = false
            redFryButton.isHidden = false
            blueFryButton.isHidden = false
            sharpenSlider.isHidden = false
            posterizeSlider.isHidden = false
            fryMenuHidden = false
        } else {
            fryMenuView.isHidden = true
            sharpenButton.isHidden = true
            posterizeButton.isHidden = true
            redFryButton.isHidden = true
            blueFryButton.isHidden = true
            sharpenSlider.isHidden = true
            posterizeSlider.isHidden = true
            fryMenuHidden = true
        }
    }
    
    @IBAction func pickImageButton(_ sender: UIButton) {
        openPhotoLibrary()
    }
    
    @IBAction func clearFiltersButton(_ sender: UIButton) {
        if originalImageURL != nil {
            currentCIImage = CIImage(contentsOf: originalImageURL!)
            refreshImageView()
        }
    }
    
    @IBAction func sharpenImage(_ sender: UIButton) {
        if currentCIImage != nil {
            currentCIImage = sharpen(currentCIImage!, intensity: sharpenIntensity)
            refreshImageView()
        }
    }
    @IBAction func sharpenIntensitySlider(_ sender: UISlider) {
        sharpenIntensity = Double(sender.value)
    }
    
    @IBAction func posterizeIntensitySlider(_ sender: UISlider) {
        posterizeIntensity = Double(sender.value)
    }
    
    @IBAction func posterizeImage(_ sender: UIButton) {
        if currentCIImage != nil {
            currentCIImage = posterize(currentCIImage!, intensity: posterizeIntensity)
            refreshImageView()
        }
    }
    
    @IBAction func redFryImage(_ sender: UIButton) {
        if currentCIImage != nil {
            currentCIImage = colorFry(currentCIImage!, secondInput: redFryCIImage!)
            refreshImageView()
        }
    }
    
    @IBAction func rotateImageLeft(_ sender: UIButton) {
        currentUIImage = imageView.image?.rotate(radians: -.pi/2)
        currentCIImage = CIImage(image: currentUIImage!)
        imageView.image = currentUIImage
    }
    
    @IBAction func rotateImageRight(_ sender: UIButton) {
        currentUIImage = imageView.image?.rotate(radians: .pi/2)
        currentCIImage = CIImage(image: currentUIImage!)
        imageView.image = currentUIImage
    }
    
    @IBAction func blueFryImage(_ sender: UIButton) {
        if currentCIImage != nil {
            currentCIImage = colorFry(currentCIImage!, secondInput: blueFryCIImage!)
            refreshImageView()
        }
    }
    
    @IBAction func saveImage(_ sender: UIButton) {
        if currentUIImage != nil {
            prepareImageForSaving(currentUIImage!)
            UIImageWriteToSavedPhotosAlbum(currentUIImage!, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    @IBAction func createLensFlare(_ sender: UIButton) {
        createImage(image: #imageLiteral(resourceName: "lensFlareImage"))
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let imageURL = info[UIImagePickerControllerImageURL] as? URL {
            originalImageURL = imageURL
            currentCIImage = CIImage(contentsOf: originalImageURL!)
            
            refreshImageView()
            
        }
        
        self.dismiss(animated: true, completion: nil)
        
    }
    
    func sharpen(_ input: CIImage, intensity: Double) -> CIImage? {
        let sharpenFilter = CIFilter(name: "CISharpenLuminance")
        sharpenFilter?.setValue(input, forKey: kCIInputImageKey)
        sharpenFilter?.setValue(intensity, forKey: kCIInputSharpnessKey)
        return sharpenFilter?.outputImage
    }
    
    func posterize(_ input: CIImage, intensity: Double) -> CIImage? {
        let posterizeFilter = CIFilter(name: "CIColorPosterize")
        posterizeFilter?.setValue(input, forKey: kCIInputImageKey)
        posterizeFilter?.setValue(intensity, forKey: "inputLevels")
        return posterizeFilter?.outputImage
    }
    
    func colorFry(_ input: CIImage, secondInput: CIImage) -> CIImage? {
        let colorFryFilter = CIFilter(name: "CIColorMap")
        colorFryFilter?.setValue(input, forKey: kCIInputImageKey)
        colorFryFilter?.setValue(secondInput, forKey: "inputGradientImage")
        return colorFryFilter?.outputImage
    }
    
    func refreshImageView() {
        currentUIImage = UIImage(ciImage: currentCIImage!)
        if Float((currentUIImage?.size.width)!) > Float((currentUIImage?.size.height)!) {
            currentUIImage = currentUIImage?.rotate(radians: .pi/2)
        }
        imageView.image = currentUIImage
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if error != nil {
            ProgressHUD.showError("Save failed!")
        } else {
            ProgressHUD.showSuccess("Saved!")
        }
    }
    
    func saveImageSelector(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if error != nil {
            ProgressHUD.showError("Save failed!")
        } else {
            ProgressHUD.showSuccess("Saved!")
        }
    }
    
    func prepareImageForSaving(_ image: UIImage) {
        if image.ciImage != nil {
            currentCGImage = context.createCGImage(currentCIImage!, from: (currentCIImage?.extent)!)
            currentUIImage = UIImage(cgImage: currentCGImage!)
        }
    }
    
    func createImage(image: UIImage) {
        let createdImageView = UIImageView(image: image)
        createdImageView.frame = CGRect(x: 0, y: 0, width: 100, height: 50)
        createdImageView.isUserInteractionEnabled = true
        view.addSubview(createdImageView)
    }
    
}
