import Foundation

final class Git {
    let workingDirectory: URL
    init(wd: URL = FileManager.default.currentDirectoryURL) { self.workingDirectory = wd }
    
    func run(_ args: [String]) throws -> String {
        let p = Process(); p.executableURL = URL(fileURLWithPath: "/usr/bin/git"); p.arguments = args; p.currentDirectoryURL = workingDirectory
        let o = Pipe(), e = Pipe(); p.standardOutput = o; p.standardError = e; try p.run(); p.waitUntilExit()
        if p.terminationStatus != 0 { throw GitFlowError(message: String(data: e.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)!.trimmingCharacters(in: .whitespacesAndNewlines), code: 3) }
        return String(data: o.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)!.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    var isGitRepo: Bool { (try? run(["rev-parse", "--git-dir"])) != nil }
    var currentBranch: String { (try? run(["branch", "--show-current"])) ?? "" }
    func status() throws -> String { try run(["status", "--porcelain"]) }
    func add(_ files: [String] = ["-A"]) throws -> String { try run(["add"] + files) }
    func commit(message: String, amend: Bool = false) throws -> String { var a = ["commit", "-m", message]; if amend { a.append("--amend") }; return try run(a) }
    func branches(all: Bool = false) throws -> String { try run(all ? ["branch", "-a", "-v"] : ["branch", "-v"]) }
    func createBranch(_ name: String, checkout: Bool = true) throws -> String { try run(checkout ? ["checkout", "-b", name] : ["branch", name]) }
    func deleteBranch(_ name: String, force: Bool = false) throws -> String { try run(["branch", force ? "-D" : "-d", name]) }
    func log(count: Int = 10, format: String = "%h|%s|%an|%ar") throws -> String { try run(["log", "--format=\(format)", "-n", "\(count)"]) }
    func tags() throws -> String { try run(["tag", "-l", "--sort=-v:refname"]) }
    func logRange(from: String, to: String = "HEAD", format: String = "%h|%s|%an|%ar") throws -> String { try run(["log", "\(from)..\(to)", "--format=\(format)"]) }
    func push(r: String = "origin", b: String? = nil) throws -> String { var a = ["push", r]; if let b = b { a.append(b) }; return try run(a) }
    func pull(r: String = "origin", b: String? = nil) throws -> String { var a = ["pull", r]; if let b = b { a.append(b) }; return try run(a) }
    func fetch(r: String = "--all") throws -> String { try run(["fetch", r]) }
    func reset(mode: String = "--soft", count: Int = 1) throws -> String { try run(["reset", mode, "HEAD~\(count)"]) }
    func resetHard(count: Int = 1) throws -> String { try run(["reset", "--hard", "HEAD~\(count)"]) }
    func remoteURL(n: String = "origin") throws -> String { try run(["remote", "get-url", n]) }
    func contributors() throws -> String { try run(["shortlog", "-sne"]) }
    func stashList() throws -> String { try run(["stash", "list"]) }
}
