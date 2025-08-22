use yew::prelude::*;

pub struct HomePage {
    count: i32,
}

#[derive(Properties, PartialEq, Default)]
pub struct HomePageProps;

pub enum HomePageMsg {
    Add,
}

impl Component for HomePage {
    type Message = HomePageMsg;
    type Properties = HomePageProps;

    fn create(ctx: &Context<Self>) -> Self {
        Self { count: 0 }
    }

    fn view(&self, ctx: &Context<Self>) -> Html {
        let onclick = ctx.link().callback(|_| HomePageMsg::Add);
        html! {
            <div>
                <button {onclick}>{ "Add" }</button>
                <h1 class="text-pink-900">{ self.count }</h1>
            </div>
        }
    }
    fn update(&mut self, ctx: &Context<Self>, msg: Self::Message) -> bool {
        match msg {
            HomePageMsg::Add => self.count += 1,
        }
        true
    }
}
