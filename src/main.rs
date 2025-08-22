use app::App;
#[cfg(feature = "ssr")]
mod server;
#[cfg(feature = "ssr")]
#[rocket::main]
async fn main() -> Result<(), rocket::Error> {
    server::run_server().await
}

#[cfg(feature = "csr")]
fn main() {
    yew::Renderer::<App>::new().render();
}

#[cfg(feature = "hydration")]
pub fn main() {
    yew::Renderer::<App>::new().hydrate();
}
