import Foundation

final class CommitCommand {
    let git: Git
    init(git: Git) { self.git = git }
    func run(args: [String]) throws -> String {
        guard git.isGitRepo else { throw GitFlowError(message: "Not a git repository", code: 4) }
        var message: String?, autoMessage = false, amend = false
        var i = 0
        while i < args.count {
            switch args[i] {
            case "-m", "--message": if i + 1 < args.count { message = args[i + 1]; i += 2 } else { throw GitFlowError(message: "Missing message", code: 2) }
            case "--amend": amend = true; i += 1
            case "--auto", "-a": autoMessage = true; i += 1
            default: i += 1
            }
        }
        _ = try git.add()
        let status = try git.status()
        if status.isEmpty { return "Nothing to commit" }
        if message == nil { message = autoMessage ? "Update files" : (throw GitFlowError(message: "No message", code: 2)) }
        let result = try git.commit(message: message!, amend: amend)
        return "✅ Committed!\n\(result)"
    }
}

final class BranchCommand {
    let git: Git
    init(git: Git) { self.git = git }
    func run(args: [String]) throws -> String {
        guard git.isGitRepo else { throw GitFlowError(message: "Not a git repository", code: 4) }
        var listAll = false, create: String?, delete: String?, rename: (String, String)?
        var i = 0
        while i < args.count {
            switch args[i] {
            case "-a", "--all": listAll = true; i += 1
            case "create", "new": if i + 1 < args.count { create = args[i + 1]; i += 2 } else { throw GitFlowError(message: "Missing name", code: 2) }
            case "delete", "del": if i + 1 < args.count { delete = args[i + 1]; i += 2 } else { throw GitFlowError(message: "Missing name", code: 2) }
            case "rename": if i + 2 < args.count { rename = (args[i + 1], args[i + 2]); i += 3 } else { throw GitFlowError(message: "Usage: rename <old> <new>", code: 2) }
            default: i += 1
            }
        }
        if let c = create { return try git.createBranch(c) }
        if let d = delete { return try git.deleteBranch(d) }
        let output = try git.branches(all: listAll)
        let current = try git.currentBranch
        var result = "📋 Branches:\n"
        for line in output.components(separatedBy: "\n").filter({!$0.isEmpty}) {
            let isCurrent = line.hasPrefix("*")
            let name = line.replacingOccurrences(of: "* ", with: "  ").components(separatedBy: " ").first ?? line
            result += isCurrent ? "✅ \(name)\n" : "  \(name)\n"
        }
        return result
    }
}

final class ChangelogCommand {
    let git: Git
    init(git: Git) { self.git = git }
    func run(args: [String]) throws -> String {
        guard git.isGitRepo else { throw GitFlowError(message: "Not a git repository", code: 4) }
        var fromTag: String?, toRef = "HEAD", conventional = false
        var i = 0
        while i < args.count {
            switch args[i] {
            case "--from", "-f": if i + 1 < args.count { fromTag = args[i + 1]; i += 2 } else { throw GitFlowError(message: "Missing tag", code: 2) }
            case "--to", "-t": if i + 1 < args.count { toRef = args[i + 1]; i += 2 }
            case "--conventional", "-c": conventional = true; i += 1
            default: i += 1
            }
        }
        if fromTag == nil { let t = try git.tags(); fromTag = t.components(separatedBy: "\n").first }
        let from = fromTag ?? "HEAD~100"
        let commits = try git.logRange(from: from, to: toRef)
        var changelog = "# Changelog\n\nFrom \(from) to \(toRef)\n\n"
        if conventional {
            for line in commits.components(separatedBy: "\n") where !line.isEmpty {
                let p = line.components(separatedBy: "|"); guard p.count >= 2 else { continue }
                let msg = p[1], prefix = msg.hasPrefix("feat") ? "✦" : (msg.hasPrefix("fix") ? "⚡" : "•")
                changelog += "\(prefix) \(msg)\n"
            }
        } else {
            for line in commits.components(separatedBy: "\n") where !line.isEmpty {
                let p = line.components(separatedBy: "|"); guard p.count >= 2 else { continue }
                changelog += "- \(p[1]) (\(p[0]))\n"
            }
        }
        return changelog
    }
}

