require_relative 'game.rb'
require 'meiro'

class RandomRoom
  attr_accessor :grid
  def initialize(map, status, window)
    @status = status
    @map = map
    @window = window
    @move_timer = Time.new
    @timer = Time.new
    @freeze = false
    @grid = {}
    default_definitions()

    @width = rand(40..60)
    @height = rand(20..30)

    @map.define_object("alien", {
      symbol: "A",
      type: "enemy",
      hp: 100,
      dmg: 10,
      color: Gosu::Color::rgb(100, 255, 100),
      killed_by: ["When trying to kiss an alien, it decided to eat you. Sicko.", "You were killed by an alien.", "Alien spit, does, in fact, burn.", "Once upon a time, you died.", "In the name of science, you discovered what an alien's stomach looks like.", "When unarmed, don't attempt battle."][rand(0..4)],
      behavior: ->(args) {
        me = @map.get_object_by_id(args[:id])
        if distance_from(me, @map.player) < 7
          chase(me, @map.player)
        else
          move_randomly(me)
        end
        passive_damage(me)
      },
    })

    options = {
      width:  @map.width,
      height: @map.height,
      min_room_number: 3,
      max_room_number: 10,
      min_room_width:  5,
      max_room_width: 20,
      min_room_height: 3,
      max_room_height: 10,
      block_split_factor: 3.0,
    }
    dungeon = Meiro.create_dungeon(options)
    floor = dungeon.generate_random_floor

    floor.classify!(:rogue_like)
    @floor = floor.to_s
    replacements = {
      " " => "q",
      "#" => ".",
      "q" => "#",
      "|" => "#",
      "-" => "#",
      "." => " ",
      "+" => " ",
    }
    replacements.each do |char, replacement|
      @floor = @floor.tr(char, replacement)
    end

    #add_corridors()
    @floor = @floor.split("\n")
  end

  def place_stuff
    @map.create_from_grid(-1, -1, @floor, {
      "#" => ["wall", {color: Gosu::Color::rgb(255, 255, 255)}],
      ">" => ["player"],
    })

    (0..7).each do |n|
      randomly_place_object("alien", id: gen_id)
    end

    randomly_place_object("stairs", id: "descend", num: -1)
    if @status == "next"
      randomly_place_object("stairs", id: "ascend", num: 1)
      randomly_place_object("player")
      @map.player[:x] = (@map.get_object_by_id("ascend")[:x])
      @map.player[:y] = (@map.get_object_by_id("ascend")[:y])
      offset_map_by_name("player")

    else
      randomly_place_object("player")
      while !@map.level.grid.key?("#{@map.player[:x]} #{@map.player[:y]}")
        @map.delete_object_by_name("player")
        randomly_place_object("player")
      end
      offset_map_by_name("player")
    end
	  randomly_place_object("npc", symbol: "N", id: gen_id, text: "What a poseur.", type: "dynamic", \
		text_opts: {x_loc: 0.78})

    @map.set_weapon("weapon")
  end

  def update
    object_controls(@map.player)
  end

  def offset_map_by_name(name)
    offset_to = @map.get_object_by_name(name)
    @map.player_offset_x = -(offset_to[:x] - @map.width / (@window.zoom / 0.5))
    @map.player_offset_y = -(offset_to[:y] - @map.height / (@window.zoom / 0.5))
  end

  def randomly_place_object(object, args={})
    x = -1
    y = -1
    possible_locs = []
    @floor.each do |layer|
      y += 1
      x = -1
      layer.split(//).each do |char|
        x += 1
        if char == " "
          possible_locs.push([x, y])
        end
      end
    end
    where = possible_locs[rand(0..possible_locs.size - 1)]
    @map.place_object(where[0], where[1], object, args)
  end
end
