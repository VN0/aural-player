import Cocoa

class FilterBandViewController: NSViewController {
    
    override var nibName: String? {return "FilterBand"}
    
    @IBOutlet weak var filterTypeMenu: NSPopUpButton!
    
    @IBOutlet weak var freqRangeSlider: FilterBandSlider!
    @IBOutlet weak var cutoffSlider: CutoffFrequencySlider!
    @IBOutlet weak var cutoffSliderCell: CutoffFrequencySliderCell!
    
    @IBOutlet weak var lblRangeCaption: NSTextField!
    @IBOutlet weak var presetRangesMenu: NSPopUpButton!
    
    @IBOutlet weak var lblCutoffCaption: NSTextField!
    @IBOutlet weak var presetCutoffsMenu: NSPopUpButton!
    
    @IBOutlet weak var lblFrequencies: NSTextField!
    
    @IBOutlet weak var tabButton: NSButton!
    
    private let filterUnit: FilterUnitDelegateProtocol = ObjectGraph.audioGraphDelegate.filterUnit
    
    var band: FilterBand = FilterBand.init(.bandStop).withMinFreq(AppConstants.Sound.audibleRangeMin).withMaxFreq(AppConstants.Sound.subBass_max)
    var bandIndex: Int!
    
    var bandChangedCallback: (() -> Void) = {() -> Void in
        // Do nothing
    }
    
    override func awakeFromNib() {
        freqRangeSlider.onControlChanged = {(slider: RangeSlider) -> Void in self.freqRangeChanged()}
    }
    
    override func viewDidLoad() {
        resetFields()
    }
    
    private func resetFields() {
        
        let filterType = band.type
        
        filterTypeMenu.selectItem(withTitle: filterType.description)
        
        [freqRangeSlider, lblRangeCaption, presetRangesMenu].forEach({$0?.showIf_elseHide(filterType == .bandPass || filterType == .bandStop)})
        [cutoffSlider, lblCutoffCaption, presetCutoffsMenu].forEach({$0?.hideIf_elseShow(filterType == .bandPass || filterType == .bandStop)})
        
        if filterType == .bandPass || filterType == .bandStop {
            
            freqRangeSlider.filterType = filterType
            
            freqRangeSlider.setFrequencyRange(band.minFreq!, band.maxFreq!)
            lblFrequencies.stringValue = String(format: "[ %@ - %@ ]", formatFrequency(freqRangeSlider.startFrequency), formatFrequency(freqRangeSlider.endFrequency))
            
            cutoffSlider.setFrequency(AppConstants.Sound.audibleRangeMin)
            
        } else {
            
            cutoffSlider.setFrequency(filterType == .lowPass ? band.maxFreq! : band.minFreq!)
            
            cutoffSliderCell.filterType = filterType
            cutoffSlider.redraw()
            lblFrequencies.stringValue = formatFrequency(cutoffSlider.frequency)
            
            freqRangeSlider.setFrequencyRange(AppConstants.Sound.audibleRangeMin, AppConstants.Sound.subBass_max)
        }
        
        presetCutoffsMenu.selectItem(at: -1)
        presetRangesMenu.selectItem(at: -1)
    }
    
    @IBAction func bandTypeAction(_ sender: Any) {
        
        let filterType = FilterBandType.fromDescription(filterTypeMenu.titleOfSelectedItem!)
        band.type = filterType
        
        [freqRangeSlider, lblRangeCaption, presetRangesMenu].forEach({$0?.showIf_elseHide(filterType == .bandPass || filterType == .bandStop)})
        [cutoffSlider, lblCutoffCaption, presetCutoffsMenu].forEach({$0?.hideIf_elseShow(filterType == .bandPass || filterType == .bandStop)})
        
        if filterType == .bandPass || filterType == .bandStop {
            
            freqRangeSlider.filterType = filterType
            freqRangeChanged()
            
            band.minFreq = freqRangeSlider.startFrequency
            band.maxFreq = freqRangeSlider.endFrequency
            
        } else {
            
            cutoffSliderCell.filterType = filterType
            cutoffSlider.redraw()
            cutoffSliderAction(self)
            
            band.minFreq = filterType == .lowPass ? nil : cutoffSlider.frequency
            band.maxFreq = filterType == .lowPass ? cutoffSlider.frequency : nil
        }
        
        filterUnit.updateBand(bandIndex, band)
        
        bandChangedCallback()
    }
    
    private func freqRangeChanged() {
        
        band.minFreq = freqRangeSlider.startFrequency
        band.maxFreq = freqRangeSlider.endFrequency
        
        filterUnit.updateBand(bandIndex, band)
        
        lblFrequencies.stringValue = String(format: "[ %@ - %@ ]", formatFrequency(freqRangeSlider.startFrequency), formatFrequency(freqRangeSlider.endFrequency))
        
        bandChangedCallback()
    }
    
    @IBAction func cutoffSliderAction(_ sender: Any) {
        
        band.minFreq = band.type == .lowPass ? nil : cutoffSlider.frequency
        band.maxFreq = band.type == .lowPass ? cutoffSlider.frequency : nil
        
        filterUnit.updateBand(bandIndex, band)
        
        lblFrequencies.stringValue = formatFrequency(cutoffSlider.frequency)
        
        bandChangedCallback()
    }
    
    @IBAction func presetRangeAction(_ sender: NSPopUpButton) {
        
        if let range = sender.selectedItem as? FrequencyRangeMenuItem {
            
            freqRangeSlider.setFrequencyRange(range.minFreq, range.maxFreq)
            freqRangeChanged()
        }
        
        presetRangesMenu.selectItem(at: -1)
    }
    
    @IBAction func presetCutoffAction(_ sender: NSPopUpButton) {
        
        cutoffSlider.setFrequency(Float(sender.selectedItem!.tag))
        cutoffSliderAction(self)
        presetCutoffsMenu.selectItem(at: -1)
    }
    
    private func formatFrequency(_ freq: Float) -> String {
        
        let rounded = roundedInt(freq)
        
        if rounded % 1000 == 0 {
            return String(format: "%dKHz", rounded / 1000)
        } else {
            return String(format: "%dHz", rounded)
        }
    }
}