use "files"

type Layers is Array[Array[U8]]

actor Main
  let _env : Env

  new create(env: Env) =>
    _env = env

    let height: U8 = 6
    let width: U8 = 25
    let image = Array[U8].init(0, (width * height).usize())
    let layers = get_layers(width * height)

    try
      for loc in layers(0)?.keys() do
        for layer in layers.values() do
          try
            match layer(loc)?
            | 0 => image.update(loc, 0)?; break
            | 1 => image.update(loc, 1)?; break
            end
          else
            None
            //_env.out.print("Eh? " + loc.string())
          end
        end
      end
    end

    print_image(image, width)


  fun print_image(image: Array[U8], width: U8) =>
    for (index, pixel) in image.pairs() do
      if (index.u8() % width) == 0 then
        _env.out.print("")
      end

      match pixel
      | 0 => _env.out.write(" ")
      | 1 => _env.out.write("█")
      end
    end

  fun get_layers(width: U8) : Layers =>
    let layers = Layers
    var i: U8 = 1
    var a = Array[U8]

    for pixel in read_input().values() do
      try
        a.push(String.from_array([pixel]).u8()?)
      end

      if i == width then
        layers.push(a)
        i = 1
        a = Array[U8]
      else
        i = i + 1
      end
    end

    layers

  fun read_input() : String =>
    try
      let path = FilePath(_env.root as AmbientAuth, "input.text")?
      let file = File.open(path)
      let input = file.read_string(20000)
      input.strip()
      input
    else
      ""
    end
