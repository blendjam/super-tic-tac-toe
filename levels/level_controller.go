components {
  id: "level_controller"
  component: "/scripts/level_controller.script"
}
embedded_components {
  id: "game"
  type: "collectionproxy"
  data: "collection: \"/main/game.collection\"\n"
  ""
}
embedded_components {
  id: "main_menu"
  type: "collectionproxy"
  data: "collection: \"/levels/main_menu.collection\"\n"
  ""
}
