use "files"
use "collections"

interface HasDepth
  fun depth(): USize

  fun ref add_parent(parent: HasDepth)


class COM
  fun depth() : USize =>
    0

  new create() =>
    None

  fun ref add_parent(parent: HasDepth) =>
    None

class Planet
  var _parent : HasDepth

  new create(parent: HasDepth) =>
    _parent = parent

  new parentless() =>
    _parent = COM // dumb reuse of COM

  fun depth() : USize =>
    1 + _parent.depth()

  fun ref add_parent(parent: HasDepth) =>
    _parent = parent

actor Main
  new create(env: Env) =>
    let planets = Map[String, HasDepth]

    try
      planets.insert("COM", COM)?
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

      var total : USize = 0
      for planet in planets.values() do
        total = total + planet.depth()
      end

      env.out.print(total.string())
    else
      env.out.print("Stuff went wrong")
    end

