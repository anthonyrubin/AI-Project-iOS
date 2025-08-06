import UIKit

class UploadImageViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: - UI Components

    let imageView: UIImageView = {
        let iv = UIImageView()
        iv.backgroundColor = .secondarySystemBackground
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.layer.borderWidth = 1
        iv.layer.borderColor = UIColor.gray.cgColor
        return iv
    }()

    let uploadButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Upload Image", for: .normal)
        button.backgroundColor = UIColor.systemBlue
        button.tintColor = .white
        button.layer.cornerRadius = 5
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    let chooseImageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Choose Screenshot", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // ViewModel
    private let viewModel = UploadImageViewModel()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        setupBindings()
    }

    // MARK: - UI Setup

    func setupUI() {
        view.addSubview(imageView)
        view.addSubview(uploadButton)
        view.addSubview(chooseImageButton)

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            imageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),

            chooseImageButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            chooseImageButton.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),

            uploadButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            uploadButton.topAnchor.constraint(equalTo: chooseImageButton.bottomAnchor, constant: 20),
            uploadButton.widthAnchor.constraint(equalTo: imageView.widthAnchor),
            uploadButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        chooseImageButton.addTarget(self, action: #selector(chooseImage), for: .touchUpInside)
        uploadButton.addTarget(self, action: #selector(uploadImage), for: .touchUpInside)
    }

    // MARK: - ViewModel Bindings

    func setupBindings() {
        viewModel.onUploadSuccess = {
            print("✅ Upload successful")
        }

        viewModel.onUploadFailure = { error in
            print("❌ Upload failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Actions

    @objc func chooseImage() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }

    @objc func uploadImage() {
        guard let image = imageView.image else { return }
        viewModel.uploadImage(image)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            imageView.image = selectedImage
        }
        dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
