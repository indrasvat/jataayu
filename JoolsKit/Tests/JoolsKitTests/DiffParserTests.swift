import Testing
import Foundation
@testable import JoolsKit

@Suite("DiffParser Tests")
struct DiffParserTests {
    @Test("Parses a simple modified file")
    func parsesSimpleModification() {
        let patch = """
        diff --git a/src/foo.swift b/src/foo.swift
        index 0000001..0000002 100644
        --- a/src/foo.swift
        +++ b/src/foo.swift
        @@ -1,3 +1,4 @@
         line one
        -removed line
        +added line
        +another addition
         line three
        """

        let files = UnifiedDiffParser.parse(patch)
        #expect(files.count == 1)
        let file = files[0]
        #expect(file.path == "src/foo.swift")
        #expect(file.oldPath == "src/foo.swift")
        #expect(file.kind == .modified)
        #expect(file.additions == 2)
        #expect(file.deletions == 1)
        #expect(file.hunks.count == 1)

        let hunk = file.hunks[0]
        #expect(hunk.oldStart == 1)
        #expect(hunk.oldCount == 3)
        #expect(hunk.newStart == 1)
        #expect(hunk.newCount == 4)

        let kinds = hunk.lines.map(\.kind)
        #expect(kinds == [.context, .deletion, .addition, .addition, .context])
    }

    @Test("Parses an added file (---/dev/null)")
    func parsesAddedFile() {
        let patch = """
        diff --git a/src/new.swift b/src/new.swift
        new file mode 100644
        --- /dev/null
        +++ b/src/new.swift
        @@ -0,0 +1,2 @@
        +import Foundation
        +let x = 1
        """

        let files = UnifiedDiffParser.parse(patch)
        #expect(files.count == 1)
        #expect(files[0].kind == .added)
        #expect(files[0].path == "src/new.swift")
        #expect(files[0].additions == 2)
        #expect(files[0].deletions == 0)
    }

    @Test("Parses a removed file (+++/dev/null)")
    func parsesRemovedFile() {
        let patch = """
        diff --git a/src/old.swift b/src/old.swift
        deleted file mode 100644
        --- a/src/old.swift
        +++ /dev/null
        @@ -1,2 +0,0 @@
        -line one
        -line two
        """

        let files = UnifiedDiffParser.parse(patch)
        #expect(files.count == 1)
        #expect(files[0].kind == .removed)
        #expect(files[0].deletions == 2)
        #expect(files[0].additions == 0)
    }

    @Test("Parses multiple files in a single patch")
    func parsesMultipleFiles() {
        let patch = """
        diff --git a/a.txt b/a.txt
        --- a/a.txt
        +++ b/a.txt
        @@ -1,1 +1,1 @@
        -alpha
        +ALPHA
        diff --git a/b.txt b/b.txt
        --- a/b.txt
        +++ b/b.txt
        @@ -1,1 +1,2 @@
         beta
        +gamma
        """

        let files = UnifiedDiffParser.parse(patch)
        #expect(files.count == 2)
        #expect(files[0].path == "a.txt")
        #expect(files[1].path == "b.txt")
        #expect(files[0].additions == 1)
        #expect(files[0].deletions == 1)
        #expect(files[1].additions == 1)
        #expect(files[1].deletions == 0)
    }

    @Test("Tracks line numbers correctly across context, additions, and deletions")
    func tracksLineNumbers() {
        let patch = """
        diff --git a/x.swift b/x.swift
        --- a/x.swift
        +++ b/x.swift
        @@ -10,4 +10,5 @@
         keep one
        -remove me
        +new line
        +another
         keep two
        """

        let files = UnifiedDiffParser.parse(patch)
        let lines = files[0].hunks[0].lines

        // First context line: old=10, new=10
        #expect(lines[0].oldLineNumber == 10)
        #expect(lines[0].newLineNumber == 10)
        // Deletion: old=11, new=nil
        #expect(lines[1].oldLineNumber == 11)
        #expect(lines[1].newLineNumber == nil)
        // First addition: old=nil, new=11
        #expect(lines[2].oldLineNumber == nil)
        #expect(lines[2].newLineNumber == 11)
        // Second addition: old=nil, new=12
        #expect(lines[3].oldLineNumber == nil)
        #expect(lines[3].newLineNumber == 12)
        // Final context: old=12, new=13
        #expect(lines[4].oldLineNumber == 12)
        #expect(lines[4].newLineNumber == 13)
    }

    @Test("Handles empty patch gracefully")
    func handlesEmptyPatch() {
        #expect(UnifiedDiffParser.parse("").isEmpty)
    }

    @Test("Skips no-newline-at-end-of-file markers")
    func skipsNoNewlineMarkers() {
        let patch = """
        diff --git a/f.txt b/f.txt
        --- a/f.txt
        +++ b/f.txt
        @@ -1,1 +1,1 @@
        -old
        \\ No newline at end of file
        +new
        \\ No newline at end of file
        """

        let files = UnifiedDiffParser.parse(patch)
        #expect(files.count == 1)
        let lines = files[0].hunks[0].lines
        #expect(lines.count == 2)
        #expect(lines.map(\.kind) == [.deletion, .addition])
    }
}