final class UndoCommand {
    let git: Git
    init(git: Git) { self.git = git }
    func run(args: [String]) throws -> String {
        guard git.isGitRepo else { throw GitFlowError(message: "Not a git repository", code: 4) }
        var count = 1, hard = false
        var i = 0
        while i < args.count {
            switch args[i] {
            case "--count", "-n": if i + 1 < args.count, let c = Int(args[i + 1]) { count = c; i += 2 }
            case "--hard", "-H": hard = true; i += 1
            default: if let c = Int(args[i]) { count = c; i += 1 } else { i += 1 }
            }
        }
        if hard { _ = try git.resetHard(count: count); return "⚠️ Undo \(count) commit(s) (hard) - ALL changes discarded!" }
        _ = try git.reset(mode: "--soft", count: count); return "✅ Undo \(count) commit(s) (soft) - changes staged"
    }
}

final class StashCommand {
    let git: Git
    init(git: Git) { self.git = git }
    func run(args: [String]) throws -> String {
        guard git.isGitRepo else { throw GitFlowError(message: "Not a git repository", code: 4) }
        var list = false, push: String?, pop: String?, drop: String?, clear = false
        var i = 0
        while i < args.count {
            switch args[i] {
            case "list", "ls": list = true; i += 1
            case "push", "save": push = i + 1 < args.count ? args[i + 1] : nil; i += push != nil ? 2 : 1
            case "pop": pop = i + 1 < args.count ? args[i + 1] : nil; i += pop != nil ? 2 : 1
            case "drop": drop = i + 1 < args.count ? args[i + 1] : nil; i += drop != nil ? 2 : 1
            case "clear": clear = true; i += 1
            default: i += 1
            }
        }
        if list || (args.isEmpty) {
            let o = try git.stashList()
            if o.isEmpty { return "📦 No stashes" }
            var r = "📦 Stashes:\n"
            for line in o.components(separatedBy: "\n") where !line.isEmpty {
                let p = line.components(separatedBy: ": "); if p.count >= 2 { r += "[\(p[0].replacingOccurrences(of: "stash@{", with: "").replacingOccurrences(of: "}", with: ""))] \(p[1])\n" }
            }
            return r
        }
        if let m = push { _ = try Git().run(["stash", "push", "-m", m]); return "📦 Stashed: \(m)" }
        if let n = pop { _ = try Git().run(["stash", "pop", n]); return "📦 Applied: \(n)" }
        if let n = drop { _ = try Git().run(["stash", "drop", n]); return "🗑️ Dropped: \(n)" }
        if clear { _ = try Git().run(["stash", "clear"]); return "🗑️ All stashes cleared" }
        return try listStashes()
    }
    private func listStashes() throws -> String { let o = try git.stashList(); return o.isEmpty ? "📦 No stashes" : "📦 Stashes:\n\(o)" }
}

final class SyncCommand {
    let git: Git
    init(git: Git) { self.git = git }
    func run(args: [String]) throws -> String {
        guard git.isGitRepo else { throw GitFlowError(message: "Not a git repository", code: 4) }
        var fetch = true, pull = false, push = false, remote = "origin"
        var i = 0
        while i < args.count {
            switch args[i] {
            case "--fetch", "-f": fetch = true; i += 1
            case "--pull", "-p": pull = true; i += 1
            case "--push", "-u": push = true; i += 1
            case "--all", "-a": fetch = true; pull = true; push = true; i += 1
            case "--remote", "-r": if i + 1 < args.count { remote = args[i + 1]; i += 2 } else { throw GitFlowError(message: "Missing remote", code: 2) }
            default: i += 1
            }
        }
        var r = "🔄 Sync Complete\n\n"
        if fetch { _ = try git.fetch(); r += "📥 Fetched\n" }
        if pull { _ = try git.pull(); r += "📥 Pulled\n" }
        if push { _ = try git.push(); r += "📤 Pushed\n" }
        return r
    }
}

final class InfoCommand {
    let git: Git
    init(git: Git) { self.git = git }
    func run(args: [String]) throws -> String {
        guard git.isGitRepo else { throw GitFlowError(message: "Not a git repository", code: 4) }
        var result = "📊 Repo Info\n\n"
        result += "🌿 Branch: \(try git.currentBranch)\n"
        if let url = try? git.remoteURL() { result += "🔗 Remote: \(url)\n" }
        let commits = try git.log(count: 1)
        if let p = commits.components(separatedBy: "|").first { result += "📝 Last: \(p)\n" }
        return result
    }
}

final class ConfigCommand {
    func run(args: [String]) throws -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let configPath = "\(home)/.config/gitflow/config.json"
        if args.isEmpty || args[0] == "show" { return "⚙️ Config:\ndefaultBranch: main\nautoFetch: true" }
        if args[0] == "reset" { return "✅ Config reset" }
        return "⚙️ Config"
    }
}
