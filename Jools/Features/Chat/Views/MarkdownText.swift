import SwiftUI
import JoolsKit
import Markdown

// MARK: - Markdown rendering for agent messages
//
// Jules emits structured GitHub-flavored markdown in agent messages —
// `**bold**`, `*italic*`, inline `code`, fenced code blocks, ordered
// and unordered lists, headings, blockquotes, links. Without a
// renderer the chat view shows the raw markdown source verbatim,
// which looks broken next to a visually-rich web client.
//
// `MarkdownText` is a small Swift-Markdown-backed renderer purpose-
// built for the chat surface:
//
//   - Inline runs (text, strong, emphasis, code, link) collapse into
//     a single SwiftUI `Text` via `AttributedString` so they wrap and
//     hyphenate naturally inside chat bubbles.
//   - Block-level elements (paragraphs, lists, code blocks, headings,
//     thematic breaks, blockquotes) render as a vertical stack of
//     SwiftUI views with consistent spacing.
//   - Fenced code blocks get a monospaced rounded surface — exactly
//     the affordance you'd expect for "this is code, don't try to
//     read it as prose".
//   - Unknown nodes degrade to plain text rather than dropping
//     content silently.
//
// We deliberately keep the renderer self-contained — no styling
// configuration, no theming knobs — so chat agent bubbles can drop
// it in as a one-liner replacement for the bare `Text(content)`
// they were using before.

/// Renders a markdown string as a SwiftUI view, walking the
/// swift-markdown AST and emitting per-block subviews.
///
/// Parsed `Document` instances are memoized in a process-wide
/// `NSCache` keyed by the markdown source string. Without this
/// cache, every re-render of the chat (which happens often — every
/// poll tick, every `@Query` update, every syncState change) would
/// re-parse every visible agent bubble's markdown on the main
/// thread. For a session with N agent messages and a chat that
/// scrolls / re-lays-out frequently, that's an O(N) main-thread
/// hit per render which manifested as the "new repoless session
/// freeze" symptom on top of the polling-task-chain fixes from
/// commit 1b2e190. The cache lives for the app lifetime and is
/// bounded by NSCache's default policy.
struct MarkdownText: View {
    let markdown: String

    init(_ markdown: String) {
        self.markdown = markdown
    }

    var body: some View {
        let document = MarkdownDocumentCache.shared.document(for: markdown)
        VStack(alignment: .leading, spacing: JoolsSpacing.sm) {
            ForEach(Array(document.blockChildren.enumerated()), id: \.offset) { _, block in
                MarkdownBlockView(block: block)
            }
        }
    }
}

/// Process-wide LRU cache for parsed `Markdown.Document` instances.
///
/// Keyed on the markdown source string identity. Each unique agent
/// message contributes one entry; the cache is bounded by NSCache's
/// default cost-based eviction so it never grows unbounded across
/// long sessions. Reads are thread-safe; writes from multiple
/// threads are serialized internally by NSCache.
final class MarkdownDocumentCache: @unchecked Sendable {
    // `@unchecked Sendable` is correct here: NSCache itself is
    // documented as thread-safe (Apple guarantees concurrent
    // get/set are safe), and the only mutable state is held inside
    // it. The cache stores `DocumentBox` reference types whose
    // `document` property is set once at init and never mutated,
    // so cross-thread reads of an entry are also safe.
    static let shared = MarkdownDocumentCache()

    private let cache: NSCache<NSString, DocumentBox> = {
        let cache = NSCache<NSString, DocumentBox>()
        cache.countLimit = 256
        return cache
    }()

    func document(for markdown: String) -> Document {
        let key = markdown as NSString
        if let cached = cache.object(forKey: key) {
            return cached.document
        }
        let parsed = Document(parsing: markdown, options: [.parseBlockDirectives])
        cache.setObject(DocumentBox(parsed), forKey: key)
        return parsed
    }

    /// NSCache requires `AnyObject` values, so wrap the value-type
    /// `Document` in a small reference box.
    private final class DocumentBox {
        let document: Document
        init(_ document: Document) { self.document = document }
    }
}

// MARK: - Block dispatcher

