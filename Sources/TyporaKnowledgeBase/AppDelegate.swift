import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    
    let main = NSMenu(title: "Knowledge Base Menu")
    
    var statusBarItem: NSStatusItem!
    
    let commitMenuItem = NSMenuItem(title: "☁️ Sync changes now",
                                    action: #selector(AppDelegate.commitChanges),
                                    keyEquivalent: "");
    
    let syncedMenuItem = NSMenuItem(title: "👍🏻 Everything has been synced",
                                    action: nil,
                                    keyEquivalent: "");
    
    
    
    let mainDropdown = NSMenuItem(title: "Items",
                                  action: nil,
                                  keyEquivalent: "");
    let subMenu = NSMenu(title: "Structure");
     
    let rootPath = "/Users/chris/kb";
    
    
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
    
    
    func buildFileMenu() {
        let structure = buildFolderStructure(kbRootPath: rootPath);
        filterFoldersByName(root: structure, name: "images")
        recursiveFileItemBuild(menu: main,
                               rootItem: structure,
                               action: #selector(selectItem(_:)))
    }
    
    func layoutMenu() {
        main.removeAllItems()
        main.addItem(syncedMenuItem)
        main.addItem(commitMenuItem)
//        main.addItem(NSMenuItem.separator())
//        main.addItem(NSMenuItem(title: "Recent Files", action: nil, keyEquivalent: ""))
        main.addItem(NSMenuItem.separator())
        main.addItem(NSMenuItem(title: "Knowledge Base", action: nil, keyEquivalent: ""))
        buildFileMenu()
        main.addItem(NSMenuItem.separator())
        main.addItem(
            withTitle: "Open in editor",
            action: #selector(openInEditor),
            keyEquivalent: "")
        main.addItem(
            withTitle: "Settings",
            action: #selector(AppDelegate.quit),
            keyEquivalent: "")
        main.addItem(
            withTitle: "Quit",
            action: #selector(AppDelegate.quit),
            keyEquivalent: "")
    }
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let statusBar = NSStatusBar.system
        statusBarItem = statusBar.statusItem(
            withLength: NSStatusItem.variableLength)
        
        
        statusBarItem.button?.title = "🧠"
        syncedMenuItem.isHidden = true;
        statusBarItem.menu = main
        
        layoutMenu()
        
        self.checkForChanges()
        
        startTimer()
    }
    
    @objc func openInEditor() {
        openPath(path: rootPath)
    }
    
    @objc func checkForChanges() {
        
        let res = shell("git", "status", "--porcelain");
        
        if(res.code == 0 && res.outputString != "") {
            statusBarItem.button?.title = "🧠✏️"
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
    
    @objc func selectItem(_ sender: CustomNSMenuItem) {
        openPath(path: sender.item!.url.path)
    }
    
    func openPath(path:String) {
        NSWorkspace.shared.openFile(path, withApplication: "Typora")
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(self)
    }
}
