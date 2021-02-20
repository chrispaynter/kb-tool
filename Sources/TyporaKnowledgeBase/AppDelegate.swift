import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    
    let main = NSMenu(title: "Knowledge Base Menu")
    
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
    

    func buildFileMenu() {
        let structure = buildFolderStructure(kbRootPath: "/Users/chris/kb");
        recursiveFileItemBuild(menu: main,
                               rootItem: structure,
                               action: #selector(selectItem(_:)))
    }
    
    func layoutMenu() {
        main.removeAllItems()
        main.addItem(syncedMenuItem)
        main.addItem(commitMenuItem)
        main.addItem(NSMenuItem.separator())
//        main.addItem(mainDropdown);
        buildFileMenu()
        main.addItem(NSMenuItem.separator())
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
    
    @objc func selectItem(_ sender: CustomNSMenuItem) {
        print("\(sender.item?.url.path)");
        NSWorkspace.shared.openFile(sender.item!.url.path, withApplication: "Typora")
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(self)
    }
}
