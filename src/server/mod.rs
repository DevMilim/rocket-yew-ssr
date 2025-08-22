use std::{fs, path::PathBuf};

use app::{ServerApp, ServerAppProps};
use rocket::{
    fs::FileServer,
    get,
    response::content::RawHtml,
    routes,
};
use yew::ServerRenderer;


#[get("/<url..>", rank = 20)]
async fn yew_routes(url: PathBuf) -> Option<RawHtml<String>> {
    let route = url.to_string_lossy();
    let path = if route.is_empty() {
        "/".to_string()
    } else {
        format!("/{}", route.trim_start_matches('/'))
    };
    let render =
        ServerRenderer::<ServerApp>::with_props(move || ServerAppProps { url: path.clone() })
            .render()
            .await;
    let html = fs::read_to_string("./index.html").ok()?;

    let a = html.replace("{{SSR_HTML}}", &render);
    println!(">> {}", route);

    Some(RawHtml(a))
}

pub async fn run_server() -> Result<(), rocket::Error> {
    let _ = rocket::build()
        .mount("/", FileServer::from("static"))
        .mount("/", routes![yew_routes])
        .launch()
        .await?;
    Ok(())
}
