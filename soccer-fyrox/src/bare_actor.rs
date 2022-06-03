use crate::prelude::*;

#[my_actor_based]
pub struct BareActor {}

impl BareActor {
    pub fn new(anchor: Anchor) -> Self {
        let vpos = Vector2::new(0, 0);

        let img_base = "blank";
        let img_indexes = vec![];

        Self {
            vpos,
            img_base,
            img_indexes,
            anchor,
        }
    }
}