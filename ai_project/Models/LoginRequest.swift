import Foundation

enum Checkpoint: String, Decodable { case verify_code, name, birthday, home }

struct LoginOrCheckpointResponse: Decodable {
    let checkpoint: Checkpoint
    let tokens: TokenResponse?
    let user: User
}
