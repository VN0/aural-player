import Cocoa

class FileSystemBrowserViewDelegate: NSObject, NSOutlineViewDelegate, NSOutlineViewDataSource {
    
    let mainFont_13: NSFont = NSFont(name: "Play Regular", size: 13)!
    
    private var fsTree: FileSystemItem!
    
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        return 25
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        
        if item == nil {

            fsTree = FileSystemItem(url: URL(fileURLWithPath: "/Users/kven/Music/Grimes"))
            return fsTree.children.count

        } else if let fsItem = item as? FileSystemItem {

            return fsItem.children.count
        }
        
        return 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        
        if item == nil {
            
            return fsTree.children[index]
            
        } else if let fsItem = item as? FileSystemItem {
            
            return fsItem.children[index]
        }
        
        return ""
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return (item as? FileSystemItem)?.isDirectory ?? false
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        
        if let fsItem = item as? FileSystemItem {
            return createNameCell(outlineView, fsItem.url.lastPathComponent)
        }
        
        return nil
    }
    
    private func createNameCell(_ outlineView: NSOutlineView, _ text: String) -> NSTableCellView? {
        
        guard let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("fileSystemBrowser_name"), owner: nil)
            as? NSTableCellView else {return nil}
        
        cell.imageView?.image = nil
        
        cell.textField?.stringValue = text
        cell.textField?.font = mainFont_13
        
        return cell
    }
}