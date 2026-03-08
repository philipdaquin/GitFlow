//
//  main.swift
//  GitFlow
//

import Foundation

@main
struct GitFlowMain {
    static func main() {
        let args = Array(CommandLine.arguments.dropFirst())
        guard let command = args.first else { printUsage(); exit(0) }
        do {
            let result = try runCommand(command, args: Array(args.dropFirst()))
            print(result)
            exit(0)
        } catch let error as GitFlowError {
            eprint("Error: \(error.message)"); exit(error.code)
        } catch { eprint("Error: \(error.localizedDescription)"); exit(1) }
    }
    
    static func printUsage() {
        print("""
        GitFlow - A modern CLI for Git workflows
        Usage: gitflow <command> [options]
        Commands: commit, branch, changelog, undo, stash, sync, info, config, help
        """)
    }
    
    static func runCommand(_ command: String, args: [String]) throws -> String {
        let git = Git()
        switch command {
        case "commit": return try CommitCommand(git: git).run(args: args)
        case "branch", "branches": return try BranchCommand(git: git).run(args: args)
        case "changelog", "log": return try ChangelogCommand(git: git).run(args: args)
        case "undo": return try UndoCommand(git: git).run(args: args)
        case "stash": return try StashCommand(git: git).run(args: args)
        case "sync": return try SyncCommand(git: git).run(args: args)
        case "info": return try InfoCommand(git: git).run(args: args)
        case "config": return try ConfigCommand().run(args: args)
        case "help", "--help", "-h": printUsage(); return ""
        default: throw GitFlowError(message: "Unknown command: \(command)", code: 2)
        }
    }
}

struct GitFlowError: Error {
    let message: String
    let code: Int
    init(message: String, code: Int = 1) { self.message = message; self.code = code }
}

func eprint(_ s: String) { FileHandle.standardError.write((s + "\n").data(using: .utf8)!) }
