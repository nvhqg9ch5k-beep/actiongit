import SwiftUI
import CoreData
import PDFKit
import UIKit

struct ExportRitualBookView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MoneyRitual.createdAt, ascending: false)],
        animation: .default
    ) private var rituals: FetchedResults<MoneyRitual>
    
    @State private var showingShareSheet = false
    @State private var pdfURL: URL?
    
    var body: some View {
        NavigationStack {
            ZStack {
                RitualTheme.warmIvory(colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: RitualTheme.padding) {
                        Text("Export & Ritual Book")
                            .font(RitualTheme.ritualTitleFont)
                            .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, RitualTheme.padding)
                            .padding(.top, 20)
                        
                        Text("This is a private personal habit and ritual journal. Not financial advice or spiritual guidance.")
                            .font(.system(size: 11))
                            .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme).opacity(0.5))
                            .padding(.horizontal, RitualTheme.padding)
                        
                        // Export options
                        VStack(spacing: 16) {
                            ExportOptionCard(
                                title: "Export PDF Book",
                                description: "Create a ceremonial book of all your rituals",
                                icon: "book.fill",
                                action: {
                                    exportPDFBook()
                                }
                            )
                            
                            ExportOptionCard(
                                title: "Share Single Ritual",
                                description: "Export one ritual as an elegant card",
                                icon: "square.and.arrow.up.fill",
                                action: {
                                    // Would show ritual picker
                                }
                            )
                        }
                        .padding(.horizontal, RitualTheme.padding)
                        .padding(.top, 20)
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingShareSheet) {
                if let url = pdfURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }
    
    private func exportPDFBook() {
        let pdfMetaData = [
            kCGPDFContextCreator: "Money Ritual Builder",
            kCGPDFContextAuthor: "Your Rituals",
            kCGPDFContextTitle: "My Money Rituals \(Calendar.current.component(.year, from: Date()))"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            var yPosition: CGFloat = 72
            
            for ritual in rituals {
                context.beginPage()
                
                // Title
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont(name: "Georgia", size: 24) ?? UIFont.systemFont(ofSize: 24, weight: .medium),
                    .foregroundColor: UIColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 1.0)
                ]
                let title = NSAttributedString(string: ritual.name ?? "Unnamed Ritual", attributes: titleAttributes)
                title.draw(at: CGPoint(x: 72, y: yPosition))
                yPosition += 40
                
                // Frequency
                let frequencyAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1.0)
                ]
                let frequency = NSAttributedString(string: "Frequency: \(ritual.frequency ?? "Daily")", attributes: frequencyAttributes)
                frequency.draw(at: CGPoint(x: 72, y: yPosition))
                yPosition += 30
                
                // Steps
                let steps = ritual.stepsArray
                if !steps.isEmpty {
                    let stepsTitle = NSAttributedString(string: "Steps:", attributes: titleAttributes)
                    stepsTitle.draw(at: CGPoint(x: 72, y: yPosition))
                    yPosition += 30
                    
                    for (index, step) in steps.enumerated() {
                        let stepText = NSAttributedString(string: "\(index + 1). \(step)", attributes: frequencyAttributes)
                        stepText.draw(at: CGPoint(x: 90, y: yPosition))
                        yPosition += 25
                    }
                }
                
                // Intention
                if let intention = ritual.intention, !intention.isEmpty {
                    yPosition += 20
                    let intentionTitle = NSAttributedString(string: "Intention:", attributes: titleAttributes)
                    intentionTitle.draw(at: CGPoint(x: 72, y: yPosition))
                    yPosition += 30
                    
                    let intentionText = NSAttributedString(string: intention, attributes: frequencyAttributes)
                    intentionText.draw(at: CGPoint(x: 72, y: yPosition))
                    yPosition += 40
                }
                
                yPosition += 40
                
                // New page if needed
                if yPosition > pageHeight - 100 {
                    context.beginPage()
                    yPosition = 72
                }
            }
        }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("MyMoneyRituals\(Calendar.current.component(.year, from: Date())).pdf")
        try? data.write(to: tempURL)
        pdfURL = tempURL
        showingShareSheet = true
    }
}

struct ExportOptionCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let description: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(RitualTheme.deepAmber)
                    .frame(width: 60, height: 60)
                    .background(RitualTheme.parchment(colorScheme: colorScheme))
                    .cornerRadius(16)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(RitualTheme.ritualNameFont)
                        .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
                    
                    Text(description)
                        .font(RitualTheme.captionFont)
                        .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme).opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme).opacity(0.4))
            }
            .padding(RitualTheme.padding)
            .background(RitualTheme.parchment(colorScheme: colorScheme))
            .cornerRadius(RitualTheme.cornerRadius)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ExportRitualBookView()
        .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
}
