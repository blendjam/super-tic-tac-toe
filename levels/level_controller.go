components {
  id: "level_controller"
  component: "/scripts/level_controller.script"
}
embedded_components {
  id: "normal_mode"
  type: "collectionproxy"
  data: "collection: \"/levels/normal_mode.collection\"\n"
  ""
}
embedded_components {
  id: "main_menu"
  type: "collectionproxy"
  data: "collection: \"/levels/main_menu.collection\"\n"
  ""
}
embedded_components {
  id: "super_mode"
  type: "collectionproxy"
  data: "collection: \"/levels/super_mode.collection\"\n"
  ""
}
embedded_components {
  id: "grid_mode"
  type: "collectionproxy"
  data: "collection: \"/levels/super_mode.collection\"\n"
  ""
}
