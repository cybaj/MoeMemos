//
//  MemoCard.swift
//  MoeMemos
//
//  Created by Mudkip on 2022/9/4.
//

import SwiftUI
import UniformTypeIdentifiers

struct MemoCard: View {
    let memo: Memo
    
    @EnvironmentObject private var memosViewModel: MemosViewModel
    @State private var showingEdit = false
    @State private var showingShareSheet = false
    @State private var showingDeleteConfirmation = false
    
    init(_ memo: Memo) {
        self.memo = memo
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(renderTime())
                    .font(.footnote)
                    .foregroundColor(.secondary)
                
                if memo.pinned {
                    Image(systemName: "flag.fill")
                        .renderingMode(.original)
                }
                
                Spacer()
                
                Menu {
                    if memo.rowStatus == .archived {
                        archivedMenu()
                    } else {
                        normalMenu()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .padding([.leading, .top, .bottom], 10)
                }
            }
            
            Text(renderContent())
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contextMenu {
            Button {
                UIPasteboard.general.setValue(memo.content, forPasteboardType: UTType.plainText.identifier)
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
        }
        .padding([.top, .bottom], 5)
        .sheet(isPresented: $showingEdit) {
            MemoInput(memo: memo)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [memo.content])
        }
        .confirmationDialog("Delete this memo?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Yes", role: .destructive) {
                Task {
                    try await memosViewModel.deleteMemo(id: memo.id)
                }
            }
            Button("No", role: .cancel) {}
        }
    }
    
    @ViewBuilder
    private func normalMenu() -> some View {
        Button {
            Task {
                do {
                    try await memosViewModel.updateMemoOrganizer(id: memo.id, pinned: !memo.pinned)
                } catch {
                    print(error)
                }
            }
        } label: {
            if memo.pinned {
                Label("Unpin", systemImage: "flag.slash")
            } else {
                Label("Pin", systemImage: "flag")
            }
        }
        Button {
            showingEdit = true
        } label: {
            Label("Edit", systemImage: "pencil")
        }
        Button {
            showingShareSheet = true
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        Button(role: .destructive, action: {
            Task {
                do {
                    try await memosViewModel.archiveMemo(id: memo.id)
                } catch {
                    print(error)
                }
            }
        }, label: {
            Label("Archive", systemImage: "archivebox")
        })
    }
    
    @ViewBuilder
    private func archivedMenu() -> some View {
        Button {
            Task {
                do {
                    try await memosViewModel.restoreMemo(id: memo.id)
                } catch {
                    print(error)
                }
            }
        } label: {
            Label("Restore", systemImage: "tray.and.arrow.up")
        }
        Button(role: .destructive, action: {
            showingDeleteConfirmation = true
        }, label: {
            Label("Delete", systemImage: "trash")
        })
    }
    
    private func renderTime() -> String {
        if Calendar.current.dateComponents([.day], from: memo.createdTs, to: .now).day! > 7 {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            formatter.timeStyle = .short
            return formatter.string(from: memo.createdTs)
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: memo.createdTs, relativeTo: .now)
    }
    
    private func renderContent() -> AttributedString {
        do {
            return try AttributedString(markdown: memo.content, options: AttributedString.MarkdownParsingOptions(
                    allowsExtendedAttributes: true,
                    interpretedSyntax: .inlineOnlyPreservingWhitespace))
            
        } catch {
            return AttributedString(memo.content)
        }
    }
}

struct MemoCard_Previews: PreviewProvider {
    static var previews: some View {
        MemoCard(Memo(id: 1, createdTs: .now.addingTimeInterval(-100), creatorId: 1, content: "Hello world\n\nThis is a **multiline** statement and thank you for everything.", pinned: false, rowStatus: .normal, updatedTs: .now, visibility: .private))
            .environmentObject(MemosViewModel())
    }
}