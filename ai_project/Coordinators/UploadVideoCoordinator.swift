
import UIKit
import AVFoundation
import PhotosUI
import UniformTypeIdentifiers

struct UploadFlowState {
    var selectedLift: String?
    var pickedAsset: AVAsset?
    var trimmedTimeRange: CMTimeRange?
    var extraNotes: String?
}

final class UploadVideoCoordinator: NSObject, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
    private(set) var nav: UINavigationController!
    private weak var presentingVC: UIViewController?
    private let header: UploadStepHeaderView
    private var state = UploadFlowState()
    private let totalSteps = 3 // example: 0=select, 1=tips, 2=pick video; metadata is post-steps
    private let uploadStateManager: UploadStateManager

    init(startingAt presentingVC: UIViewController, uploadStateManager: UploadStateManager) {
        self.presentingVC = presentingVC
        self.uploadStateManager = uploadStateManager
        self.header = UploadStepHeaderView(total: totalSteps)
        super.init()

        let root = SelectExerciseViewController()
        // wire step callbacks the coordinator expects
        root.onSelectedLift = { [weak self] lift in self?.state.selectedLift = lift }
        // let VC advance the flow via its bottom Continue
        root.onContinue = { [weak self] in self?.nextTapped() }

        nav = UINavigationController(rootViewController: root)
        nav.delegate = self
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = false
        }

        // Back chevron uses the darker gray of your two grays
        nav.navigationBar.tintColor = .secondaryLabel

        installNavChrome(for: root, stepIndex: 0)
        presentingVC.present(nav, animated: true)
    }

    func start() {
        presentingVC?.present(nav, animated: true)
    }

    // MARK: - Right-side header item

    private func makeHeaderBarItem() -> UIBarButtonItem {
        header.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(header)

        NSLayoutConstraint.activate([
            header.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            header.topAnchor.constraint(equalTo: container.topAnchor),
            header.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            header.heightAnchor.constraint(equalToConstant: 32)
        ])

        // Size container to the header’s fitting width
        let width = header.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).width
        container.frame = CGRect(x: 0, y: 0, width: width, height: 32)

        return UIBarButtonItem(customView: container)
    }

    // MARK: - Left-side close chip

    private func makeCloseBarItem() -> UIBarButtonItem {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .secondarySystemBackground
        button.tintColor = .secondaryLabel
        button.layer.cornerRadius = 16
        button.layer.masksToBounds = true
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        let image = UIImage(systemName: "xmark")?.applyingSymbolConfiguration(symbolConfig)
        button.setImage(image, for: .normal)

        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 32),
            button.heightAnchor.constraint(equalToConstant: 32)
        ])

        button.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        button.applyTactileTap()

        return UIBarButtonItem(customView: button)
    }

    // MARK: Navigation

    private func installNavChrome(for vc: UIViewController, stepIndex: Int) {
        header.setActive(index: stepIndex)

        vc.navigationItem.titleView = nil
        vc.navigationItem.rightBarButtonItem = makeHeaderBarItem()

        if nav.viewControllers.first === vc {
            vc.navigationItem.leftBarButtonItem = makeCloseBarItem()
        } else {
            vc.navigationItem.leftBarButtonItem = nil
        }
    }

    // MARK: Actions

    @objc private func closeTapped() { nav.dismiss(animated: true) }

    // Called by each VC's bottom Continue (via onContinue)
    @objc private func nextTapped() {
        guard let top = nav.topViewController else { return }

        if let _ = top as? SelectExerciseViewController {
            // Step 0 → Step 1
            let instructionsStep1 = InstructionStep1ViewController()
            instructionsStep1.onContinue = { [weak self] in self?.nextTapped() }
            nav.pushViewController(instructionsStep1, animated: true)
            installNavChrome(for: instructionsStep1, stepIndex: 1)
            return
        } else if let _ = top as? InstructionStep1ViewController {
            // Step 1 → Step 2 (video pick step)
            let oneFullRep = OneFullRepViewController()
            // Continue here should open picker
            oneFullRep.onContinue = { [weak self] in self?.presentVideoPicker() }
            nav.pushViewController(oneFullRep, animated: true)
            installNavChrome(for: oneFullRep, stepIndex: 2)
            return
        }
        // else if top is your next step, handle accordingly…
    }

    @objc private func backFromMeta() { nav.popViewController(animated: true) }

    // Keep header on the visible VC after interactive back/push
    func navigationController(_ navigationController: UINavigationController,
                              willShow viewController: UIViewController,
                              animated: Bool) {
        let idx: Int
        switch viewController {
        case is SelectExerciseViewController:   idx = 0
        case is InstructionStep1ViewController: idx = 1
        case is OneFullRepViewController:       idx = 2
//      case is PickVideoVC:                    idx = 2
        default:
            viewController.navigationItem.titleView = nil
            return
        }
        installNavChrome(for: viewController, stepIndex: idx)
    }

    // MARK: - Video Picker

    private func presentVideoPicker() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 1
        config.filter = .videos

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        nav.present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let result = results.first else { return }
        let provider = result.itemProvider

        let movieType = UTType.movie.identifier
        if provider.hasItemConformingToTypeIdentifier(movieType) {
            provider.loadFileRepresentation(forTypeIdentifier: movieType) { [weak self] url, error in
                guard let self = self, let srcURL = url, error == nil else { return }

                // Copy to a URL we own so the file persists
                let tmpDir = FileManager.default.temporaryDirectory
                let destURL = tmpDir.appendingPathComponent("coachai-\(UUID().uuidString).mov")
                do {
                    try? FileManager.default.removeItem(at: destURL)
                    try FileManager.default.copyItem(at: srcURL, to: destURL)

                    // Make thumbnail off-main; push on main
                    let thumb = generateThumbnail(for: destURL)
                    let prefill = self.state.selectedLift?.capitalized
                    DispatchQueue.main.async {
                        self.state.pickedAsset = AVAsset(url: destURL)
                        self.pushVideoReview(thumbnail: thumb, videoURL: destURL, prefill: prefill)
                    }
                } catch {
                    print("Copy failed:", error)
                }
            }
        } else {
            // Fallback if needed
            provider.loadObject(ofClass: AVURLAsset.self) { [weak self] obj, _ in
                guard let self = self, let avURLAsset = obj as? AVURLAsset else { return }
                let url = avURLAsset.url
                let thumb = generateThumbnail(for: url)
                let prefill = self.state.selectedLift?.capitalized
                DispatchQueue.main.async {
                    self.state.pickedAsset = avURLAsset
                    self.pushVideoReview(thumbnail: thumb, videoURL: url, prefill: prefill)
                }
            }
        }
    }


    // MARK: - Next Screen (stub)

    private func pushVideoReview(thumbnail: UIImage?, videoURL: URL? = nil, prefill: String? = nil) {
        guard let videoURL = videoURL else { return }

        let edit = EditVideoViewController(videoURL: videoURL)
        edit.navigationItem.titleView = nil

        edit.onFinish = { [weak self] trimmedURL, range in
            guard let self = self else { return }

            // Update coordinator state to the TRIMMED clip
            self.state.pickedAsset = AVAsset(url: trimmedURL)
            self.state.trimmedTimeRange = range

            // Snapshot from the trimmed clip
            let thumb = generateThumbnail(for: trimmedURL)
            let prefill = self.state.selectedLift?.capitalized

            // Push the analysis questions screen with trimmed media
            let questions = StartAnalysisQuestionsViewController(
                thumbnail: thumb,
                videoURL: trimmedURL,
                prefill: prefill,
                isSignup: false,
                selectedLift: state.selectedLift
            )
            questions.hidesProgressBar = true
            questions.navigationItem.titleView = nil
            questions.uploadStateManager = self.uploadStateManager
            self.nav.pushViewController(questions, animated: true)
        }

        nav.pushViewController(edit, animated: true)
    }

}