private struct MarkdownBlockView: View {
    let block: any BlockMarkup

    var body: some View {
        switch block {
        case let paragraph as Paragraph:
            ParagraphView(paragraph: paragraph)

        case let heading as Heading:
            HeadingView(heading: heading)

        case let unordered as UnorderedList:
            ListView(items: Array(unordered.listItems), ordered: false)

        case let ordered as OrderedList:
            ListView(items: Array(ordered.listItems), ordered: true)

        case let codeBlock as CodeBlock:
            CodeBlockView(code: codeBlock.code, language: codeBlock.language)

        case let blockQuote as BlockQuote:
            BlockQuoteView(blockQuote: blockQuote)

        case let table as Markdown.Table:
            TableView(table: table)

        case is ThematicBreak:
            Divider()

        default:
            // Fallback: render the inline children if we can, otherwise
            // dump the plain text. We never want to silently drop
            // content the user authored.
            Text(block.format())
                .font(.joolsBody)
        }
    }
}

// MARK: - Paragraph

private struct ParagraphView: View {
    let paragraph: Paragraph

    var body: some View {
        Text(InlineAttributedStringBuilder.build(from: paragraph))
            .font(.joolsBody)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Heading

private struct HeadingView: View {
    let heading: Heading

    var body: some View {
        Text(InlineAttributedStringBuilder.build(from: heading))
            .font(font(for: heading.level))
            .fontWeight(.semibold)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, heading.level <= 2 ? JoolsSpacing.xs : 0)
    }

    private func font(for level: Int) -> Font {
        switch level {
        case 1: return .system(.title2, design: .default).weight(.bold)
        case 2: return .system(.title3, design: .default).weight(.bold)
        case 3: return .system(.headline, design: .default).weight(.semibold)
        default: return .system(.subheadline, design: .default).weight(.semibold)
        }
    }
}

// MARK: - Lists

private struct ListView: View {
    let items: [ListItem]
    let ordered: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: JoolsSpacing.xs) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                ListItemView(
                    item: item,
                    bullet: ordered ? "\(index + 1)." : "•"
                )
            }
        }
    }
}

private struct ListItemView: View {
    let item: ListItem
    let bullet: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: JoolsSpacing.xs) {
            Text(bullet)
                .font(.joolsBody.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(minWidth: 18, alignment: .trailing)

            VStack(alignment: .leading, spacing: JoolsSpacing.xxs) {
                ForEach(Array(item.blockChildren.enumerated()), id: \.offset) { _, block in
                    MarkdownBlockView(block: block)
                }
            }
        }
    }
}

// MARK: - Code block

private struct CodeBlockView: View {
    let code: String
    let language: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let language, !language.isEmpty {
                Text(language)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, JoolsSpacing.sm)
                    .padding(.top, JoolsSpacing.xs)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                Text(code.hasSuffix("\n") ? String(code.dropLast()) : code)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.primary)
                    .padding(JoolsSpacing.sm)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.joolsSurfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: JoolsRadius.sm))
    }
}

// MARK: - Block quote

private struct BlockQuoteView: View {
    let blockQuote: BlockQuote

