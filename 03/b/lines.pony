class val Point
  let x : I32 val
  let y : I32 val

  new val create(x': I32, y': I32) =>
    x = x'
    y = y'

  fun vertical_with(p2: Point) : Bool =>
    x == p2.x

  fun horizontal_with(p2: Point) : Bool =>
    y == p2.y

  fun left_of(p2: Point) : Bool =>
    x < p2.x

  fun right_of(p2: Point) : Bool =>
    x > p2.x

  fun above(p2: Point) : Bool =>
    y > p2.y

  fun below(p2: Point) : Bool =>
    y < p2.y

  fun eq(p2: Point) : Bool =>
    (x == p2.x) and
    (y == p2.y)

  fun distance_from_0() : U32 =>
    x.abs() + y.abs()

  fun string() : String =>
    x.string() + "," + y.string()

class Line
  let p1 : Point
  let p2 : Point

  new create(p1': Point, p2' : Point) =>
    // To simplify things,
    // p1 is always the left/bottom point
    // and p2 is always the right/top point
    if p1'.vertical_with(p2') then
      if p1'.y < p2'.y then
        p1 = p1'
        p2 = p2'
      else
        p1 = p2'
        p2 = p1'
      end
    else
      if p1'.x < p2'.x then
        p1 = p1'
        p2 = p2'
      else
        p1 = p2'
        p2 = p1'
      end
    end

  fun is_vertical() : Bool =>
    p1.vertical_with(p2)

  fun is_horizontal() : Bool =>
    p1.horizontal_with(p2)

  fun intersects(line: Line) : Bool =>
    if is_vertical() then
      if line.is_vertical() then
        return false
      end

      if line.p1.left_of(p1) and
        line.p2.right_of(p1) and
        line.p1.above(p1) and
        line.p1.below(p2) then

        return true
      end

    elseif is_horizontal() then
      if line.is_horizontal() then
        return false
      end

      if line.p1.below(p1) and
        line.p2.above(p1) and
        line.p1.right_of(p1) and
        line.p1.left_of(p2) then

        return true
      end
    end

    false

  fun intersection(line: Line) : Point =>
    if is_vertical() then
      // This line is vertical,
      // so intersection is this line's
      // X and the other line's Y
      Point(p1.x, line.p1.y)
    else
      // This line is vertical,
      // so intersection is this line's
      // Y and the other line's X
      Point(line.p1.x, p1.y)
    end

  fun length() : U32 =>
    if is_vertical() then
      (p2.y - p1.y).abs()
    else
      (p2.x - p1.x).abs()
    end

  fun steps_to_point(point: Point, prev: Line) : U32 =>
    // Need to determine start point based on connection to
    // previous line *sigh*
    let start = if (p1 == prev.p1) or (p1 == prev.p2) then
      p1
    else
      p2
    end

    (start.x - point.x).abs() +
        (start.y - point.y).abs()
