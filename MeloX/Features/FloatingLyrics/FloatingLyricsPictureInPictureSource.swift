import SwiftUI
import UIKit

struct FloatingLyricsPictureInPictureSource: UIViewRepresentable {
    let controller: FloatingLyricsController

    func makeCoordinator() -> Coordinator {
        Coordinator(controller: controller)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        view.isUserInteractionEnabled = false
        controller.attachDisplayLayer(
            to: view.layer,
            bounds: view.bounds
        )
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        controller.updateDisplayLayerFrame(view.bounds)
    }

    static func dismantleUIView(
        _ view: UIView,
        coordinator: Coordinator
    ) {
        MainActor.assumeIsolated {
            coordinator.controller.detachDisplayLayer(from: view.layer)
        }
    }

    final class Coordinator {
        let controller: FloatingLyricsController

        init(controller: FloatingLyricsController) {
            self.controller = controller
        }
    }
}
