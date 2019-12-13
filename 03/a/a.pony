use "files"

actor Main
  new create(env: Env) =>
      let path = try
        FilePath(env.root as AmbientAuth, "input.text")?
      else
        env.out.print("No file?")
        return
      end

      let dirs = read_dirs(path)
      let intersections = Array[Point]

      try
        let wire1 = dirs_to_lines(dirs(0)?)
        let wire2 = dirs_to_lines(dirs(1)?)

        for line1 in wire1.values() do
          for line2 in wire2.values() do
            if line1.intersects(line2) then
              intersections.push(line1.intersection(line2))
            end
          end
        end
      end

      var min = U32.max_value()

      for i in intersections.values() do
        if i.distance_from_0() < min then
          min = i.distance_from_0()
        end
      end

      env.out.print(min.string())


  fun read_dirs(path: FilePath) : Array[Array[String]] =>
    let file = File.open(path)
    let result = Array[Array[String]](2)
    for line in FileLines(file) do
      result.push(split_dirs(consume line))
    end

    result

  fun split_dirs(input: String ref) : Array[String] =>
    input.strip()
    input.split_by(",")

  fun dirs_to_lines(dirs: Array[String]) : Array[Line] =>
    var x: I32 = 0
    var y: I32 = 0
    let a = Array[Line]

    for dir in dirs.values() do
      try
        let step = dir.substring(1,4).i32()?

        match dir(0)?
        | 68 => // Down
            a.push(Line(Point(x, y), Point(x, y - step)))
            y = y - step
        | 85 => // Up
            a.push(Line(Point(x, y), Point(x, y + step)))
            y = y + step
        | 82 => // Right
            a.push(Line(Point(x, y), Point(x + step, y)))
            x = x + step
        | 76 => // Left
            a.push(Line(Point(x, y), Point(x - step, y)))
            x = x - step
        end
      end
    end

    a
