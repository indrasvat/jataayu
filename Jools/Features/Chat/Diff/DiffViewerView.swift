import SwiftUI
import JoolsKit

/// Phone-friendly diff viewer for a parsed unified-diff blob.
///
/// Lists every changed file with its `+/-` counts at the top, and
/// renders each hunk inline with line numbers and red/green styling.
/// Each file row is collapsible (expanded by default for the first
/// few files, collapsed for everything past the threshold so the
/// initial paint stays cheap on large diffs).
struct DiffViewerView: View {
    let title: String
    let files: [DiffFile]

    @State private var collapsedFiles: Set<String>
    @Environment(\.dismiss) private var dismiss

    private static let initiallyExpandedCount = 3

    init(title: String, files: [DiffFile]) {
        self.title = title
        self.files = files
        // Collapse everything past the first N files to keep the
        // initial paint snappy on large completion diffs.
        let initialCollapsed = files
            .dropFirst(Self.initiallyExpandedCount)
            .map(\.path)
        _collapsedFiles = State(initialValue: Set(initialCollapsed))
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: JoolsSpacing.md) {
                summaryHeader

                ForEach(files) { file in
                    DiffFileSection(
                        file: file,
                        isCollapsed: collapsedFiles.contains(file.path),
                        onToggle: { toggle(file.path) }
                    )
                    .id(file.id)
                    .accessibilityIdentifier("diff.file.\(file.path)")
                }
            }
            .padding()
        }
        .background(Color.joolsBackground)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Expand all") { collapsedFiles.removeAll() }
                    Button("Collapse all") {
                        collapsedFiles = Set(files.map(\.path))
                    }
                } label: {
                    Image(systemName: "arrow.up.and.down.text.horizontal")
                }
                .accessibilityIdentifier("diff.expandMenu")
            }
        }
    }

    private var summaryHeader: some View {
        HStack(spacing: JoolsSpacing.sm) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.title3)
                .foregroundStyle(Color.joolsAccent)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(files.count) \(files.count == 1 ? "file" : "files") changed")
                    .font(.joolsHeadline)
                HStack(spacing: JoolsSpacing.xs) {
                    Text("+\(totalAdditions)")
                        .foregroundStyle(Color.joolsSuccess)
                        .fontWeight(.semibold)
                    Text("-\(totalDeletions)")
                        .foregroundStyle(Color.joolsError)
                        .fontWeight(.semibold)
                }
                .font(.joolsCaption)
            }

            Spacer()
        }
        .padding()
        .background(Color.joolsSurface)
        .clipShape(RoundedRectangle(cornerRadius: JoolsRadius.md))
    }

    private var totalAdditions: Int {
        files.reduce(0) { $0 + $1.additions }
    }

    private var totalDeletions: Int {
        files.reduce(0) { $0 + $1.deletions }
    }

    private func toggle(_ path: String) {
        if collapsedFiles.contains(path) {
            collapsedFiles.remove(path)
        } else {
            collapsedFiles.insert(path)
        }
    }
}

// MARK: - File section

