enum Checkpoint: String, Decodable {
    case verify_code = "verify_code"
    case name
    case birthday
    case home
}

struct CheckpointResponse: Decodable {
    let checkpoint: Checkpoint
    let email: String?
}
