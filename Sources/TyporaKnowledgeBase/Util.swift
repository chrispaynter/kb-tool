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

func sortItems(left:FolderStructureItem, right:FolderStructureItem)->Bool {
    let priority = "                  ";
    let leftName = left.isDirectory ? "\(priority)\(left.url.lastPathComponent)" : left.url.lastPathComponent
    let rightName = right.isDirectory ? "\(priority)\(right.url.lastPathComponent)" : right.url.lastPathComponent
    return leftName.lowercased() < rightName.lowercased();
}

func recursiveFileItemBuild(menu:NSMenu, rootItem: FolderStructureItem, action:Selector) {
    
    let sorted = rootItem.children.sorted { (left, right) -> Bool in
        return sortItems(left: left, right: right)
    }
    
    sorted.forEach() { item in
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

class ShellExecutionResult {
    init(code:Int32, output:String) {
        self.code = code;
        self.outputString = output;
    }
    var code:Int32;
    var outputString:String;
}

func shell(_ args: String...) -> ShellExecutionResult {
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = args
    task.currentDirectoryPath = "~/kb"
    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()
    var outstr = ""
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    if let output = String(data: data, encoding: .utf8) {
        outstr = output as String
    }
    task.waitUntilExit()
    return ShellExecutionResult(code: task.terminationStatus, output: outstr)
}

func filterFoldersByName(root:FolderStructureItem, name:String) {
    
    root.children = root.children.filter({
        if($0.isDirectory) {
            return $0.url.lastPathComponent.lowercased() != name.lowercased()
        } else {
            return true;
        }
        
    })
    root.children.forEach() { child in filterFoldersByName(root: child, name: name)}
}