private struct DiffFileSection: View {
    let file: DiffFile
    let isCollapsed: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if !isCollapsed {
                Divider()
                if file.isBinary {
                    Text("Binary file — content not shown.")
                        .font(.joolsCaption)
                        .foregroundStyle(.secondary)
                        .padding(JoolsSpacing.md)
                } else if file.hunks.isEmpty {
                    Text("No textual changes.")
                        .font(.joolsCaption)
                        .foregroundStyle(.secondary)
                        .padding(JoolsSpacing.md)
                } else {
                    ForEach(file.hunks) { hunk in
                        DiffHunkView(hunk: hunk)
                    }
                }
            }
        }
        .background(Color.joolsSurface)
        .clipShape(RoundedRectangle(cornerRadius: JoolsRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: JoolsRadius.md)
                .stroke(Color.joolsSurfaceElevated, lineWidth: 1)
        )
    }

    private var header: some View {
        Button(action: onToggle) {
            HStack(spacing: JoolsSpacing.sm) {
                Image(systemName: kindIcon)
                    .foregroundStyle(kindColor)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(file.path)
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if case .renamed(let from) = file.kind {
                        Text("renamed from \(from)")
                            .font(.joolsCaption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                HStack(spacing: JoolsSpacing.xs) {
                    Text("+\(file.additions)")
                        .foregroundStyle(Color.joolsSuccess)
                    Text("-\(file.deletions)")
                        .foregroundStyle(Color.joolsError)
                }
                .font(.joolsCaption.weight(.semibold))

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(isCollapsed ? 0 : 90))
            }
            .padding(JoolsSpacing.md)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("diff.file.toggle.\(file.path)")
    }

    private var kindIcon: String {
        switch file.kind {
        case .modified: return "pencil"
        case .added: return "plus.circle"
        case .removed: return "minus.circle"
        case .renamed: return "arrow.right"
        }
    }

    private var kindColor: Color {
        switch file.kind {
        case .modified: return Color.joolsAccent
        case .added: return Color.joolsSuccess
        case .removed: return Color.joolsError
        case .renamed: return Color.joolsAccent
        }
    }
}

// MARK: - Hunk

private struct DiffHunkView: View {
    let hunk: DiffHunk

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hunk header — gray pill that anchors the new line
            // numbers, similar to GitHub's compact diff view. Stays
            // pinned (doesn't scroll horizontally with the lines below).
            Text(hunk.header)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(.horizontal, JoolsSpacing.md)
                .padding(.vertical, JoolsSpacing.xxs)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.joolsSurfaceElevated)

            // Horizontally scrollable hunk body so long source lines
            // get a single visual row each (matching the line numbers
            // 1:1) instead of wrapping. CodeRabbit P1 review feedback.
            ScrollView(.horizontal, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(hunk.lines) { line in
                        DiffLineRow(line: line)
                    }
                }
            }
        }
    }
}

private struct DiffLineRow: View {
    let line: DiffLine

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            lineNumberCell(line.oldLineNumber)
                .foregroundStyle(.tertiary)
            lineNumberCell(line.newLineNumber)
                .foregroundStyle(.tertiary)

            // Single visual row per diff line — never wrap. The parent
            // ScrollView lets long lines scroll horizontally instead,
            // preserving the 1:1 mapping between source lines and
            // visible rows that diff readers rely on.
            Text(prefix + line.content)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(textColor)
                .lineLimit(1)
                .padding(.vertical, 2)
                .padding(.leading, JoolsSpacing.xs)
                .padding(.trailing, JoolsSpacing.md)
                .fixedSize(horizontal: true, vertical: false)
        }
        .background(rowBackground)
    }

    private func lineNumberCell(_ number: Int?) -> some View {
        Text(number.map(String.init) ?? "")
            .font(.system(.caption2, design: .monospaced))
            .frame(width: 36, alignment: .trailing)
            .padding(.vertical, 2)
            .padding(.horizontal, 4)
    }

    private var prefix: String {
        switch line.kind {
        case .addition: return "+"
        case .deletion: return "-"
        case .context, .header: return " "
        }
    }

    private var textColor: Color {
        switch line.kind {
        case .addition: return Color.joolsSuccess
        case .deletion: return Color.joolsError
        case .context, .header: return .primary
        }
    }

    private var rowBackground: Color {
        switch line.kind {
        case .addition: return Color.joolsSuccess.opacity(0.10)
        case .deletion: return Color.joolsError.opacity(0.10)
        case .context, .header: return .clear
        }
    }
}

// MARK: - Preview

#Preview("Diff Viewer") {
    NavigationStack {
        DiffViewerView(
            title: "Sample diff",
            files: UnifiedDiffParser.parse(
                """
                diff --git a/src/foo.swift b/src/foo.swift
                --- a/src/foo.swift
                +++ b/src/foo.swift
                @@ -1,4 +1,5 @@
                 import Foundation
                -let greeting = "hi"
                +let greeting = "hello"
                +let greetingLoud = greeting.uppercased()
                 print(greeting)
                """
            )
        )
    }
}
