use std::{fs, path::PathBuf, sync::RwLock};

use app::{ServerApp, ServerAppProps};
use rocket::{
    fairing::{Fairing, Info, Kind},
    fs::FileServer,
    get,
    response::content::RawHtml,
    routes, Data, Request,
};
use yew::ServerRenderer;

struct AppState {
    counter: RwLock<i32>,
}

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

struct Counter {
    get: RwLock<i32>,
}

#[rocket::async_trait]
impl Fairing for Counter {
    fn info(&self) -> Info {
        Info {
            name: "GET Counter",
            kind: Kind::Request | Kind::Response,
        }
    }
    async fn on_request(&self, request: &mut Request<'_>, _: &mut Data<'_>) {
        println!("Request: {:?}", self.get.read());
        let mut value = self.get.write().unwrap();
        *value += 1;
    }
}

pub async fn run_server() -> Result<(), rocket::Error> {
    let a = AppState {
        counter: RwLock::new(0),
    };
    let _ = rocket::build()
        .manage(a)
        .attach(Counter {
            get: RwLock::new(0),
        })
        .mount("/", FileServer::from("static"))
        .mount("/", routes![yew_routes])
        .launch()
        .await?;
    Ok(())
}