    var body: some View {
        HStack(alignment: .top, spacing: JoolsSpacing.sm) {
            Rectangle()
                .fill(Color.joolsAccent.opacity(0.4))
                .frame(width: 3)

            VStack(alignment: .leading, spacing: JoolsSpacing.xs) {
                ForEach(Array(blockQuote.blockChildren.enumerated()), id: \.offset) { _, block in
                    MarkdownBlockView(block: block)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Table
//
// Jules frequently emits results as GitHub-flavored markdown tables
// (e.g. "list the top 3 repos in a markdown table"). swift-markdown
// parses these into `Markdown.Table` with a `head` row and a `body`
// of rows. Without an explicit handler the block dispatcher would
// fall through to `block.format()` and dump the raw markdown source
// (`| col | col |\n|---|---|\n| a | b |`) into the chat bubble.
//
// We render tables as a horizontally-scrollable column-stack of
// cells: each column is a vertical pile of `Text` runs (header on
// top, body cells below), with a separator strip after the header.
// SwiftUI's `Grid` would be ideal here but its sizing model doesn't
// play nicely with the chat bubble's `fixedSize(horizontal: false,
// vertical: true)` because Grid wants intrinsic widths from every
// child up front. The HStack-of-VStacks approach measures each
// column independently and lets the bubble flow naturally.

private struct TableView: View {
    let table: Markdown.Table

    var body: some View {
        let columnCount = computedColumnCount
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 0) {
                ForEach(0..<columnCount, id: \.self) { columnIndex in
                    columnView(at: columnIndex)
                    if columnIndex < columnCount - 1 {
                        Divider()
                    }
                }
            }
            .background(Color.joolsSurfaceElevated.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: JoolsRadius.sm))
            .overlay(
                RoundedRectangle(cornerRadius: JoolsRadius.sm)
                    .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
            )
        }
    }

    /// Tables can technically have rows of different widths in
    /// markdown, so take the maximum cell count across head + body
    /// rather than trusting any single row.
    private var computedColumnCount: Int {
        var maxCount = Array(table.head.cells).count
        for row in table.body.rows {
            maxCount = max(maxCount, Array(row.cells).count)
        }
        return maxCount
    }

    private func columnView(at columnIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header cell
            cellText(headerCell(at: columnIndex), isHeader: true)

            Divider()

            // Body cells
            ForEach(Array(table.body.rows.enumerated()), id: \.offset) { rowIndex, row in
                let cells = Array(row.cells)
                let cell: Markdown.Table.Cell? = columnIndex < cells.count ? cells[columnIndex] : nil
                cellText(cell, isHeader: false)

                if rowIndex < Array(table.body.rows).count - 1 {
                    Divider().opacity(0.4)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func headerCell(at columnIndex: Int) -> Markdown.Table.Cell? {
        let cells = Array(table.head.cells)
        guard columnIndex < cells.count else { return nil }
        return cells[columnIndex]
    }

    @ViewBuilder
    private func cellText(_ cell: Markdown.Table.Cell?, isHeader: Bool) -> some View {
        let attributed = cell.map { InlineAttributedStringBuilder.build(from: $0) } ?? AttributedString("")
        Text(attributed)
            .font(isHeader ? .joolsBody.weight(.semibold) : .joolsBody)
            .padding(.horizontal, JoolsSpacing.sm)
            .padding(.vertical, JoolsSpacing.xs)
            .frame(minWidth: 60, alignment: .leading)
    }
}

// MARK: - Inline → AttributedString

/// Walks an inline-bearing block and produces a SwiftUI-compatible
/// `AttributedString` covering the spans we care about: bold, italic,
/// inline code, links, soft and hard line breaks, plain runs.
///
/// Style is threaded through the recursion via `InlineStyle` so that
/// nested spans compose correctly — e.g. `**bold _and italic_**`
/// ends up bold+italic, not just bold. An earlier version set
/// `inner.font = ...` on the whole inner string after recursing,
/// which silently clobbered whatever children had already applied
/// (the inner italic ran was re-fonted to the outer bold and lost
/// its italic trait). (CodeRabbit review.)
enum InlineAttributedStringBuilder {
    /// Which traits are currently active on the recursion path.
    /// Kept as a value type so children get a copy they can layer
    /// new traits onto without affecting siblings.
    fileprivate struct InlineStyle {
        var bold: Bool = false
        var italic: Bool = false
        var strikethrough: Bool = false
        var link: URL?

        /// Build the SwiftUI `Font` that represents this style stack.
        /// The base is always `.body` (matching `.joolsBody`'s size);
        /// bold and italic compose via the Font trait modifiers.
        var font: Font {
            var font: Font = .system(.body)
            if italic {
                font = font.italic()
            }
            if bold {
                font = font.weight(.semibold)
            }
            return font
        }
    }

    static func build(from block: any BlockMarkup) -> AttributedString {
        build(fromChildren: block.children)
    }

    /// Overload for non-BlockMarkup containers like `Markdown.Table.Cell`
    /// (which inherits `Markup` but not `BlockMarkup`). The chat
    /// table renderer needs to walk a cell's inline children to
    /// produce a styled `AttributedString` for that cell, and the
    /// `Markup` protocol exposes the same `children` sequence we
    /// already use elsewhere.
    static func build(from markup: Markup) -> AttributedString {
        build(fromChildren: markup.children)
    }

    private static func build(fromChildren children: MarkupChildren) -> AttributedString {
        var result = AttributedString()
        for child in children {
            append(child, into: &result, style: InlineStyle())
        }
        return result
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private static func append(
        _ markup: Markup,
        into output: inout AttributedString,
        style: InlineStyle
    ) {
        switch markup {
        case let text as Markdown.Text:
            var run = AttributedString(text.string)
            applyStyle(style, to: &run)
            output.append(run)

        case let strong as Strong:
            var nextStyle = style
            nextStyle.bold = true
            for child in strong.children {
                append(child, into: &output, style: nextStyle)
            }

        case let emphasis as Emphasis:
            var nextStyle = style
            nextStyle.italic = true
            for child in emphasis.children {
                append(child, into: &output, style: nextStyle)
            }

        case let inlineCode as InlineCode:
            // Inline code is the one span where we DON'T inherit the
            // surrounding font — `**`bold`**` should stay monospaced
            // regardless, because that's what makes it look like code.
            // We still carry link / strikethrough through.
            var run = AttributedString(inlineCode.code)
            run.font = .system(.body, design: .monospaced)
            run.backgroundColor = Color.joolsSurfaceElevated
            if style.strikethrough {
                run.strikethroughStyle = .single
            }
            if let url = style.link {
                run.link = url
                run.foregroundColor = Color.joolsAccent
                run.underlineStyle = .single
            }
            output.append(run)

        case let link as Markdown.Link:
            var nextStyle = style
            if let destination = link.destination, let url = URL(string: destination) {
                nextStyle.link = url
            }
            for child in link.children {
                append(child, into: &output, style: nextStyle)
            }

        case is LineBreak:
            output.append(AttributedString("\n"))

        case is SoftBreak:
            output.append(AttributedString(" "))

        case let strikethrough as Strikethrough:
            var nextStyle = style
            nextStyle.strikethrough = true
            for child in strikethrough.children {
                append(child, into: &output, style: nextStyle)
            }

        case let image as Markdown.Image:
            // We don't render images inline in the chat (would need
            // network fetches and layout pinning we don't want here).
            // Substitute the alt text so the user still has context.
            let alt = image.children
                .compactMap { ($0 as? Markdown.Text)?.string }
                .joined()
            if !alt.isEmpty {
                var run = AttributedString("[image: \(alt)]")
                run.foregroundColor = Color.secondary
                output.append(run)
            }

        default:
            // Unknown inline node — fall back to its plain text format
            // so we don't drop authored content.
            var run = AttributedString(markup.format())
            applyStyle(style, to: &run)
            output.append(run)
        }
    }

    /// Apply the current `InlineStyle` to a freshly-created run. Kept
    /// as a helper so Strong/Emphasis/Strikethrough/Link all converge
    /// on the same attribute-writing logic.
    private static func applyStyle(_ style: InlineStyle, to run: inout AttributedString) {
        run.font = style.font
        if style.strikethrough {
            run.strikethroughStyle = .single
        }
        if let url = style.link {
            run.link = url
            run.foregroundColor = Color.joolsAccent
            run.underlineStyle = .single
        }
    }
}

#Preview("Markdown sample") {
    ScrollView {
        MarkdownText(
            """
            # Top-level heading

            Here is a paragraph with **bold**, *italic*, and `inline code`. \
            And a [link to Apple](https://apple.com).

            ## Findings

            * **Data Isolation:** Actors automatically isolate their mutable state.
            * **Asynchronous Access:** Interacting requires `await`.
            * **No Inheritance:** Actors do not support inheritance.

            1. First step
            2. Second step
            3. Third step

            ```swift
            actor Counter {
                private var value = 0
                func increment() { value += 1 }
            }
            ```

            > A blockquote with some context.
            """
        )
        .padding()
    }
}
