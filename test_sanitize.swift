import Foundation

let invalidChars = CharacterSet(charactersIn: ":/\\?%*|\"<>")
let title = "Hello World Test"
let cleaned = title.components(separatedBy: invalidChars).joined(separator: "_")
print("Original: \"\(title)\"")
print("Cleaned: \"\(cleaned)\"")
print("Components: \(title.components(separatedBy: invalidChars))")

let title2 = "Test Note"
let cleaned2 = title2.components(separatedBy: invalidChars).joined(separator: "_")
print("Original2: \"\(title2)\"")
print("Cleaned2: \"\(cleaned2)\"")
print("Components2: \(title2.components(separatedBy: invalidChars))") 