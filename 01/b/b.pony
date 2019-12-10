use "files"

actor Main
  new create(env: Env) =>
    var i: I64 = 0

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

  fun fuel_for(mass: F64) : I64 =>
    let fuel: I64 = (mass / 3).floor().i64() - 2

    if fuel <= 0 then
      0
    else
      fuel + fuel_for(fuel.f64())
    end
