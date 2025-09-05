components {
  id: "shape"
  component: "/scripts/shape.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"circle\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "size {\n"
  "  x: 100.0\n"
  "  y: 100.0\n"
  "}\n"
  "size_mode: SIZE_MODE_MANUAL\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/atlas/game.atlas\"\n"
  "}\n"
  ""
}
