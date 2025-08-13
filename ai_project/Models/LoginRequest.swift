import Foundation

enum Checkpoint: String, Decodable { case verify_code, name, birthday, home }

struct LoginOrCheckpointResponse: Decodable {
    let email: String
    let checkpoint: Checkpoint
    let tokens: TokenResponse?
    let user: User?
}
