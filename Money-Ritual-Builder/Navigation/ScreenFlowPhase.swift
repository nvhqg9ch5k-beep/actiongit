import Foundation

enum ScreenFlowPhase {
    case launch
    case mainApp
    case remotePage(String)
    case errorScreen(String)
}
