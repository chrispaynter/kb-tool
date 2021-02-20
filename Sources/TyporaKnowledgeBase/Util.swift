import Foundation
import Cocoa

class FolderStructureItem: CustomStringConvertible {
    internal init(isDirectory: Bool, url: URL) {
        self.isDirectory = isDirectory
        self.url = url
    }
    
    var isDirectory: Bool
    var url: URL;
    
    var children: [FolderStructureItem] = [];
    var parent: FolderStructureItem?;
    
    
    var description: String {
        return url.path;
    }
}

class CustomNSMenuItem: NSMenuItem {
    var item: FolderStructureItem?;
}

func buildFolderStructure(kbRootPath:String)->FolderStructureItem {
    let url = URL(fileURLWithPath: kbRootPath)
    
    let root = FolderStructureItem(isDirectory: true, url: url);
    
    var currentDirectory: FolderStructureItem = root;
    
    if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
        
        for case let fileURL as URL in enumerator {
            do {
                if(fileURL.scheme != nil && fileURL.scheme == "file") {
                    
                    let isInCurrentDir = currentDirectory.url == fileURL.deletingLastPathComponent();
                    if(!isInCurrentDir) {
                        currentDirectory = currentDirectory.parent!;
                    }
                  
                    if(fileURL.hasDirectoryPath) {
                        let newDir = FolderStructureItem(isDirectory: true, url: fileURL);
                        newDir.parent = currentDirectory;
                        currentDirectory.children.append(newDir);
                        currentDirectory = newDir;
                    } else {
                        let fileItem = FolderStructureItem(isDirectory: false, url: fileURL);
                        currentDirectory.children.append(fileItem);
                    }
                }
            } catch { print(error, fileURL) }
        }
        
        root.children.forEach() { child in
            print(child.url);
        }
    }
    
    return root;
}

func recursiveFileItemBuild(menu:NSMenu, rootItem: FolderStructureItem, action:Selector) {
    
    rootItem.children.forEach() { item in
        let menuItem = CustomNSMenuItem(title: "", action: action, keyEquivalent: "")
        menuItem.item = item;
        menu.addItem(menuItem)
        
        if(item.children.count > 0) {
            menuItem.title = "🗂 \(item.url.lastPathComponent)";
            let subMenu = NSMenu(title: item.url.lastPathComponent);
            menu.setSubmenu(subMenu, for: menuItem);
            recursiveFileItemBuild(menu: subMenu, rootItem: item, action:action)
        } else {
            menuItem.title = "📖 \(item.url.lastPathComponent)";
        }
    }
}


func shell(_ args: String...) -> Int32 {
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = args
    task.currentDirectoryPath = "~/kb"
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}
