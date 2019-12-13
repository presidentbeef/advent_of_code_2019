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
      var min : U32 = U32.max_value()

      try
        let wire1 = dirs_to_lines(dirs(0)?)
        let wire2 = dirs_to_lines(dirs(1)?)

        var last_line1 = Line(Point(0, 0), Point(0, 0))
        var l1_steps : U32 = 0

        for line1 in wire1.values() do
          var l2_steps : U32 = 0
          var last_line2 = Line(Point(0, 0), Point(0, 0))

          for line2 in wire2.values() do
            if line1.intersects(line2) then
              let i = line1.intersection(line2)

              let steps = l1_steps +
                  l2_steps +
                  line1.steps_to_point(i, last_line1) +
                  line2.steps_to_point(i, last_line2)

              if steps < min then
                min = steps
              end

              break
            end

            last_line2 = line2
            l2_steps = l2_steps + line2.length()
          end

          last_line1 = line1
          l1_steps = l1_steps + line1.length()
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
