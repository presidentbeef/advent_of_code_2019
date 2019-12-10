use "files"

actor Main
  new create(env: Env) =>
    var i: U64 = 0

    try
      let path = FilePath(env.root as AmbientAuth, "input.text")?
      let file = File.open(path)
      let lines = FileLines(file)

      for line in lines do
        let mass = line.f64()?
        i = i + fuel_for(mass)
      end

      env.out.print(i.string())
    end

  fun fuel_for(mass: F64) : U64 =>
    (mass / 3).floor().u64() - 2
