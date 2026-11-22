//! The $12 Server Challenge submission binary.
//! Config comes only from env (SPEC.md): SQLITE_PATH, JWT_SECRET, HOST, PORT.

pub mod config;
pub mod handlers;
pub mod jwt;
pub mod router;
pub mod store;

fn main() {
    let sqlite_path = std::env::var("SQLITE_PATH").expect("SQLITE_PATH");
    let jwt_secret = std::env::var("JWT_SECRET").expect("JWT_SECRET");
    let host = std::env::var("HOST").unwrap_or_else(|_| "0.0.0.0".into());
    let port = std::env::var("PORT").unwrap_or_else(|_| "80".into());
    let cfg = config::Config::from_env().unwrap_or_else(|e| {
        eprintln!("config: {e}");
        std::process::exit(2);
    });
    let _ = (cfg, sqlite_path, jwt_secret, host, port);
    // TODO(challenge): wire uring-http loop + sqlite-btree reads + group commit.
}
