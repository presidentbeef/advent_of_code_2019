use "files"

actor Main
  let _env : Env

  new create(env: Env) =>
    _env = env

    let layers = get_layers(25 * 6)
    let least_zeroes = min_layer(layers)

    let num_ones = count_digits(least_zeroes, 1)
    let num_twos = count_digits(least_zeroes, 2)

    env.out.print((num_ones * num_twos).string())

  fun print_layers(layers: Array[Array[U8]]) =>
    for l in layers.values() do
      for p in l.values() do
        _env.out.write(p.string())
      end
      _env.out.print("")
    end


  fun min_layer(layers: Array[Array[U8]]) : Array[U8] =>
    try
      var layer = layers(0)?
      var min_zeroes = USize.max_value()

      for l in layers.values() do
        let m = count_digits(l, 0)
        if m < min_zeroes then
          min_zeroes = m
          layer = l
        end
      end

      layer
    else
      []
    end

  fun get_layers(width: U8) : Array[Array[U8]] =>
    let layers = Array[Array[U8]]
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

  fun count_digits(array: Array[U8], digit: U8) : USize =>
    var count: USize = 0

    for d in array.values() do
      if d == digit then
        count = count + 1
      end
    end

    count
