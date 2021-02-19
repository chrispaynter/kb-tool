import Cocoa

class MenuFileItem: CustomStringConvertible {
    internal init(isDirectory: Bool, url: URL) {
        self.isDirectory = isDirectory
        self.url = url
    }
    
    var isDirectory: Bool
    var url: URL;
    
    var children: [MenuFileItem] = [];
    var parent: MenuFileItem?;
    
    
    var description: String {
        return url.path;
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusBarItem: NSStatusItem!
    
    let commitMenuItem = NSMenuItem(title: "☁️ Sync changes now",
                                    action: #selector(AppDelegate.commitChanges),
                                    keyEquivalent: "");
    
    let syncedMenuItem = NSMenuItem(title: "Everything up to date.",
                                    action: nil,
                                    keyEquivalent: "");
    
    let mainDropdown = NSMenuItem(title: "Items",
                                    action: nil,
                                    keyEquivalent: "");
    let subMenu = NSMenu(title: "Structure");
    
    var timer:Timer?;
    
    func startTimer() {
        stopTimer();
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { _ in
            self.checkForChanges()
        })
    }
    
    func stopTimer() {
        if(timer != nil) {
            timer!.invalidate();
            timer = nil;
        }
    }
    
    func buildKBFolders() {
        
        let kbRootPath = "/Users/chris/kb";
        let url = URL(fileURLWithPath: kbRootPath)
        
        let root = MenuFileItem(isDirectory: true, url: url);
        
        var currentDirectory: MenuFileItem = root;
        
        if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
            
            for case let fileURL as URL in enumerator {
                print("CURRENT \(currentDirectory.url.path)")
                do {
                    if(fileURL.scheme != nil && fileURL.scheme == "file") {
                        
                        let isInCurrentDir = currentDirectory.url == fileURL.deletingLastPathComponent();
                        if(!isInCurrentDir) {
                            currentDirectory = currentDirectory.parent!;
                            print("BACK TO DIR \(currentDirectory.url.path)")
                        }
                      
                        if(fileURL.hasDirectoryPath) {
                            let newDir = MenuFileItem(isDirectory: true, url: fileURL);
                            newDir.parent = currentDirectory;
                            currentDirectory.children.append(newDir);
                            currentDirectory = newDir;
                            print("ADDING DIR \(newDir.url.path)")
                        } else {
                            let fileItem = MenuFileItem(isDirectory: false, url: fileURL);
                            print("ADDING FILE \(fileItem.url.path)")
                            currentDirectory.children.append(fileItem);
                        }
                    }
                    print()
                } catch { print(error, fileURL) }
            }
            
            root.children.forEach() { child in
                print(child.url);
            }
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let statusBar = NSStatusBar.system
        statusBarItem = statusBar.statusItem(
            withLength: NSStatusItem.variableLength)
        
        
        statusBarItem.button?.title = "🧠"
        syncedMenuItem.isHidden = true;
        
        let main = NSMenu(title: "Knowledge Base Menu")
        statusBarItem.menu = main
        
        main.addItem(syncedMenuItem)
        main.addItem(commitMenuItem)
        main.addItem(NSMenuItem.separator())
        main.addItem(mainDropdown);
        main.setSubmenu(subMenu, for: mainDropdown)
        main.addItem(NSMenuItem.separator())
        main.addItem(
            withTitle: "Settings",
            action: #selector(AppDelegate.quit),
            keyEquivalent: "")
        main.addItem(
            withTitle: "Quit",
            action: #selector(AppDelegate.quit),
            keyEquivalent: "")
        
        self.checkForChanges()
        
       startTimer()
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
    
    @objc func checkForChanges() {
        if(shell("git", "diff", "--quiet", "--exit-code") != 0 ||
            shell("git", "diff", "--staged", "--quiet", "--exit-code") != 0) {
            statusBarItem.button?.title = "🧠⚠️"
            commitMenuItem.isHidden = false;
            syncedMenuItem.isHidden = true;
            print("CHANGES");
        } else {
            statusBarItem.button?.title = "🧠"
            commitMenuItem.isHidden = true;
            syncedMenuItem.isHidden = false;
            print("NO CHANGES");
        }
    }
    
    
    @objc func commitChanges() {
        stopTimer();
        statusBarItem.button?.title = "🧠⏳"
        shell("git", "add", "-A");
        shell("git", "commit", "-m", "Updated.");
        shell("git", "push");
        statusBarItem.button?.title = "🧠✅"
        commitMenuItem.isHidden = true;
        syncedMenuItem.isHidden = false;
        startTimer()
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(self)
    }
}
