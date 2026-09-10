embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"S_Busket\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "size {\n"
  "  x: 83.0\n"
  "  y: 45.0\n"
  "}\n"
  "size_mode: SIZE_MODE_MANUAL\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/app/media/atlasses/common.atlas\"\n"
  "}\n"
  ""
  position {
    z: 1.0
  }
  scale {
    x: 0.75
    y: 0.75
  }
}
embedded_components {
  id: "label"
  type: "label"
  data: "size {\n"
  "  x: 200.0\n"
  "  y: 80.0\n"
  "}\n"
  "text: \"0.2x\"\n"
  "font: \"/app/media/font/16px-numbers-roboto-bold-df.font\"\n"
  "material: \"/builtins/fonts/label-df.material\"\n"
  ""
  position {
    x: -1.0
    y: 5.0
    z: 1.1
  }
  scale {
    x: 0.25
    y: 0.25
  }
}
embedded_components {
  id: "label_shadow"
  type: "label"
  data: "size {\n"
  "  x: 200.0\n"
  "  y: 80.0\n"
  "}\n"
  "color {\n"
  "  x: 0.0\n"
  "  y: 0.0\n"
  "  z: 0.0\n"
  "}\n"
  "outline {\n"
  "  w: 0.0\n"
  "}\n"
  "text: \"0.2x\"\n"
  "font: \"/app/media/font/16px-numbers-roboto-bold-df.font\"\n"
  "material: \"/builtins/fonts/label-df.material\"\n"
  ""
  position {
    x: 0.15
    y: 3.7
    z: 1.0
  }
  scale {
    x: 0.25
    y: 0.25
  }
}
