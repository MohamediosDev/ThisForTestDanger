import Danger 
import Foundation
import DangerSwiftCoverage

let danger = Danger()
let editedFiles = danger.git.modifiedFiles + danger.git.createdFiles

// 1. Big PR warning
if editedFiles.count - danger.git.deletedFiles.count > 300 {
    warn("Big PR, try to keep changes smaller if you can")
}

// 2. PR Description Warning
let body = danger.github.pullRequest.body?.count ?? 0
let linesOfCode = danger.github.pullRequest.additions ?? 0
if body < 3 && linesOfCode > 10 {
    warn("Please provide a summary in the Pull Request description")
}

// 3. Large PR changes warning
let additions = danger.github.pullRequest.additions ?? 0
let deletions = danger.github.pullRequest.deletions ?? 0
let totalChanges = additions + deletions

if totalChanges > 500 {
    warn("Large PR with over 500 lines changed. Consider breaking it down into smaller PRs.")
}

// 4. Special check for important files
let importantFiles = editedFiles.filter { $0.contains("Config.swift") || $0.contains(".env") }

if !importantFiles.isEmpty {
    warn("You have modified configuration files. Please ensure they are reviewed carefully.")
}

// 5. WIP Warning
if danger.github != nil {
    if danger.github.pullRequest.title.contains("WIP") {
        warn("PR is classed as Work in Progress")
    }
}

// 6. Run SwiftLint only on Swift files
let swiftFiles = editedFiles.filter { $0.hasSuffix(".swift") }

if !swiftFiles.isEmpty {
    print("Running SwiftLint on changed Swift files...")
    SwiftLint.lint(.files(swiftFiles), inline: true, strict: true, quiet: false)
}

// 7. Code coverage check
func checkCodeCoverage(filePath: String, threshold: Double) {
    guard let data = FileManager.default.contents(atPath: filePath),
          let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
          let coverage = json["coverage"] as? Double else {
        warn("Could not retrieve code coverage data.")
        return
    }
    
    if coverage < threshold {
        warn("Code coverage is below the acceptable threshold (\(threshold)%) at \(coverage)%")
    } else {
        message("Code coverage is good at \(coverage)%")
    }
}

// Example path to coverage file and coverage threshold
let coverageFilePath = "path/to/coverage.json"
let coverageThreshold = 80.0

checkCodeCoverage(filePath: coverageFilePath, threshold: coverageThreshold)
let report = XCodeSummary(filePath: "result.json")
report.report()

Coverage.xcodeBuildCoverage(.derivedDataFolder("build"), minimumCoverage: 50, excludedTargets: ["DangerSwiftCoverageTests.xctest"])
