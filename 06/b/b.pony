use "files"
use "collections"

class Planet
  var parent : (Planet | None)

  new create(parent': Planet) =>
    parent = parent'

  new parentless() =>
    parent = None

  fun depth() : USize =>
    match parent
    | let p: Planet box => 1 + p.depth()
    | None => 0
    end

  fun ref add_parent(parent': Planet) =>
    parent = parent'

actor Main
  new create(env: Env) =>
    let planets = Map[String, Planet]

    try
      planets.insert("COM", Planet.parentless())?
      let path = FilePath(env.root as AmbientAuth, "input.text")?
      let file = File.open(path)
      let lines = FileLines(file)

      for line in lines do
        let ps = line.split(")")
        let lhs_name = ps(0)?
        let rhs_name = ps(1)?

        let lhs = if planets.contains(lhs_name) then
          planets(lhs_name)?
        else
          planets.insert(lhs_name, Planet.parentless())?
        end

        let rhs = if planets.contains(rhs_name) then
          planets(rhs_name)?
        else
          planets.insert(rhs_name, Planet(lhs))?
        end

        rhs.add_parent(lhs)
      end

      let san = planets("SAN")?
      let you = planets("YOU")?

      let san_parents = get_parents(san)
      let you_parents = get_parents(you)


      let res = most_common_parent(san_parents, you_parents)

      let distance = ((san.depth() - res.depth()) + (you.depth() - res.depth())) - 2
      env.out.print(distance.string())
    else
      env.out.print("Stuff went wrong")
    end

  fun get_parents(planet: Planet) : Array[Planet] =>
    let r = Array[Planet]
    var current = planet
    var has_parent = true

    while has_parent do
      has_parent = match current.parent
      | let p: Planet =>
        r.push(p)
        current = p
        true
      | None => false
      end
    end

    r

  fun most_common_parent(lhs: Array[Planet], rhs: Array[Planet]) : Planet =>
    // This is a very inefficient function.
    // Not only does it have classic nested loops for O(n^2) but every call to depth()
    // is also linear. So that's like O(n^3)?
    var common = Planet.parentless()

    for planet in lhs.values() do
      for other_planet in rhs.values() do
        if (planet is other_planet) and (planet.depth() > common.depth()) then
          common = planet
        end
      end
    end

    common
