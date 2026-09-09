components {
  id: "fx_hit"
  component: "/app/gameplay/systems/hit/fx_hit.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"R48\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "size {\n"
  "  x: 48.0\n"
  "  y: 48.0\n"
  "}\n"
  "size_mode: SIZE_MODE_MANUAL\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/app/media/atlasses/common.atlas\"\n"
  "}\n"
  ""
  position {
    z: -1.0
  }
}
