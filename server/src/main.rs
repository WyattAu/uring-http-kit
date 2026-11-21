//! The $12 Server Challenge submission binary.
//! Config comes only from env (SPEC.md): SQLITE_PATH, JWT_SECRET, HOST, PORT.

fn main() {
    let sqlite_path = std::env::var("SQLITE_PATH").expect("SQLITE_PATH");
    let jwt_secret = std::env::var("JWT_SECRET").expect("JWT_SECRET");
    let host = std::env::var("HOST").unwrap_or_else(|_| "0.0.0.0".into());
    let port = std::env::var("PORT").unwrap_or_else(|_| "80".into());
    eprintln!("feed-server skeleton: sqlite={sqlite_path} host={host} port={port} jwt_len={}", jwt_secret.len());
    // TODO(challenge): wire uring-http loop + sqlite-btree reads + group commit.
}
