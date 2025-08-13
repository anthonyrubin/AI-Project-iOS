import Foundation
import UIKit
import PhotosUI
import UniformTypeIdentifiers

final class SessionViewController: UIViewController {
    private let viewModel = VideoUploadViewModel()
    private let floatingBar = UIView()
    private let startButton: UIButton = {
        var c = UIButton.Configuration.filled()
        c.title = "START SESSION"
        c.image = UIImage(systemName: "video.fill")
        c.imagePadding = 8
        c.baseBackgroundColor = .black
        c.baseForegroundColor = .white
        c.cornerStyle = .medium
        return UIButton(configuration: c)
    }()

    private let floatingHeight: CGFloat = 92
    private let shadowPad: CGFloat = 24       // room above for the top shadow
    private weak var host: UIView?            // lives in tabBarController.view

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        hideNavBarHairline()
        
        setupViewModel()
        setupUI()

        // bar visuals
        floatingBar.backgroundColor = .white
        floatingBar.layer.cornerRadius = 20
        floatingBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        floatingBar.layer.masksToBounds = false
        floatingBar.layer.shadowColor = UIColor.black.cgColor
        floatingBar.layer.shadowOpacity = 0.5
        floatingBar.layer.shadowRadius = 12
        floatingBar.layer.shadowOffset = .init(width: 0, height: 6)

        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.addTarget(self, action: #selector(startSession), for: .touchUpInside)
    }
    
    private func setupViewModel() {
        viewModel.onUploadSuccess = { [weak self] videoId in
            print("Video uploaded successfully with ID: \(videoId)")
            // Show success message or navigate to analysis view
        }
        
        viewModel.onUploadFailure = { [weak self] error in
            print("Video upload failed: \(error)")
            // Show error message to user
        }
        
        viewModel.onAnalysisComplete = { [weak self] analysisId in
            print("Video analysis completed with ID: \(analysisId)")
            // Navigate to results view or show success message
        }
        
        viewModel.onAnalysisFailure = { [weak self] error in
            print("Video analysis failed: \(error)")
            // Show error message to user
        }
        
        viewModel.onDataRefreshNeeded = { [weak self] in
            // Notify LessonsViewController to refresh data
            NotificationCenter.default.post(name: .videoAnalysisCompleted, object: nil)
        }
    }
    
    private func setupUI() {
        // Additional UI setup if needed
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        installFloatingBarIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // refresh path after any layout changes when returning to this tab
        tabBarController?.view.layoutIfNeeded()
        updateShadowPath()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        uninstallFloatingBar() // do not persist over other tabs
    }

    private func installFloatingBarIfNeeded() {
        guard host == nil, let tbc = tabBarController else { return }

        // Host view clips bottom; pinned to tab bar top
        let host = UIView()
        host.translatesAutoresizingMaskIntoConstraints = false
        host.clipsToBounds = true
        tbc.view.addSubview(host)

        NSLayoutConstraint.activate([
            host.leadingAnchor.constraint(equalTo: tbc.view.leadingAnchor),
            host.trailingAnchor.constraint(equalTo: tbc.view.trailingAnchor),
            host.bottomAnchor.constraint(equalTo: tbc.tabBar.topAnchor),
            host.heightAnchor.constraint(equalToConstant: floatingHeight + shadowPad)
        ])

        // Bar sits inside host with top padding for the shadow cap
        floatingBar.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(floatingBar)
        NSLayoutConstraint.activate([
            floatingBar.topAnchor.constraint(equalTo: host.topAnchor, constant: shadowPad),
            floatingBar.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            floatingBar.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            floatingBar.bottomAnchor.constraint(equalTo: host.bottomAnchor)
        ])

        floatingBar.addSubview(startButton)
        NSLayoutConstraint.activate([
            startButton.topAnchor.constraint(equalTo: floatingBar.topAnchor, constant: 20),
            startButton.leadingAnchor.constraint(equalTo: floatingBar.leadingAnchor, constant: 20),
            startButton.trailingAnchor.constraint(equalTo: floatingBar.trailingAnchor, constant: -20),
            startButton.bottomAnchor.constraint(equalTo: floatingBar.bottomAnchor, constant: -20)
        ])

        UIView.performWithoutAnimation { tbc.view.layoutIfNeeded() }
        self.host = host
        updateShadowPath() // top-only shadow
    }

    private func uninstallFloatingBar() {
        host?.removeFromSuperview()
        host = nil
    }

    // Draw shadow only on the top cap so nothing overlaps the tab bar
    private func updateShadowPath() {
        guard floatingBar.bounds.width > 0 else { return }
        let r = floatingBar.bounds
        let capHeight: CGFloat = 32
        let cap = CGRect(x: 0, y: 0, width: r.width, height: min(capHeight, r.height))
        let path = UIBezierPath(
            roundedRect: cap,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: 20, height: 20)
        )
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        floatingBar.layer.shadowPath = path.cgPath
        CATransaction.commit()
    }

    @objc private func startSession() {
        var cfg = PHPickerConfiguration(photoLibrary: .shared())
        cfg.filter = .videos
        cfg.selectionLimit = 1
        cfg.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: cfg)
        picker.delegate = self
        present(picker, animated: true)
    }
}

// MARK: - PHPicker
extension SessionViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)

        guard let item = results.first?.itemProvider else { return }
        let type = UTType.movie.identifier

        guard item.hasItemConformingToTypeIdentifier(type) else { return }

        item.loadFileRepresentation(forTypeIdentifier: type) { [weak self] url, err in
            guard let self, let url else { return }
            // Copy to a readable location for later upload/use
            let dest = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(url.pathExtension.isEmpty ? "mov" : url.pathExtension)
            do {
                // remove if exists
                try? FileManager.default.removeItem(at: dest)
                try FileManager.default.copyItem(at: url, to: dest)
                DispatchQueue.main.async {
                    self.handlePickedVideo(at: dest)
                }
            } catch {
                // handle copy error if needed
            }
        }
    }

    private func handlePickedVideo(at url: URL) {
        // Upload video using the view model with loading overlay
        viewModel.uploadVideo(fileURL: url, on: self)
    }
}
