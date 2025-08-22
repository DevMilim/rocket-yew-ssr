use yew::prelude::*;
use yew_router::prelude::*;

pub mod home;

use home::HomePage;

#[derive(Routable, Debug, Clone, PartialEq, Eq)]

pub enum AppRoute {
    #[at("/")]
    Home,
    #[not_found]
    #[at("/page-not-found")]
    PageNotFound,
}

pub fn switch(routes: AppRoute) -> Html {
    match routes.clone() {
        AppRoute::Home => html! { <HomePage /> },
        AppRoute::PageNotFound => html! { "Page not found" },
    }
}

#[derive(Properties, PartialEq, Clone)]
pub struct ServerAppProps {
    pub url: String,
}

#[function_component(App)]
pub fn app() -> Html {
    html! {
        <BrowserRouter>
            <div class="flex min-h-screen flex-col">
                <Switch<AppRoute> render={switch} />
            </div>
        </BrowserRouter>
    }
}

#[cfg(not(target_arch = "wasm32"))]
#[function_component]
pub fn ServerApp(props: &ServerAppProps) -> Html {
    use yew_router::history::{AnyHistory, MemoryHistory};
    let mem = MemoryHistory::with_entries(vec![props.url.clone()]);
    let any_hist = AnyHistory::from(mem);
    html! {
        <Router history={any_hist}>
            <div class="flex min-h-screen flex-col">
                <Switch<AppRoute> render={switch} />
            </div>
        </Router>
    }
}
